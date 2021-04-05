source ~/.bin/antigen.zsh

antigen bundle git
# antigen bundle command-not-found
# antigen bundle zsh-users/zsh-autosuggestions
# antigen bundle zsh-users/zsh-completions

antigen theme denysdovhan/spaceship-prompt

antigen apply

alias ls='ls --color=auto'
alias open='wslview'

# zsh-autosuggest
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# From https://superuser.com/questions/1092033/how-can-i-make-zsh-tab-completion-fix-capitalization-errors-for-directories-and
# Allows zsh completion to fix case and allow case-insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

bindkey ";5C" forward-word
bindkey ";5D" backward-word

if command -v pazi &>/dev/null; then
	eval "$(pazi init zsh)" # or 'bash'
fi

zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on

precmd() {
	# sets the tab title to current dir
	echo -ne "\e]1;${PWD##*/}\a"
}

mkcdir ()
{
	mkdir -p -- "$1" &&
	cd -P -- "$1"
}
