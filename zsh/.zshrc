# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

fpath=(~/.zsh/completions $fpath)

ZVM_INIT_MODE=sourcing

# Clone antidote if necessary.
if [[ ! -e "$HOME/.bin/antidote" ]]; then
  mkdir -p "$HOME/.bin/antidote" && git clone https://github.com/mattmc3/antidote.git "$HOME/.bin/antidote"
fi

source ~/.bin/antidote/antidote.zsh
antidote load

alias grss='git restore --staged'
alias ls='eza'
if [[ ! -a /usr/bin/open ]]; then
	alias open='wslview'
fi
alias llmg='llm -m gemini-2.5-pro-preview-03-25'

export PATH=/usr/local/bin:$PATH
export PATH=~/.local/bin:$PATH

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
	# Cannot be cached because each fnm can have a different node version used
        eval "$(fnm env --use-on-cd)"
fi

if [ -f ~/.zsh/functions/neovim.zsh ]; then 
	source ~/.zsh/functions/neovim.zsh
fi

if [ -f ~/.zsh/functions/cmd_ai.zsh ]; then 
	source ~/.zsh/functions/cmd_ai.zsh
fi

if [ -f ~/.zsh/functions/tmux.zsh ]; then 
	source ~/.zsh/functions/tmux.zsh
fi

if [ -f ~/.zsh/functions/date.zsh ]; then 
	source ~/.zsh/functions/date.zsh
fi

if [ -f ~/.zsh/functions/yt-transcript.zsh ]; then 
	source ~/.zsh/functions/yt-transcript.zsh
fi

if [ -f ~/.zsh/functions/rg.zsh ]; then 
	source ~/.zsh/functions/rg.zsh
fi

if [ -f ~/.zsh/functions/work.zsh ]; then 
	source ~/.zsh/functions/work.zsh
fi

if [ -f ~/.zsh/functions/git-worktree.zsh ]; then 
	source ~/.zsh/functions/git-worktree.zsh
fi

# zstyle ':completion:*' accept-exact '*(N)'
# zstyle ':completion:*' use-cache on

# Commented out to allow tmux to control terminal title
# precmd() {
# 	# sets the tab title to current dir
# 	echo -ne "\e]1;${PWD##*/}\a"
# }

mkcdir ()
{
	mkdir -p -- "$1" &&
	cd -P -- "$1"
}

[[ -s "$HOME/.zsh/functions/git_ai.zsh" ]] && source "$HOME/.zsh/functions/git_ai.zsh"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

autoload -Uz compinit && compinit

# Source git functions last to ensure custom aliases override plugin aliases
if [ -f ~/.zsh/functions/git.zsh ]; then
	source ~/.zsh/functions/git.zsh
fi

if [ -f ~/.fzf.zsh ]; then 
	source ~/.fzf.zsh
else
	source <(fzf --zsh)
fi

_evalcache zoxide init zsh

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/jfokkan/.lmstudio/bin"
# End of LM Studio CLI section
