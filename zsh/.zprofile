if [ -f /opt/homebrew/bin/brew ]; then 
	eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
if [ -f "~/.orbstack/shell/init.zsh" ]; then 
	source ~/.orbstack/shell/init.zsh 2>/dev/null || :
fi
