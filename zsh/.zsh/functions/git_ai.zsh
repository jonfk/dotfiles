function git-smart-commit() {
  local model="gemini-2.5-flash"
  local additional_prompt=""
  local additional_flags=""
  local help=0
  
  # Function to display help
  function _show_help() {
    echo "Usage: git-smart-commit [-m MODEL] [-h|--help] [additional prompt -- llm flags]"
    echo ""
    echo "Options:"
    echo "  -m MODEL      Specify LLM model to use (default: $model)"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "Additional arguments:"
    echo "  Text before -- is used as additional prompt context"
    echo "  Arguments after -- are passed directly to the llm command"
    echo ""
    echo "Context files:"
    echo "  .git-commit-ai-prompt.txt - Additional project-specific commit instructions"
    echo ""
    echo "Example:"
    echo "  git-smart-commit -m claude-3-5-sonnet-20240307"
    echo "  git-smart-commit focus on the security fixes -- --temperature 0.7"
  }
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        _show_help
        return 0
        ;;
      -m)
        if [[ -z "$2" || "$2" == -* ]]; then
          echo "Error: -m requires a model name"
          return 1
        fi
        model="$2"
        shift 2
        ;;
      --)
        shift
        additional_flags="$*"
        break
        ;;
      *)
        if [[ -z "$additional_prompt" ]]; then
          additional_prompt="$1"
        else
          additional_prompt="$additional_prompt $1"
        fi
        shift
        ;;
    esac
  done

  # Check if llm command exists
  if ! command -v llm &>/dev/null; then
    echo "Error: llm command not found. Please install it first."
    return 1
  fi
  
  # Check if jq command exists
  if ! command -v jq &>/dev/null; then
    echo "Error: jq command not found. Please install it first."
    return 1
  fi
  
  # Check if in a git repository
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not in a git repository"
    return 1
  fi
  
  # Gather context information
  local context_info=""
  
  # Get recent commit history for context
  local recent_commits
  if recent_commits=$(git log --oneline -5 2>/dev/null); then
    context_info="Recent commits in this project:\n$recent_commits\n\n"
  fi
  
  # Read project-specific prompt file if it exists
  local project_prompt=""
  if [[ -f ".git-commit-ai-prompt.txt" ]]; then
    project_prompt=$(cat ".git-commit-ai-prompt.txt" 2>/dev/null)
    if [[ -n "$project_prompt" ]]; then
      context_info="${context_info}Project-specific commit guidelines:\n$project_prompt\n\n"
    fi
  fi
  
  # Base prompt with AI assistant context
  local base_prompt="You are an AI engineering assistant helping with git commit creation. 

${context_info}Create a conventional commit message that describes the PRIMARY purpose of these changes.

Use conventional commit format with types like: feat, fix, docs, style, refactor, test, chore, perf, ci, build

Guidelines:
- Keep the main message concise and under 50 characters when possible  
- Use imperative mood (\"add\" not \"added\" or \"adds\")
- Include scope in parentheses when appropriate: type(scope): description
- Only use body lines for complex changes that need detailed explanation
- Focus on WHAT changed and WHY, not HOW"
  
  # Define full JSON schemas for structured output
  local staged_schema='{
    "type": "object",
    "properties": {
      "message": {
        "type": "string",
        "description": "Concise conventional commit message under 50 characters when possible",
        "minLength": 1,
        "maxLength": 100
      },
      "body": {
        "type": "array",
        "items": {
          "type": "string",
          "minLength": 1
        },
        "description": "Array of detailed explanation lines. Each item in the array is a line in the commit body. Only include if changes need detailed explanation"
      }
    },
    "required": ["message"],
    "additionalProperties": false
  }'
  
  local unstaged_schema='{
    "type": "object", 
    "properties": {
      "files": {
        "type": "array",
        "items": {
          "type": "string",
          "minLength": 1
        },
        "minItems": 1,
        "description": "Array of file paths to stage together - only include related files that serve a common purpose"
      },
      "message": {
        "type": "string",
        "description": "Concise conventional commit message under 50 characters when possible",
        "minLength": 1,
        "maxLength": 100
      },
      "body": {
        "type": "array",
        "items": {
          "type": "string",
          "minLength": 1 
        },
        "description": "Array of detailed explanation lines. Each item in the array is a line in the commit body. Only include if changes need detailed explanation"
      }
    },
    "required": ["files", "message"],
    "additionalProperties": false
  }'
  
  # Add additional prompt context if provided
  if [[ -n "$additional_prompt" ]]; then
    base_prompt="$base_prompt\n\nAdditional context: $additional_prompt"
  fi
  
  local json_response=""
  local temp_commit_file=""
  
  # First check if there are staged changes
  if ! git diff --staged --quiet --exit-code; then
    # There are staged changes
    echo "Generating commit message for staged changes..."
    echo "Using model: $model"
    
    local full_prompt="$base_prompt\n\nAnalyze the following staged diff:"
    json_response=$(git diff --staged | llm -m "$model" $additional_flags --schema "$staged_schema" <<< "$full_prompt")
    
  elif ! git diff --quiet --exit-code; then
    # There are unstaged changes
    echo "Generating commands to stage and commit changes..."
    echo "Using model: $model"
    
    local full_prompt="$base_prompt\n\nAnalyze the following diff and identify ONLY RELATED changes that should be committed together. DO NOT add all files - select only files with related changes that serve a common purpose.\n\nDiff:"
    json_response=$(git diff | llm -m "$model" $additional_flags --schema "$unstaged_schema" <<< "$full_prompt")
    
  else
    # No changes at all
    echo "No changes detected in the repository"
    return 0
  fi
  
  if [[ -z "$json_response" ]]; then
    echo "Error: Failed to generate commit information"
    return 1
  fi
  
  echo "Generated response:"
  echo "$json_response" | jq .
  
  # Extract information using jq with proper error handling
  local commit_message files_to_stage body_lines
  
  commit_message=$(echo "$json_response" | jq -r '.message // empty' 2>/dev/null)
  if [[ -z "$commit_message" ]]; then
    echo "Error: Could not extract commit message from response"
    return 1
  fi
  
  # Extract body lines (if any)
  body_lines=$(echo "$json_response" | jq -r '.body[]? // empty' 2>/dev/null)
  
  # For unstaged changes, extract files to stage
  if git diff --staged --quiet --exit-code; then
    files_to_stage=$(echo "$json_response" | jq -r '.files[]? // empty' 2>/dev/null)
    
    if [[ -n "$files_to_stage" ]]; then
      echo "Staging files:"
      echo "$files_to_stage"
      
      # Stage the files with proper shell escaping
      local files_array=()
      while IFS= read -r file; do
        if [[ -n "$file" ]]; then
          # Verify file exists and has changes
          if git diff --name-only | grep -Fxq "$file"; then
            files_array+=("$file")
          else
            echo "Warning: File '$file' not found in changes or already staged"
          fi
        fi
      done <<< "$files_to_stage"
      
      if [[ ${#files_array[@]} -eq 0 ]]; then
        echo "Error: No valid files to stage"
        return 1
      fi
      
      # Stage files using git add with proper quoting
      if ! git add "${files_array[@]}"; then
        echo "Error: Failed to stage files"
        return 1
      fi
    else
      echo "Error: No files specified for staging"
      return 1
    fi
  fi
  
  # Create commit
  if [[ -n "$body_lines" ]]; then
    # Multi-line commit using temp file
    temp_commit_file=$(mktemp)
    
    # Write commit message to temp file
    printf '%s\n' "$commit_message" > "$temp_commit_file"
    printf '\n' >> "$temp_commit_file"
    
    # Add body lines
    while IFS= read -r line; do
      if [[ -n "$line" ]]; then
        printf '%s\n' "$line" >> "$temp_commit_file"
      fi
    done <<< "$body_lines"
    
    echo "Commit message preview:"
    echo "----------------------"
    cat "$temp_commit_file"
    echo "----------------------"
    
    # Prepare the commit command
    local cmd="git commit -F $(printf %q "$temp_commit_file")"

    # Invoke the git commit editor with the tempfile
    git commit --edit --template="$temp_commit_file" \
      || \
    # if it aborts because you didn't change anything, just commit with -F
    print -z "git commit -F \"$(printf %q "$temp_commit_file")\""
  else
    # Simple single-line commit
    echo "Commit message: $commit_message"
    local cmd="git commit -m \"$(printf %q "$commit_message")\""

    echo "Generated command:"
    echo "$cmd"
  
    # Put command in zsh buffer for user to execute
    print -z "$cmd"
  fi
}

alias gai=git-smart-commit
