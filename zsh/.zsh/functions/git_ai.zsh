
function git-smart-commit() {
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
  
  local cmd=""
  
  # First check if there are staged changes
  if ! git diff --staged --quiet --exit-code; then
    # There are staged changes
    echo "Generating commit message for staged changes..."
    cmd=$(git diff --staged | llm --extract-last "$prompt_staged")
  else
    # No staged changes, check if there are unstaged changes
    if ! git diff --quiet --exit-code; then
      # There are unstaged changes
      echo "Generating commands to stage and commit changes..."
      cmd=$(git diff | llm --extract-last "$prompt_unstaged")
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

alias gai=git-smart-commit

