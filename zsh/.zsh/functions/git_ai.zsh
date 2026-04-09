alias gai=git-smart-commit

function _codex_commit_cleanup() {
  local tmpdir=$1

  if [[ -n "$tmpdir" && -d "$tmpdir" ]]; then
    rm -rf "$tmpdir"
  fi
}

function _codex_commit_print_log_tail() {
  local log_file=$1

  if [[ -f "$log_file" ]]; then
    printf 'codex-commit: Codex output (tail)\n' >&2
    tail -n 40 "$log_file" >&2
  fi
}

function _codex_commit_schema_path() {
  local function_file dotfiles_root

  function_file=${functions_source[codex-commit]}
  dotfiles_root=${function_file:A:h:h:h:h}

  printf '%s\n' "$dotfiles_root/openai-codex/.codex/skills/git-commit-proposal/commit-proposal.schema.json"
}

function _codex_commit_skill_path() {
  local function_file dotfiles_root

  function_file=${functions_source[codex-commit]}
  dotfiles_root=${function_file:A:h:h:h:h}

  printf '%s\n' "$dotfiles_root/openai-codex/.codex/skills/git-commit-proposal/SKILL.md"
}

function _codex_commit_message_file() {
  local output_file=$1
  local message_file=$2
  local subject
  local -a body_paragraphs

  subject=$(jq -er '.commit.subject' "$output_file") || return 1
  body_paragraphs=("${(@f)$(jq -r '.commit.body_paragraphs[]? // empty' "$output_file")}") || return 1
  body_paragraphs=("${(@)body_paragraphs:#}")

  {
    printf '%s\n' "$subject"

    if (( ${#body_paragraphs[@]} > 0 )); then
      printf '\n'
      printf '%s\n\n' "${body_paragraphs[@]}"
    fi
  } > "$message_file"
}

function _codex_commit_print_proposal() {
  local output_file=$1
  local message_file=$2
  local summary
  local -a stage_paths

  summary=$(jq -r '.summary // ""' "$output_file")
  stage_paths=("${(@f)$(jq -r '.stage_paths[]? // empty' "$output_file")}")
  stage_paths=("${(@)stage_paths:#}")

  if [[ -n "$summary" ]]; then
    printf '%s\n\n' "$summary"
  fi

  printf 'Proposed files:\n'
  if (( ${#stage_paths[@]} == 0 )); then
    printf '  (none)\n'
  else
    printf '  %s\n' "${stage_paths[@]}"
  fi

  printf '\nProposed commit message:\n'
  printf -- '---\n'
  cat "$message_file"
  printf -- '---\n'
}

function _codex_commit_print_alternatives() {
  local output_file=$1
  local count i summary subject
  local -a paths

  count=$(jq -r '.alternatives | length // 0' "$output_file")

  if [[ "$count" == "0" ]]; then
    return 0
  fi

  printf '\nSuggested split commits:\n'
  for i in $(seq 0 $(( count - 1 ))); do
    summary=$(jq -r ".alternatives[$i].summary // \"\"" "$output_file")
    subject=$(jq -r ".alternatives[$i].commit_subject // \"\"" "$output_file")
    paths=("${(@f)$(jq -r ".alternatives[$i].stage_paths[]? // empty" "$output_file")}")
    paths=("${(@)paths:#}")

    printf '\n%d. %s\n' $(( i + 1 )) "${summary:-Alternative $(( i + 1 ))}"
    if [[ -n "$subject" ]]; then
      printf '   Commit: %s\n' "$subject"
    fi
    if (( ${#paths[@]} > 0 )); then
      printf '   Files:\n'
      printf '     %s\n' "${paths[@]}"
    fi
  done
}

function _codex_commit_editor() {
  local repo_root=$1
  local editor

  editor=$(git -C "$repo_root" var GIT_EDITOR 2>/dev/null)
  if [[ -n "$editor" ]]; then
    printf '%s\n' "$editor"
    return 0
  fi

  printf '%s\n' "${VISUAL:-${EDITOR:-vi}}"
}

function codex-commit() {
  emulate -L zsh
  setopt localtraps

  local prompt skill_path skill_text
  local repo_root schema_path tmpdir output_file message_file log_file proposal_status action editor
  local -a stage_paths current_staged
  local current_sorted proposed_sorted

  skill_path=$(_codex_commit_skill_path)
  if [[ ! -f "$skill_path" ]]; then
    echo "codex-commit: skill file not found at $skill_path" >&2
    return 1
  fi

  skill_text=$(<"$skill_path")
  prompt=$'Follow these instructions exactly and return only a schema-compliant JSON response.\n\n'
  prompt+="$skill_text"

  # Allow optional extra context appended to the base prompt.
  if [ $# -gt 0 ]; then
    prompt="${prompt}"$'\n\nAdditional user context:\n'"$*"
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "codex-commit: jq is required" >&2
    return 1
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "codex-commit: not inside a git repository" >&2
    return 1
  fi

  repo_root=$(git rev-parse --show-toplevel) || return 1
  schema_path=$(_codex_commit_schema_path)
  if [[ ! -f "$schema_path" ]]; then
    echo "codex-commit: schema file not found at $schema_path" >&2
    return 1
  fi

  tmpdir=$(mktemp -d) || return 1
  output_file="$tmpdir/proposal.json"
  message_file="$tmpdir/COMMIT_EDITMSG"
  log_file="$tmpdir/codex.log"
  trap '_codex_commit_cleanup "$tmpdir"; return 130' INT TERM

  codex exec \
    --ephemeral \
    --sandbox read-only \
    -c model_reasoning_effort="low" \
    --output-schema "$schema_path" \
    -o "$output_file" \
    "$prompt" \
    </dev/null \
    >"$log_file" 2>&1
  if [[ $? -ne 0 ]]; then
    _codex_commit_print_log_tail "$log_file"
    _codex_commit_cleanup "$tmpdir"
    return 1
  fi

  proposal_status=$(jq -er '.status' "$output_file" 2>/dev/null)
  if [[ $? -ne 0 ]]; then
    echo "codex-commit: invalid proposal output" >&2
    _codex_commit_print_log_tail "$log_file"
    _codex_commit_cleanup "$tmpdir"
    return 1
  fi

  case "$proposal_status" in
    ready)
      stage_paths=("${(@f)$(jq -r '.stage_paths[]? // empty' "$output_file")}")
      stage_paths=("${(@)stage_paths:#}")
      if (( ${#stage_paths[@]} == 0 )); then
        echo "codex-commit: ready proposal missing stage_paths" >&2
        _codex_commit_cleanup "$tmpdir"
        return 1
      fi

      if ! jq -e '.commit.subject | type == "string" and length > 0' "$output_file" >/dev/null 2>&1; then
        echo "codex-commit: ready proposal missing commit subject" >&2
        _codex_commit_cleanup "$tmpdir"
        return 1
      fi

      if ! _codex_commit_message_file "$output_file" "$message_file"; then
        echo "codex-commit: failed to build commit message" >&2
        _codex_commit_cleanup "$tmpdir"
        return 1
      fi
      ;;
    split_required|nothing_to_commit)
      jq -r '.summary // "No commit created."' "$output_file"
      if [[ "$proposal_status" == "split_required" ]]; then
        _codex_commit_print_alternatives "$output_file"
      fi
      _codex_commit_cleanup "$tmpdir"
      return 0
      ;;
    *)
      echo "codex-commit: unsupported proposal status '$proposal_status'" >&2
      _codex_commit_cleanup "$tmpdir"
      return 1
      ;;
  esac

  current_staged=("${(@f)$(git -C "$repo_root" diff --cached --name-only)}")
  current_staged=("${(@)current_staged:#}")
  if (( ${#current_staged[@]} > 0 )); then
    current_sorted=$(printf '%s\n' "${current_staged[@]}" | LC_ALL=C sort)
    proposed_sorted=$(printf '%s\n' "${stage_paths[@]}" | LC_ALL=C sort)
    if [[ "$current_sorted" != "$proposed_sorted" ]]; then
      echo "codex-commit: proposal does not match the current staged set; refusing to add files" >&2
      printf 'Currently staged files:\n'
      printf '  %s\n' "${current_staged[@]}"
      printf '\nProposed files:\n'
      printf '  %s\n' "${stage_paths[@]}"
      _codex_commit_cleanup "$tmpdir"
      return 1
    fi
  fi

  while true; do
    _codex_commit_print_proposal "$output_file" "$message_file"
    read -r "action?Commit with this message? [Y/n] "
    case "$action:l" in
      ""|y|yes)
        if (( ${#current_staged[@]} == 0 )); then
          git -C "$repo_root" add -- "${stage_paths[@]}" || {
            _codex_commit_cleanup "$tmpdir"
            return 1
          }
        fi
        git -C "$repo_root" commit -F "$message_file"
        local commit_status=$?
        _codex_commit_cleanup "$tmpdir"
        return $commit_status
        ;;
      n|no)
        editor=$(_codex_commit_editor "$repo_root")
        eval "$editor \"\$message_file\"" || {
          _codex_commit_cleanup "$tmpdir"
          return 1
        }
        ;;
      *)
        echo "Press Enter or y to commit, n to edit, or Ctrl+C to cancel."
        ;;
    esac
  done
}

alias gaic='codex-commit'
