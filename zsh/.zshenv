alias youtubedl="sudo docker run --rm --user $UID:$GID -v $PWD:/downloads jonfk/youtube-dl"

if [ -d "/usr/local/go" ]; then
    export PATH=$PATH:/usr/local/go/bin
fi

if [ -d "$HOME/go/bin" ]; then
    export PATH=$PATH:"$HOME/go/bin"
fi

if [[ `uname` == "Darwin" ]]; then
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi

if [ -d "$HOME/.bin" ]; then
    export PATH=$PATH:"$HOME/.bin"
fi

if [ -d "$HOME/.local/bin" ]; then
    export PATH=$PATH:"$HOME/.local/bin"
fi

if [ -d "/opt/nvim-linux64/bin/" ]; then
    export PATH=$PATH:"/opt/nvim-linux64/bin/"
fi

if [ -d "/Users/jfokkan/Library/Application Support/Coursier/bin" ]; then
    export PATH=$PATH:"/Users/jfokkan/Library/Application Support/Coursier/bin"
fi

# Add icu4c bin to PATH without overwritting base libraries from macOS
if command -v brew >/dev/null 2>&1; then
  icu_prefix="$(brew --prefix icu4c 2>/dev/null)"
  if [[ -n "$icu_prefix" && -d "$icu_prefix/bin" ]]; then
    export PATH="$icu_prefix/bin:$PATH"
  fi
fi

if [[ -f ~/.zshenv_priv ]]; then
  source ~/.zshenv_priv
fi

ytdlp() {
    yt-dlp $1 -o "$2 %(title)s [%(id)s].%(ext)s"
}

tn() {
  echo $PATH
  if [[ -n "$1" ]]; then
    # If an argument is provided, use it as the session name
    tmux new -s "$1"
  else
    # If no argument is provided, use cwd and up to 2 parent directories
    local path=$(pwd)
    local session_name=$(echo "$path" | rev | cut -d'/' -f1-3 | rev | tr '/' ':')
    
    tmux new -s "$session_name"
  fi
}


export EDITOR="vim"
export VISUAL="code"
. "$HOME/.cargo/env"

alias assume=". assume"

export BAT_THEME="TwoDark"

export GIT_WORKTREE_ADMIN_ROOT=~/Developer/worktrees-admin
export GIT_WORKTREE_ROOT=~/Developer/worktrees
