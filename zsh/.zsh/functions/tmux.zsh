alias tcd='cd "$(tmux display-message -p "#{session_path}")"'
alias tmux-cd-session-to-cwd='if [[ -n "$TMUX" ]]; then tmux attach-session -t . -c "$PWD"; else :; fi'

function tn() {
  # Find the full path to tmux to avoid any PATH issues
  local tmux_cmd=$(which tmux)
  
  if [[ -n "$1" ]]; then
    # If an argument is provided, use it as the session name
    "$tmux_cmd" new -s "$1"
  else
    # Get home directory and current path
    local home_dir=$HOME
    local current_path=$(pwd)
    
    # Check if we're in home directory or ~/Developer
    if [[ "$current_path" == "$home_dir" || "$current_path" == "$home_dir/Developer" ]]; then
      # Just use the current directory name
      local dir_name=$(basename "$current_path")
      "$tmux_cmd" new -s "$dir_name"
    else
      # Use cwd and parent directory
      local parts=("${(s:/:)current_path}")
      local num_parts=${#parts[@]}
      local start_idx=$((num_parts > 2 ? num_parts - 2 : 0))
      local session_name="${(j:|:)parts[start_idx+1,-1]}"
      
      # Handle empty session name (can happen if at root)
      [[ -z "$session_name" ]] && session_name="root"
      
      "$tmux_cmd" new -s "$session_name"
    fi
  fi
}
