
# Main interactive ripgrep function
rgf() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: rgf <pattern> [rg-options...]"
        echo "Examples:"
        echo "  rgf 'function.*test'"
        echo "  rgf 'TODO' --type=python"
        echo "  rgf 'const.*=' --type=js --ignore-case"
        return 1
    fi
    
    rg --color=always --line-number --no-heading --smart-case "$@" |
    fzf --ansi \
        --delimiter ':' \
        --preview 'bat --color=always --style=numbers --highlight-line {2} {1}' \
        --preview-window 'right:60%:+{2}+3/2:~3' \
        --header 'Enter: edit | Ctrl-Y: copy line | Ctrl-O: open file' \
        --bind 'enter:execute(nvim +{2} {1})' \
        --bind 'ctrl-y:execute-silent(echo {3..} | pbcopy)+abort' \
        --bind 'ctrl-o:execute(nvim {1})'
}

# Live grep - search as you type
rgl() {
    local initial_query="$1"
    local rg_prefix="rg --column --line-number --no-heading --color=always --smart-case"
    
    fzf --ansi \
        --disabled \
        --query "$initial_query" \
        --bind "change:reload:$rg_prefix {q} || true" \
        --bind "enter:execute(nvim +{2} {1})" \
        --delimiter ':' \
        --preview 'bat --color=always --style=numbers --highlight-line {2} {1}' \
        --preview-window 'right:60%:+{2}+3/2:~3' \
        --header 'Type to search | Enter: edit file'
}
