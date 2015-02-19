#!/usr/bin/env bash

set -e -x

rsync -va ~/dotfiles/.emacs ~/.emacs

rsync -va ~/dotfiles/.bashrc ~/.bashrc

rsync -va ~/dotfiles/update.sh ~/update.sh

rsync -va ~/dotfiles/push.sh ~/push.sh

rsync -va ~/dotfiles/.vim ~/.vim

rsync -va ~/dotfiles/.vimrc ~/.vimrc
