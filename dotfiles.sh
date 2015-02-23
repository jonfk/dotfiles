#!/usr/bin/env bash

set -e
set -x

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
verbose=0

show_help () {
    cat << EOF
usage: dotfiles [-h][-u][-p][-d]

syncs dotfiles between ~/dotfiles and ~/

OPTIONS:
 -h print usage

 -u updates dotfiles in ~/

 -p pushes changes to dotfiles in ~/ to ~/dotfiles

 -d view the difference between dotfiles in ~/ and ~/dotfiles

EOF
}

EMACSDOT=~/dotfiles/emacs/.emacs
BASHDOT=~/dotfiles/bash/.bashrc
VIMDOT=~/dotfiles/vim
AWESOMEDOT=~/dotfiles/awesome/rc.lua

update () {
    rsync -va $EMACSDOT ~/.emacs

    rsync -va $BASHDOT ~/.bashrc

    rsync -va $VIMDOT/.vim ~/.vim

    rsync -va $VIMDOT/.vimrc ~/.vimrc

    mkdir -p ~/.config/awesome
    rsync -va $AWESOMEDOT ~/.config/awesome/rc.lua

    rsync -va ~/dotfiles/dotfiles.sh ~/bin/dotfiles.sh
}

push () {
    rsync -va ~/.emacs $EMACSDOT

    rsync -va ~/.bashrc $BASHDOT

    # rsync -va ~/.vim/ ~/dotfiles/.vim/

    rsync -va ~/.vimrc $VIMDOT/.vimrc

    rsync -va ~/.config/awesome/rc.lua $AWESOMEDOT

    rsync -va ~/bin/dotfiles.sh ~/dotfiles/dotfiles.sh
}

difference () {
    diff $EMACSDOT ~/.emacs

    diff $BASHDOT ~/.bashrc

    # diff ~/dotfiles/.vim ~/.vim

    diff $VIMDOT/.vimrc ~/.vimrc

    diff $AWESOMEDOT ~/.config/awesome/rc.lua

    diff ~/dotfiles/dotfiles.sh ~/bin/dotfiles.sh
}

while getopts "h?upd" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    u)
        update
        exit 0
        ;;
    p)
        push
        exit 0
        ;;
    d)
        difference
        exit 0
        ;;
    *)
        show_help
        exit 0
        ;;
    esac
done

# End of file
