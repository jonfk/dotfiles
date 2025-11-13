# Unset conflicting git aliases from ohmyzsh plugin
unalias gco gp grss 2>/dev/null

# Git-related aliases and helpers
_git_log_medium_format='%C(bold)Commit:%C(reset) %C(green)%H%C(red)%d%n%C(bold)Author:%C(reset) %C(cyan)%an <%ae>%n%C(bold)Date:%C(reset)   %C(blue)%ai (%ar)%C(reset)%n%+B'
_git_log_oneline_format='%C(green)%h%C(reset) %s%C(red)%d%C(reset)%n'
_git_log_brief_format='%C(green)%h%C(reset) %s%n%C(blue)(%ar by %an)%C(red)%d%C(reset)%n'

alias gs='git status'
alias gco='git checkout'
alias gci='git checkout $(git branch | fzf)'
alias grss='git restore --staged'
alias gls="git log --topo-order --stat --pretty=format:\"${_git_log_medium_format}\""
alias delta-full='delta --diff-args=-U9999'

# Push wrapper that copies and opens GitHub PR links when offered by remote.
function gp() {
  setopt localoptions pipefail

  local tmpfile
  tmpfile=$(mktemp 2>/dev/null)
  if [[ -z "$tmpfile" ]]; then
    echo "gp: failed to create temp file" >&2
    return 1
  fi

  command git push "$@" | tee "$tmpfile"
  local push_status=${pipestatus[1]:-0}

  local pr_url
  pr_url=$(grep -Eo 'https://github\.com/[^[:space:]]+/pull/new/[^[:space:]]+' "$tmpfile" | head -n1)
  rm -f "$tmpfile"

  if [[ -n "$pr_url" ]]; then
    pr_url=${pr_url//$'\r'/}
    echo "Detected GitHub PR URL: $pr_url"

    if command -v pbcopy >/dev/null 2>&1; then
      printf '%s' "$pr_url" | pbcopy
      echo "Copied PR URL to clipboard."
    elif command -v wl-copy >/dev/null 2>&1; then
      printf '%s' "$pr_url" | wl-copy
      echo "Copied PR URL to clipboard."
    elif command -v xclip >/dev/null 2>&1; then
      printf '%s' "$pr_url" | xclip -selection clipboard
      echo "Copied PR URL to clipboard."
    else
      echo "Warning: no clipboard tool found; URL not copied."
    fi

    if command -v open >/dev/null 2>&1; then
      open "$pr_url" >/dev/null 2>&1
    elif command -v xdg-open >/dev/null 2>&1; then
      xdg-open "$pr_url" >/dev/null 2>&1
    else
      echo "Warning: could not auto-open browser for PR URL."
    fi
  fi

  return $push_status
}

function ghpr() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: ghpr"
    echo ""
    echo "Opens GitHub pull requests associated with recent commits."
    echo ""
    echo "This function:"
    echo "  1. Searches the last 100 commits for messages ending with '(#number)'"
    echo "  2. Shows the 10 most recent matches using fzf"
    echo "  3. Extracts the PR number and opens it in your browser"
    echo ""
    echo "Requirements:"
    echo "  - Must be run inside a git repository"
    echo "  - Repository must have a GitHub remote named 'origin'"
    echo "  - fzf must be installed (https://github.com/junegunn/fzf)"
    echo ""
    echo "Options:"
    echo "  -h, --help    Display this help message"
    return 0
  fi

  # Check if we're in a git repository
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not in a git repository."
    return 1
  fi

  # Extract the remote URL (assuming origin)
  local remote_url=$(git remote get-url origin 2>/dev/null)
  if [[ -z "$remote_url" ]]; then
    echo "Error: No 'origin' remote found."
    return 1
  fi

  # Check if the remote is a GitHub repository
  if [[ ! "$remote_url" =~ github\.com ]]; then
    echo "Error: Remote is not a GitHub repository."
    return 1
  fi

  # Extract owner and repo name from the remote URL using sed
  local owner_repo=""
  
  # Handle SSH URL format: git@github.com:owner/repo.git
  if [[ "$remote_url" == git@github.com:* ]]; then
    owner_repo=$(echo "$remote_url" | sed 's/git@github.com:\(.*\)\.git/\1/')
  # Handle HTTPS URL format: https://github.com/owner/repo.git
  elif [[ "$remote_url" == https://github.com/* ]]; then
    owner_repo=$(echo "$remote_url" | sed 's|https://github.com/\(.*\)\.git|\1|' | sed 's|https://github.com/\(.*\)|\1|')
  else
    echo "Error: Unsupported GitHub URL format: $remote_url"
    return 1
  fi
  
  # Trim any trailing .git if it exists
  owner_repo=${owner_repo%.git}
  
  # Verify that we have a valid owner/repo format
  if [[ ! "$owner_repo" =~ ^[^/]+/[^/]+$ ]]; then
    echo "Error: Could not extract valid owner/repo from remote URL: $remote_url"
    echo "Extracted: $owner_repo"
    return 1
  fi

  # Get the last 10 commits with messages ending in "(#number)"
  local commits=$(git log --pretty=format:"%h %s" -n 100 | grep -E ' \(#[0-9]+\)$' | head -n 20)
  
  # Check if we found any matching commits
  if [[ -z "$commits" ]]; then
    echo "No commits found with messages ending in '(#number)'"
    return 1
  fi
  
  # Use fzf to select a commit
  local selected_commit=$(echo "$commits" | fzf --height 40% --reverse --preview 'git show --color=always {1}' --preview-window=right:60%)
  
  # Check if a commit was selected
  if [[ -z "$selected_commit" ]]; then
    echo "No commit selected"
    return 0
  fi
  
  # Extract the PR number from the commit message
  local pr_number=$(echo "$selected_commit" | grep -oE '\(#[0-9]+\)$' | grep -oE '[0-9]+')
  
  # Check if we got a PR number
  if [[ -z "$pr_number" ]]; then
    echo "Could not extract PR number from commit message"
    return 1
  fi
  
  # Construct the URL using the extracted owner and repo
  local url="https://github.com/$owner_repo/pull/$pr_number"
  echo "Opening: $url"
  
  # Try to detect platform and open browser accordingly
  if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$url"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open "$url" &>/dev/null
  else
    echo "URL: $url"
    echo "Could not automatically open the URL. Please copy and paste it into your browser."
  fi
}
