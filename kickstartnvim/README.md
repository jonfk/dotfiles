## Customizations to Kickstart.nvim

Outlines the modifications applied to `kickstart.nvim`.

### init.lua

* `vim.g.have_nerd_font` set to `true`
* **Neovide Specific Configuration**

  ```lua
  if vim.g.neovide then
      require 'custom.neovide'
  end
  ```
* **Option Changes:**

  * `vim.o.relativenumber` set to `true`
  * `vim.o.scrolloff` changed from `10` to `5`
* **Commented-out Keymaps Removed:**

  * Removed the example of disabling arrow keys in normal mode
* **Plugin Setup (`lazy.setup`) Comments Reduced:**

  * Stripped down the explanatory comments in the `require('lazy').setup` block
  * Removed the `NMAC427/guess-indent.nvim` example
* **LuaSnip Snippet Configuration:**

  * Enabled `rafamadriz/friendly-snippets`, loading VSCode-style snippets lazily
  * Added snippet navigation mappings in insert and select modes:

    * `<C-L>` jumps forward
    * `<C-J>` jumps backward
* **`which-key` Registrations Added:**

  * `<leader>b` group for `[B]uffer` operations
  * `gr` group for `LSP keybinds`
* **Language Server Protocol (LSP) Configuration:**

  * Enabled by default (uncommented) in the `servers` table:

    * `gopls`
    * `rust_analyzer`
    * `ts_ls`
* **Formatter Configuration (`conform.nvim`):**

  * Added formatters for `rust` and `javascript`
* **New `mini.nvim` Plugins Configured:**

  * `mini.tabline`: setup added
  * `mini.sessions`: setup added with autocommands for auto-loading/saving sessions by working directory; includes helper `create_session_name_from_path`
  * `mini.pairs`: setup for insert, command, and terminal modes
  * `mini.files`: setup with custom mappings (`go_out = 'H'`), and keymaps `<leader>e`/`<leader>E` to open files at current file/project root
* **Treesitter `ensure_installed` Expanded:**

  * Added languages: `gitcommit`, `gitignore`, `git_config`, `git_rebase`, `go`, `gomod`, `ini`, `javascript`, `json`, `just`, `yaml`
* **Custom Plugins Imported:**

  * Uncommented `{ import = 'custom.plugins' }` to load plugins from `lua/custom/plugins/`
* **Custom Modules Required at End of File:**

  ```lua
  require 'custom.keymaps'
  require 'custom.folds'
  ```

### Custom Files

#### `lua/custom/folds.lua`

* Configures folding:

  * `foldmethod = 'expr'`, `foldexpr = 'nvim_treesitter#foldexpr()'`
  * Fallback to `indent` for buffers without Treesitter
  * Disable folding for files larger than 1MB
  * `foldlevel = 99` to start with all folds open

#### `lua/custom/keymaps.lua`

* Buffer navigation keymaps:

  * `<leader>bd`: delete buffer
  * `<leader>bn`: next buffer
  * `<leader>bp`: previous buffer
* `mini.files` autocommands:

  * `<esc><esc>` to close explorer
  * `<cr>` to "go in plus" (expand directory/open file and close explorer)

#### `lua/custom/neovide.lua`

* Neovide GUI settings:

  * `guifont = 'Hack Nerd Font:h14'`
  * Animation lengths for position and scroll
  * `macos_option_key_is_meta = 'only_left'`
  * `<D-v>` paste mappings in normal, visual, command, insert, and terminal modes

### Custom Plugin Configurations

#### `lua/custom/plugins/clipboard.lua`

* `gbprod/yanky.nvim` setup:

  * Uses `sqlite.lua` for persistent yank history
  * `<leader>p` to open yank history

#### `lua/custom/plugins/codecompanion.lua`

* `olimorris/codecompanion.nvim` setup:

  * Default adapter `anthropic` for chat, inline, and command modes
  * Debug logging enabled
  * Action palette via `telescope`

#### `lua/custom/plugins/flash.lua`

* `folke/flash.nvim` customization:

  * Disabled in search mode
  * Enabled jump labels for char mode
  * Keymaps: `s`, `S`, `r`, `R`, `<c-s>`

#### `lua/custom/plugins/terminal.lua`

* `akinsho/toggleterm.nvim` setup:

  * Floating terminals, `<C-\>` to toggle
  * `<leader>tt`, `<leader>tn`, `<leader>tr`, `<leader>ts` keymaps
* `ryanmsnyder/toggleterm-manager.nvim` included for enhanced management
