#!/usr/bin/env bash

set -e -x

rsync -va ~/.emacs ~/dotfiles/.emacs

rsync -va ~/.bashrc ~/dotfiles/.bashrc

rsync -va ~/update.sh ~/dotfiles/update.sh

rsync -va ~/.vim ~/dotfiles/.vim

rsync -va ~/.vimrc ~/dotfiles/.vimrc
