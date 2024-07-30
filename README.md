dotfiles
========

Quick install
```bash
# install gnu stow
./init.sh
```

Dotfiles are installed using stow. stow installs the dotfiles by creating symlinks into the target directory based on the structure in the dotfiles directory. 

By default the stow command will create symlinks for files in the parent directory of where you execute the command.

But you can override the default behavior and symlink files to another location with the -t (target) argument flag.

So my dotfiles setup assumes this repo is located in the root of your home directory `~/dotfiles`.

## Dependencies

### Dotfiles

- gnu stow

### Zsh

- [Antidote](https://github.com/mattmc3/antidote): zsh plugin manager
- 

### CLI Utilities

- fzf
- fd
- ripgrep
- fnm

#### Tmux

- [Tmux Yank](https://github.com/tmux-plugins/tmux-yank): Plugin to copy to system clipboard

### Editors

- neovim
    - [astronvim](https://astronvim.com/)
    - [kickstart](https://github.com/nvim-lua/kickstart.nvim)
- neovide: a cross platform neovim GUI

### Rust

- install rust https://www.rustup.rs/
- rustfmt: Is now a component in rustup and can be installed using `rustup component add rustfmt`
    - See [rustup book/components](https://rust-lang.github.io/rustup/concepts/components.html) for all components.

### Go

- Download and install Go `tar -C /usr/local -xzf go$VERSION.$OS-$ARCH.tar.gz`
- Create Go Path dir: `mkdir -p $HOME/Code/go/src`
- Install [gocode](https://github.com/nsf/gocode): `go get -u github.com/nsf/gocode`
- Install [goimport](https://github.com/bradfitz/goimports): `go get golang.org/x/tools/cmd/goimports`

### MacOS Utilities

- [Hidden Bar](https://github.com/dwarvesf/hidden) toggle hide menu bar items.
- [reattach-to-user-namespace](https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard): Used for [tmux-yank](https://github.com/tmux-plugins/tmux-yank)

