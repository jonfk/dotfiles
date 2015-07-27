dotfiles
========

Files can be synced using stow.

To install emacs config
```bash
$ stow emacs
```

By default the stow command will create symlinks for files in the parent directory of where you execute the command.
So my dotfiles setup assumes this repo is located in the root of your home directory `~/dotfiles`.

But you can override the default behavior and symlink files to another location with the -t (target) argument flag.