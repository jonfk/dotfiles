alias gai=git-smart-commit

function codex-commit() {
  local prompt='Use $git-commit'
  local edit_choice

  # Allow optional extra context appended to the base prompt.
  if [ $# -gt 0 ]; then
    prompt="${prompt} $*"
  fi

  codex exec --yolo -c model_reasoning_effort="low" "$prompt" || return $?

  read -r "edit_choice?Edit commit message now? [y/N] "
  if [[ "$edit_choice" =~ ^([yY]|[yY][eE][sS])$ ]]; then
    git commit --amend
  fi
}

alias gaic='codex-commit'
