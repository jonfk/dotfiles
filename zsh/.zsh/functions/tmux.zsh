alias tcd='cd "$(tmux display-message -p "#{session_path}")"'
alias tmux-cd-session-to-cwd='if [[ -n "$TMUX" ]]; then tmux attach-session -t . -c "$PWD"; else :; fi'

function tn() {
  # Find the full path to tmux to avoid any PATH issues
  local tmux_cmd=$(which tmux)
  local session_name

  if [[ -n "$1" ]]; then
    # If an argument is provided, use it as the session name
    session_name="$1"
  else
    # Get home directory and current path
    local home_dir=$HOME
    local current_path=$(pwd)

    # Check if we're in home directory or ~/Developer
    if [[ "$current_path" == "$home_dir" || "$current_path" == "$home_dir/Developer" ]]; then
      # Just use the current directory name
      session_name=$(basename "$current_path")
    else
      # Use cwd and parent directory
      local parts=("${(s:/:)current_path}")
      local num_parts=${#parts[@]}
      local start_idx=$((num_parts > 2 ? num_parts - 2 : 0))
      session_name="${(j:|:)parts[start_idx+1,-1]}"

      # Handle empty session name (can happen if at root)
      [[ -z "$session_name" ]] && session_name="root"
    fi
  fi

  if "$tmux_cmd" has-session -t "=$session_name" 2>/dev/null; then
    if [[ -n "$TMUX" ]]; then
      "$tmux_cmd" switch-client -t "=$session_name"
    else
      "$tmux_cmd" attach-session -t "=$session_name"
    fi
  elif [[ -n "$TMUX" ]]; then
    "$tmux_cmd" new-session -d -s "$session_name" -c "$PWD"
    "$tmux_cmd" switch-client -t "=$session_name"
  else
    "$tmux_cmd" new-session -s "$session_name" -c "$PWD"
  fi
}

function tmux_session_switch_interactive() {
  local tmux_cmd=$(which tmux)
  local query="$*"
  local selected_session

  if [[ -n "$TMUX" ]]; then
    local current_session
    local popup_command

    current_session=$("$tmux_cmd" display-message -p '#S')
    popup_command="selected_session=\$($tmux_cmd list-sessions -F '#{session_last_attached} #{session_name}' | sort -rn | sed -E 's/^[0-9]+ //' | grep -v '^${current_session:q}$' | fzf --reverse --query=${query:q} --preview '$tmux_cmd capture-pane -ep -t {}' --preview-window=right:60%); [ -n \"\$selected_session\" ] && $tmux_cmd switch-client -t \"\$selected_session\""
    "$tmux_cmd" display-popup -E "$popup_command"
  else
    selected_session=$("$tmux_cmd" list-sessions -F '#{session_last_attached} #{session_name}' |
      sort -rn |
      sed -E 's/^[0-9]+ //' |
      fzf --reverse --query "$query" --preview "$tmux_cmd capture-pane -ep -t {}" --preview-window=right:60%)

    if [[ -n "$selected_session" ]]; then
      "$tmux_cmd" attach-session -t "$selected_session"
    fi
  fi
}

alias tsi='tmux_session_switch_interactive'
