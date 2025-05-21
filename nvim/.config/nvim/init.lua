--[[

Minimal config with no plugins based off of kickstart.nvim

--]]

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.o.number = true
vim.o.relativenumber = true

vim.o.mouse = "a"

vim.o.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

-- Save undo history
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = "yes"

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.o.inccommand = "split"

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 5

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Disable arrow keys in normal mode
vim.keymap.set("n", "<left>", '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set("n", "<right>", '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set("n", "<up>", '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set("n", "<down>", '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Buffer Keymaps ]]
vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "Previous buffer" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- [[ mini.nvim ]]
local path_package = vim.fn.stdpath("data") .. "/site/"
local mini_path = path_package .. "pack/deps/start/mini.nvim"
if not vim.loop.fs_stat(mini_path) then
	vim.cmd('echo "Installing `mini.nvim`" | redraw')
	local clone_cmd = {
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/echasnovski/mini.nvim",
		mini_path,
	}
	vim.fn.system(clone_cmd)
	vim.cmd("packadd mini.nvim | helptags ALL")
	vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

require("mini.deps").setup({ path = { package = path_package } })

MiniDeps.add({
	source = "nvim-treesitter/nvim-treesitter",
	-- Use 'master' while monitoring updates in 'main'
	checkout = "master",
	monitor = "main",
	-- Perform action after every checkout
	hooks = {
		post_checkout = function()
			vim.cmd("TSUpdate")
		end,
	},
})
-- Possible to immediately execute code which depends on the added plugin
require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"bash",
		"c",
		"diff",
		"gitcommit",
		"gitignore",
		"git_config",
		"git_rebase",
		"go",
		"gomod",
		"html",
		"ini",
		"javascript",
		"json",
		"just",
		"lua",
		"luadoc",
		"markdown",
		"markdown_inline",
		"query",
		"vim",
		"vimdoc",
		"yaml",
	},
	highlight = { enable = true },
})

MiniDeps.add({
	source = "rafamadriz/friendly-snippets",
	checkout = "main",
})

-- [[ mini.nvim ]]
MiniDeps.now(function()
  -- stylua: ignore start
  local base16_palettes = {
    Chalk = {
      base00 = "#151515", base01 = "#202020", base02 = "#303030", base03 = "#505050",
      base04 = "#b0b0b0", base05 = "#d0d0d0", base06 = "#e0e0e0", base07 = "#f5f5f5",
      base08 = "#fb9fb1", base09 = "#eda987", base0A = "#ddb26f", base0B = "#acc267",
      base0C = "#12cfc0", base0D = "#6fc2ef", base0E = "#e1a3ee", base0F = "#deaf8f",
    },
    ["Catppuccin Mocha"] = {
      base00 = "#1e1e2e", base01 = "#181825", base02 = "#313244", base03 = "#45475a",
      base04 = "#585b70", base05 = "#cdd6f4", base06 = "#f5e0dc", base07 = "#b4befe",
      base08 = "#f38ba8", base09 = "#fab387", base0A = "#f9e2af", base0B = "#a6e3a1",
      base0C = "#94e2d5", base0D = "#89b4fa", base0E = "#cba6f7", base0F = "#f2cdcd",
    },
    ["Ayu Dark"] = {
      base00 = "#0F1419", base01 = "#131721", base02 = "#272D38", base03 = "#3E4B59",
      base04 = "#BFBDB6", base05 = "#E6E1CF", base06 = "#E6E1CF", base07 = "#F3F4F5",
      base08 = "#F07178", base09 = "#FF8F40", base0A = "#FFB454", base0B = "#B8CC52",
      base0C = "#95E6CB", base0D = "#59C2FF", base0E = "#D2A6FF", base0F = "#E6B673",
    },
    ["3024"] = {
      base00 = "#090300", base01 = "#3a3432", base02 = "#4a4543", base03 = "#5c5855",
      base04 = "#807d7c", base05 = "#a5a2a2", base06 = "#d6d5d4", base07 = "#f7f7f7",
      base08 = "#db2d20", base09 = "#e8bbd0", base0A = "#fded02", base0B = "#01a252",
      base0C = "#b5e4f4", base0D = "#01a0e4", base0E = "#a16a94", base0F = "#cdab53",
    },
    ["OneDark Dark"] = {
      base00 = "#000000", base01 = "#1c1f24", base02 = "#2c313a", base03 = "#434852",
      base04 = "#565c64", base05 = "#abb2bf", base06 = "#b6bdca", base07 = "#c8ccd4",
      base08 = "#ef596f", base09 = "#d19a66", base0A = "#e5c07b", base0B = "#89ca78",
      base0C = "#2bbac5", base0D = "#61afef", base0E = "#d55fde", base0F = "#be5046",
    },
    ["Precious Dark Eleven"] = {
      base00 = "#1c1e20", base01 = "#292b2d", base02 = "#37393a", base03 = "#858585",
      base04 = "#a8a8a7", base05 = "#b8b7b6", base06 = "#b8b7b6", base07 = "#b8b7b6",
      base08 = "#ff8782", base09 = "#ea9755", base0A = "#d0a543", base0B = "#95b658",
      base0C = "#42bda7", base0D = "#68b0ee", base0E = "#b799fe", base0F = "#f382d8",
    },
    ["Primer Dark"] = {
      base00 = "#010409", base01 = "#21262d", base02 = "#30363d", base03 = "#484f58",
      base04 = "#8b949e", base05 = "#b1bac4", base06 = "#c9d1d9", base07 = "#f0f6fc",
      base08 = "#ff7b72", base09 = "#f0883e", base0A = "#d29922", base0B = "#3fb950",
      base0C = "#a5d6ff", base0D = "#58a6ff", base0E = "#f778ba", base0F = "#bd561d",
    },
    ["Solar Flare"] = {
      base00 = "#18262F", base01 = "#222E38", base02 = "#586875", base03 = "#667581",
      base04 = "#85939E", base05 = "#A6AFB8", base06 = "#E8E9ED", base07 = "#F5F7FA",
      base08 = "#EF5253", base09 = "#E66B2B", base0A = "#E4B51C", base0B = "#7CC844",
      base0C = "#52CBB0", base0D = "#33B5E1", base0E = "#A363D5", base0F = "#D73C9A",
    },
    ["Tokyo Night Dark"] = {
      base00 = "#1A1B26", base01 = "#16161E", base02 = "#2F3549", base03 = "#444B6A",
      base04 = "#787C99", base05 = "#A9B1D6", base06 = "#CBCCD1", base07 = "#D5D6DB",
      base08 = "#C0CAF5", base09 = "#A9B1D6", base0A = "#0DB9D7", base0B = "#9ECE6A",
      base0C = "#B4F9F8", base0D = "#2AC3DE", base0E = "#BB9AF7", base0F = "#F7768E",
    },
  }
	-- stylua: ignore end

	-- Seed RNG once (you could also seed with os.time())
	math.randomseed(vim.loop.hrtime() % 1e9)

	-- Pick a random palette name
	local names = vim.tbl_keys(base16_palettes)
	local choice = names[math.random(#names)]
	local palette = base16_palettes[choice]
	require("mini.base16").setup({
		palette = palette,
	})
	vim.notify(string.format("mini.base16 → using palette: %s", choice), vim.log.levels.INFO)

	require("mini.icons").setup()
	require("mini.statusline").setup()
	require("mini.tabline").setup()
end)

-- [[ flash.nvim ]]
MiniDeps.add({
	source = "folke/flash.nvim",
	checkout = "main",
})

MiniDeps.later(function()
	require("flash").setup({})

	local map = vim.keymap.set
	-- Normal, Visual, and Operator-pending mode mappings
	map({ "n", "x", "o" }, "s", function()
		require("flash").jump()
	end, { desc = "Flash" })
	map({ "n", "x", "o" }, "S", function()
		require("flash").treesitter()
	end, { desc = "Flash Treesitter" })

	-- Operator-pending mode only
	map("o", "r", function()
		require("flash").remote()
	end, { desc = "Remote Flash" })

	-- Operator-pending and Visual modes
	map({ "o", "x" }, "R", function()
		require("flash").treesitter_search()
	end, { desc = "Treesitter Search" })

	-- Command mode
	map("c", "<c-s>", function()
		require("flash").toggle()
	end, { desc = "Toggle Flash Search" })
end)

MiniDeps.add({
	source = "lewis6991/gitsigns.nvim",
	checkout = "main",
})

MiniDeps.later(function()
	require("gitsigns").setup({
		signs = {
			add = { text = "+" },
			change = { text = "~" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
		},
	})
end)
