#!/usr/bin/env bash
stow emacs -t $HOME
stow bash -t $HOME
stow vim -t $HOME
stow shell -t $HOME
touch $HOME/.env_priv
