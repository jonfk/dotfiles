source ~/.bin/antigen.zsh

antigen bundle git
# antigen bundle command-not-found
# antigen bundle zsh-users/zsh-autosuggestions
# antigen bundle zsh-users/zsh-completions

antigen theme denysdovhan/spaceship-prompt

antigen apply

alias ls='ls -G'
alias open='wslview'

# zsh-autosuggest
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# From https://superuser.com/questions/1092033/how-can-i-make-zsh-tab-completion-fix-capitalization-errors-for-directories-and
# Allows zsh completion to fix case and allow case-insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line

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

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
