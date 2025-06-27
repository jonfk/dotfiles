
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
  
  # Check if in a git repository
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not in a git repository"
    return 1
  fi
  
  local prompt_staged='
  Use the provided diff and changes to create git commands.

  CRITICAL: Return ONLY the git commit command with NO explanation, NO markdown, NO preamble, NO backticks, NO fenced code blocks, and NO postscript.
  IMPORTANT: Your entire response will be executed on the command line.
  
  Your response must be a valid git commit command.
  
  Analyze the staged diff for RELATED changes. Create a conventional commit message that describes the PRIMARY purpose of these changes.
  
  For simple commit messages use: git commit -m "type(scope): description"
  
  For multiline commit messages, use embedded newlines with ANSI-C quoting like this:
  git commit -m $'"'"'type(scope): short description\n\n- Detail point 1\n- Detail point 2'"'"'
  
  Use multiline format ONLY when the changes require detailed explanation.
  
  Common types: feat, fix, docs, style, refactor, test, chore, perf
  '
  
  local prompt_unstaged='
  Use the provided diff and changes to create git commands.

  CRITICAL: Return ONLY git commands with NO explanation, NO markdown, NO preamble, NO backticks, NO fenced code blocks, and NO postscript.
  IMPORTANT: Your entire response will be executed on the command line.
  
  Your response must start and end with git commands.
  
  Analyze the diff and identify ONLY RELATED changes that should be committed together.
  DO NOT add all changed files - only select files that contain related changes with a common purpose.
  
  The response should be git commands to:
  1. Stage only the related files (not all files)
  2. Create a conventional commit with an appropriate message
  
  For simple commits use: git add path/to/file1.js && git commit -m "type(scope): description"
  
  For multiline commit messages, use embedded newlines with ANSI-C quoting like this:
  git add path/to/file1.js path/to/file2.js && git commit -m $'"'"'type(scope): short description\n\n- Detail point 1\n- Detail point 2'"'"'
  
  Use multiline format ONLY when the changes require detailed explanation.
  '
  
  # Add additional prompt context if provided
  if [[ -n "$additional_prompt" ]]; then
    prompt_staged="$prompt_staged\n\nAdditional context: $additional_prompt"
    prompt_unstaged="$prompt_unstaged\n\nAdditional context: $additional_prompt"
  fi
  
  local cmd=""
  
  # First check if there are staged changes
  if ! git diff --staged --quiet --exit-code; then
    # There are staged changes
    echo "Generating commit message for staged changes..."
    echo "Using model: $model"
    cmd=$(git diff --staged | llm -m "$model" $additional_flags --extract-last <<< "$prompt_staged")
  else
    # No staged changes, check if there are unstaged changes
    if ! git diff --quiet --exit-code; then
      # There are unstaged changes
      echo "Generating commands to stage and commit changes..."
      echo "Using model: $model"
      cmd=$(git diff | llm -m "$model" $additional_flags --extract-last <<< "$prompt_unstaged")
    else
      # No changes at all
      echo "No changes detected in the repository"
      return 0
    fi
  fi
  
  if [ -z "$cmd" ]; then
    echo "Error: Failed to generate git commands"
    return 1
  fi
  
  echo "Generated command:"
  echo "$cmd"
  
  # No need to check for heredocs anymore since we're using embedded newlines
  # Simply use print -z to put the command in the buffer
  print -z "$cmd"
}

alias gai=git-smart-commit
