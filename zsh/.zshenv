if command cargo &> /dev/null; then
    source "$HOME/.cargo/env"
fi

alias gs="git status"
alias gco="git checkout"
_git_log_medium_format='%C(bold)Commit:%C(reset) %C(green)%H%C(red)%d%n%C(bold)Author:%C(reset) %C(cyan)%an <%ae>%n%C(bold)Date:%C(reset)   %C(blue)%ai (%ar)%C(reset)%n%+B'
_git_log_oneline_format='%C(green)%h%C(reset) %s%C(red)%d%C(reset)%n'
_git_log_brief_format='%C(green)%h%C(reset) %s%n%C(blue)(%ar by %an)%C(red)%d%C(reset)%n'
alias gls="git log --topo-order --stat --pretty=format:\"${_git_log_medium_format}\""
alias youtubedl="sudo docker run --rm --user $UID:$GID -v $PWD:/downloads jonfk/youtube-dl"

if command go &> /dev/null; then
    export PATH=$PATH:/usr/local/go/bin:~/go/bin
fi

if [[ `uname` == "Darwin" ]]; then
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi


export EDITOR="vim"
export VISUAL="code"
