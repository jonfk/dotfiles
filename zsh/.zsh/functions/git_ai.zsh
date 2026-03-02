alias gai=git-smart-commit

function codex-commit() {
  local prompt='Use $git-commit'

  # Allow optional extra context appended to the base prompt.
  if [ $# -gt 0 ]; then
    prompt="${prompt} $*"
  fi

  codex exec --yolo -c model_reasoning_effort="low" "$prompt"
}

alias gaic='codex-commit'
