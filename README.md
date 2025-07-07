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
- tmux

### CLI Utilities

- fzf
- fd
- ripgrep
- fnm
- eza: ls replacement `cargo install eza`
- bat
    - on Ubuntu: sudo apt install bat && ln -s /usr/bin/batcat ~/.local/bin/bat
- llmcat
- [delta](https://dandavison.github.io/delta/introduction.html)
- zoxide for quick cd with `z` and `zi`

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
- [Aerospace](https://github.com/nikitabobko/AeroSpace) Lightning fast TWM for OSX with virtualized workspaces
    - [JankyBorders](https://github.com/FelixKratz/JankyBorders) Highlights the currently focussed window
- [SketchyBar](https://github.com/FelixKratz/SketchyBar) A status bar replacement #todo. Not currently using.
- [Maccy](https://github.com/p0deje/Maccy) Clipboard manager
- [Touch-Tab](https://github.com/ris58h/Touch-Tab?tab=readme-ov-file) Switch apps with trackpad gestures
- [AltTab](https://alt-tab-macos.netlify.app/) Window switching app. Has potential for creating shortcuts to windows

## Other Setup

### MacOS

#### Create custom shortcuts to focus on windows

[Original Source](https://www.reddit.com/r/MacOS/comments/j2472l/hotkey_for_switching_focus_to_specific_apps/)

Steps:

1. Open Automator create a new "Quick Action" (if you're looking at docs that say "Service", this appears to just be a name change around 10.6).
2. Select "no input" from any application in the new window
3. From the left-hand side, select run Applescript*1
4. Type in your Applescript (See below)
5. Save your automation.
6. Go to privacy and security and add automator onto the approved accessibility list
7. Go into keyboard shortcuts and navigate to services, your automator action should be there I believe under general.
8. Enable the action and select a hotkey.*2

Notes:

1. Many references I started with set me about converting my Applescript into an application. While I would ideally like to do this, I simply was unable to get it to work this way. If anyone knows how please let me know.
2. There are very few system-wide keyboard shortcuts that aren't already in use, and there's not really any good feedback to let you know if you're using one that's already in use besides things not really working. I would recommend a shift+option+command modifier plus a key. *DO NOT USE THE CONTROL KEY AS A MODIFIER** This is a trap I fell into because it turns out that anytime Applescript is executed with the control key held down, it will automatically show the startup options (which is not what you want for this to work).

```
on run {input, parameters}
	tell application "Google Chrome" to activate
end run
```

```
on run {input, parameters}
	tell application "iTerm" to activate
end run
```

#### Allow moving windows while dragging any part of the window

From [AeroSpace Readme](https://github.com/nikitabobko/AeroSpace?tab=readme-ov-file#tip-of-the-day)

```
defaults write -g NSWindowShouldDragOnGesture -bool true
```

> Now, you can move windows by holding ctrl+cmd and dragging any part of the window (not necessarily the window title)

