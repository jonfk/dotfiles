#!/usr/bin/env bash
stow vim -t $HOME
stow zsh -t $HOME
stow git -t $HOME
stow nvim -t $HOME
stow karabiner -t $HOME/.config

touch $HOME/.env_priv

