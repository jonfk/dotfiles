## Customizations to Kickstart.nvim

Outlines the modifications applied to `kickstart.nvim`.

### init.lua

* `vim.g.have_nerd_font` set to `true`
* Neovide Specific Configuration
    ```lua
    if vim.g.neovide then
        require 'custom.neovide'
    end
    ```
* **Option Changes:**
    * `vim.o.relativenumber` set to `true`
    * `vim.o.scrolloff` has been changed from `10` to `5`.
* **Commented-out Keymaps Removed:**
    * The commented-out example keymaps for disabling arrow keys in normal mode have been removed.
* **Plugin Setup (`lazy.setup`) Comments Reduced:**
    * A significant portion of the explanatory comments within the `require('lazy').setup` block, detailing how to add and configure plugins, has been removed. The configuration for `NMAC427/guess-indent.nvim` was also removed as part of this cleanup (it was an example).
* **`which-key` Registrations Added:**
    * New groups for `which-key` have been added:
        * `<leader>b` for `[B]uffer` operations.
        * `gr` for `LSP keybinds`.
* **Language Server Protocol (LSP) Configuration:**
    * The following language servers are now enabled by default (uncommented) in the `servers` table for `nvim-lspconfig`:
        * `gopls`
        * `rust_analyzer`
        * `ts_ls`
* **Formatter Configuration (`conform.nvim`):**
    * Formatters for `rust` and `javascript` have been added:
* **New `mini.nvim` Plugins Configured:**
    * `mini.tabline`: Setup added.
    * `mini.sessions`: Setup added, along with autocommands for automatic session loading and saving based on the current working directory. Includes a helper function `create_session_name_from_path` to generate safe session names.
    * `mini.pairs`: Setup added for insert, command, and terminal modes.
    * `mini.files`: Setup added with custom mappings for `go_in` (emptied), `go_out` (`H`), and `go_out_plus` (emptied). Keymaps `<leader>e` and `<leader>E` are added to open `mini.files` at the current file or project root, respectively.
* **Treesitter `ensure_installed` Expanded:**
    * The list of languages for `nvim-treesitter` to `ensure_installed` has been significantly expanded to include: `gitcommit`, `gitignore`, `git_config`, `git_rebase`, `go`, `gomod`, `ini`, `javascript`, `json`, `just`, `yaml`.
* **Custom Plugins Imported:**
    * The line `{ import = 'custom.plugins' }` has been uncommented, enabling the loading of plugins from the `lua/custom/plugins/` directory.
* **Custom Modules Required:**
    * The following custom modules are now required at the end of the file:
        ```lua
        require 'custom.keymaps'
        require 'custom.folds'
        ```

### Custom Files

* **`lua/custom/folds.lua`:**
    * Configures folding settings.
    * Sets `foldmethod` to `expr` and `foldexpr` to `nvim_treesitter#foldexpr()`.
    * Includes an autocommand to fallback to `indent` folding if Treesitter is not available for the current buffer.
    * Adds a performance optimization to disable folding for files larger than 1MB.
    * Sets `foldlevel` to `99` to start with all folds open.

* **`lua/custom/keymaps.lua`:**
    * Defines custom keymappings.
    * Adds buffer navigation keymaps:
        * `<leader>bd`: Delete buffer
        * `<leader>bn`: Next buffer
        * `<leader>bp`: Previous buffer
    * Adds autocommands for `mini.files` to:
        * Map `<esc><esc>` to close the explorer.
        * Map `<cr>` to "go in plus" (expand directory or open file and close explorer).

* **`lua/custom/neovide.lua`:**
    * Contains settings specific to the Neovide GUI.
    * Sets `guifont` to `Hack Nerd Font:h14`.
    * Configures Neovide animation lengths (`neovide_position_animation_length`, `neovide_scroll_animation_length`).
    * Sets `neovide_input_macos_option_key_is_meta` to `only_left`.
    * Adds various keymaps for `<D-v>` (Cmd-v on macOS) to handle pasting from the system clipboard in normal, visual, command, insert, and terminal modes.

* **`lua/custom/plugins/clipboard.lua`:**
    * Configures the `gbprod/yanky.nvim` plugin for enhanced yank/paste functionality.
    * Sets up `yanky.nvim` with `sqlite.lua` for persistent yank history.
    * Defines keymaps for opening yank history (`<leader>p`) and standard yank/put operations.

* **`lua/custom/plugins/codecompanion.lua`:**
    * Configures the `olimorris/codecompanion.nvim` plugin (likely for AI-assisted coding).
    * Sets the default adapter for chat, inline, and command strategies to `anthropic`.
    * Enables debug logging.
    * Configures display settings, including showing settings in chat and using `telescope` for the action palette.

* **`lua/custom/plugins/flash.lua`:**
    * Configures the `folke/flash.nvim` plugin for improved cursor movement/jumping.
    * Disables flash for search mode (`modes.search.enabled = false`).
    * Enables jump labels for char mode.
    * Defines keymaps for various flash functions: `s` (jump), `S` (treesitter), `r` (remote), `R` (treesitter search), and `<c-s>` (toggle flash search in command mode).

* **`lua/custom/plugins/terminal.lua`:**
    * Configures `akinsho/toggleterm.nvim` for managing terminal windows.
    * Sets toggleterm direction to `float` and the open mapping to `<C-\>`.
    * Adds keymaps:
        * `<leader>tt`: Toggle terminal.
        * `<leader>tn`: Open new terminal in the current buffer's directory (or project root if buffer has no file).
        * `<leader>tr`: Toggle/Open new terminal in Neovim's current working directory.
        * `<leader>ts`: Select terminal.
    * Includes `ryanmsnyder/toggleterm-manager.nvim` for enhanced terminal management, likely integrated with Telescope.
