# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Clone antidote if necessary.
if [[ ! -e "$HOME/.bin/antidote" ]]; then
  mkdir -p "$HOME/.bin/antidote" && git clone https://github.com/mattmc3/antidote.git "$HOME/.bin/antidote"
fi

source ~/.bin/antidote/antidote.zsh
antidote load

alias ls='ls -G'
if [[ ! -a /usr/bin/open ]]; then
	alias open='wslview'
fi

export PATH=/usr/local/bin:$PATH

# zsh-autosuggest
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# From https://superuser.com/questions/1092033/how-can-i-make-zsh-tab-completion-fix-capitalization-errors-for-directories-and
# Allows zsh completion to fix case and allow case-insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line

[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# https://github.com/Schniz/fnm
if command -v fnm &> /dev/null; then
	eval "$(fnm env --use-on-cd)"
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

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

autoload -Uz compinit && compinit

source <(fzf --zsh)

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
