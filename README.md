dotfiles
========

Quick install
```bash
# install gnu stow
./init.sh
```

Files can be synced using stow.

To install emacs config
```bash
$ stow emacs
```

By default the stow command will create symlinks for files in the parent directory of where you execute the command.
So my dotfiles setup assumes this repo is located in the root of your home directory `~/dotfiles`.

But you can override the default behavior and symlink files to another location with the -t (target) argument flag.

## Dependencies

### Zsh
- [Prezto](https://github.com/sorin-ionescu/prezto)
Notes on config files: [Link](http://zshwiki.org/home/config/files)
My Fork: https://github.com/jonfk/prezto

### Rust
- install rust https://www.rustup.rs/
- https://github.com/phildawes/racer
- clone rust source: `git clone git@github.com:rust-lang/rust.git $HOME/Code/rust/rust-src`
- rust-fmt: `cargo install rustfmt`

### Go
- Download and install Go `tar -C /usr/local -xzf go$VERSION.$OS-$ARCH.tar.gz`
- Create Go Path dir: `mkdir -p $HOME/Code/go/src`
- Install [gocode](https://github.com/nsf/gocode): `go get -u github.com/nsf/gocode`
- Install [goimport](https://github.com/bradfitz/goimports): `go get golang.org/x/tools/cmd/goimports`

### Git annex
- install git annex
