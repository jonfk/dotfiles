function git-worktree-utils-cd() {
  if ! command -v git-worktree-utils >/dev/null 2>&1; then
    echo "git-worktree-utils-cd: git-worktree-utils not found in PATH" >&2
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "git-worktree-utils-cd: jq is required" >&2
    return 1
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    echo "git-worktree-utils-cd: fzf is required" >&2
    return 1
  fi

  local worktrees_json
  if ! worktrees_json=$(git-worktree-utils ls --json 2>/dev/null); then
    echo "git-worktree-utils-cd: failed to list worktrees" >&2
    return 1
  fi

  if [[ -z ${worktrees_json} || ${worktrees_json} == "[]" ]]; then
    echo "git-worktree-utils-cd: no worktrees found" >&2
    return 1
  fi

  local selection
  selection=$(echo "${worktrees_json}" \
    | jq -r '.[] | "\(.name)\t\(.branch)\t\(.path)"' \
    | fzf --height=40% --reverse --ansi --with-nth=1,2 --prompt='worktree> ')

  if [[ -z ${selection} ]]; then
    echo "git-worktree-utils-cd: selection cancelled" >&2
    return 1
  fi

  local name branch worktree_path
  IFS=$'\t' read -r name branch worktree_path <<<"${selection}"

  if [[ -z ${worktree_path} ]]; then
    echo "git-worktree-utils-cd: unable to parse selection" >&2
    return 1
  fi

  if [[ ! -d ${worktree_path} ]]; then
    echo "git-worktree-utils-cd: path not found -> ${worktree_path}" >&2
    return 1
  fi

  cd "${worktree_path}" || return 1
  echo "Switched to ${name} (${branch})"
}
