function cmd-ai() {
  # Default values
  local model="gemini-2.5-flash-preview-04-17"
  local has_piped_input=0
  
  # Check if input is being piped
  if [ ! -t 0 ]; then
    has_piped_input=1
  fi
  
  # Parse options
  while getopts ":em:" opt; do
    case ${opt} in
      m ) model=$OPTARG ;;
      \? ) echo "Usage: cmd [-e] [-m model] <description of command>"
           echo "  -m: Specify the LLM model to use"
           echo "Example: cmd find all png files larger than 1MB"
           return 1 ;;
    esac
  done
  shift $((OPTIND -1))
  
  # Check if llm command exists
  if ! command -v llm &>/dev/null; then
    echo "Error: llm command not found. Please install it first."
    echo "Install with: pip install llm"
    return 1
  fi
  
  # Check if a prompt was provided
  if [ $# -eq 0 ]; then
    echo "Usage: cmd [-e] [-m model] <description of command>"
    echo "  -m: Specify the LLM model to use" 
    echo "Example: cmd find all png files larger than 1MB"
    return 1
  fi
  
  # Create the system prompt for llm
  local system_prompt='
  Return only the command to be executed as a raw string, no string delimiters wrapping it, no yapping, no markdown, no fenced code blocks, what you return will be passed to subprocess.check_output() directly.

  For example, if the user asks: undo last git commit
  You return only: git reset --soft HEAD~1

  If the user asks: find large log files
  You return only: find . -name "*.log" -size +10M

  If the user asks: check disk space
  You return only: df -h

  Your ENTIRE response must be ONLY the command to execute.
  
  Do not include:
  - No explanations or descriptions
  - No backticks (`) or triple backticks (```)
  - No "Command:" prefix
  - No additional text or comments
  
  Environment info:
  - Shell: zsh
  - Current directory: $(pwd)
  - OS: $(uname -s)
  '
  
  # Get user's request
  local user_request="$*"
  
  echo "Generating command for: $user_request"
  
  # Prepare llm command arguments as an array
  local llm_args=()
  if [[ -n "$model" ]]; then
    llm_args+=("--model" "$model")
  fi
  llm_args+=("--system" "$system_prompt" "--extract-last")
  
  # Call llm with the system prompt and user request
  local cmd
  if [ $has_piped_input -eq 1 ]; then
    # Use piped input directly
    cmd=$(cat | llm "${llm_args[@]}" "$user_request")
  else
    # No piped input
    cmd=$(llm "${llm_args[@]}" "$user_request")
  fi
  
  if [ -z "$cmd" ]; then
    echo "Error: Failed to generate command"
    return 1
  fi
  
  # Check for potentially dangerous commands
  if echo "$cmd" | grep -E 'rm -[rf]|rm -.*f|rm -.*r|mv|dd|mkfs|reboot|shutdown|halt|poweroff|format|> /dev/|> /etc/' > /dev/null; then
    echo "⚠️ WARNING: This command may be destructive. Review carefully before executing."
  fi
  
  print -z "$cmd"
}
