#!/usr/bin/env bash

set -e
#set -x

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

update () {
    rsync -va ~/dotfiles/.emacs ~/.emacs

    rsync -va ~/dotfiles/.bashrc ~/.bashrc

    rsync -va ~/dotfiles/.vim ~/.vim

    rsync -va ~/dotfiles/.vimrc ~/.vimrc
}

push () {
    rsync -va ~/.emacs ~/dotfiles/.emacs

    rsync -va ~/.bashrc ~/dotfiles/.bashrc

    rsync -va ~/.vim ~/dotfiles/.vim

    rsync -va ~/.vimrc ~/dotfiles/.vimrc
}

difference () {
    diff ~/dotfiles/.emacs ~/.emacs

    diff ~/dotfiles/.bashrc ~/.bashrc

    # diff ~/dotfiles/.vim ~/.vim

    diff ~/dotfiles/.vimrc ~/.vimrc
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
