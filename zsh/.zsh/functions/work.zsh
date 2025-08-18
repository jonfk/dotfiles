
gh-compare-permalink() {
  emulate -L zsh
  setopt NO_BEEP

  # Clipboard and opener (override with env vars if you want)
  local paste_cmd="${GIT_PASTE_CMD:-pbcopy}"
  local open_cmd
  if [[ -n "${GIT_OPEN_CMD:-}" ]]; then
    open_cmd="$GIT_OPEN_CMD"
  else
    case "$(uname -s)" in
      Darwin) open_cmd="open" ;;
      Linux)  open_cmd="xdg-open" ;;
      *)      open_cmd="open" ;;  # best effort
    esac
  fi

  local use_full=0
  if [[ "$1" == "--full-hash" ]]; then
    use_full=1
    shift
  fi

  if (( $# != 2 )); then
    print -u2 -- "Usage: gh-compare-permalink [--full-hash] <base-ref> <head-ref>"
    return 2
  fi

  local base_ref="$1" head_ref="$2"

  # Ensure we're in a git repo
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    print -u2 -- "Error: not inside a git repository."
    return 1
  }

  # Quietly try to fetch the specific refs from origin (ok if offline)
  git fetch --quiet origin "$base_ref" "$head_ref" 2>/dev/null || true

  # Resolve a ref to a commit SHA (prefer origin/<ref>, then local/tag/SHA)
  _resolve_ref() {
    local ref="$1"
    if git rev-parse -q --verify "origin/${ref}^{commit}" >/dev/null 2>&1; then
      git rev-parse "origin/${ref}^{commit}"
    elif git rev-parse -q --verify "${ref}^{commit}" >/dev/null 2>&1; then
      git rev-parse "${ref}^{commit}"
    else
      return 1
    fi
  }

  local base_sha head_sha
  base_sha=$(_resolve_ref "$base_ref") || { print -u2 -- "Error: can't resolve base ref '$base_ref'."; return 1; }
  head_sha=$(_resolve_ref "$head_ref") || { print -u2 -- "Error: can't resolve head ref '$head_ref'."; return 1; }

  # Short (12) by default; full only with --full-hash
  local base_out head_out
  if (( use_full )); then
    base_out="$base_sha"; head_out="$head_sha"
  else
    base_out="${base_sha:0:12}"; head_out="${head_sha:0:12}"
  fi

  # Derive owner/repo from origin URL (must be GitHub)
  local remote_url slug
  remote_url=$(git remote get-url origin 2>/dev/null) || {
    print -u2 -- "Error: cannot get URL for remote 'origin'."
    return 1
  }
  case "$remote_url" in
    git@github.com:*)       slug="${remote_url#git@github.com:}" ;;
    https://github.com/*)   slug="${remote_url#https://github.com/}" ;;
    ssh://git@github.com/*) slug="${remote_url#ssh://git@github.com/}" ;;
    *) print -u2 -- "Error: 'origin' is not a github.com remote."; return 1 ;;
  esac
  slug="${slug%.git}"

  local url="https://github.com/${slug}/compare/${base_out}...${head_out}"

  # Copy to clipboard
  if command -v "$paste_cmd" >/dev/null 2>&1; then
    print -r -- "$url" | "$paste_cmd"
    print -- "Copied permalink to clipboard."
  else
    print -u2 -- "Warning: '$paste_cmd' not found; permalink not copied."
  fi

  # Open in browser
  if command -v "$open_cmd" >/dev/null 2>&1; then
    "$open_cmd" "$url" >/dev/null 2>&1 &
  else
    print -u2 -- "Warning: '$open_cmd' not found; couldn't open the URL."
  fi
}
