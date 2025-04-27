return {
	"rmagatti/auto-session",
	lazy = false,

	---enables autocomplete for opts
	---@module "auto-session"
	---@type AutoSession.Config
	opts = {
		suppressed_dirs = { "~/", "~/Downloads", "/" },
		auto_create = false,
		cwd_change_handling = true,
		session_lens = {
			mappings = {
				-- These should be the default values. Setting them explicitly anyway to document them here.
				-- {"i", "n"} for both insert and normal mode
				delete_session = { "i", "<C-D>" },
				alternate_session = { "i", "<C-S>" },
				copy_session = { "i", "<C-Y>" },
			},
		},
		-- log_level = 'debug',
	},
	keys = {
		--
		{ "<leader>wer", "<cmd>SessionSearch<CR>", desc = "S[e]ssion sea[r]ch" },
		{ "<leader>wes", "<cmd>SessionSave<CR>", desc = "Save [s]ession" },
		{ "<leader>wea", "<cmd>SessionToggleAutoSave<CR>", desc = "Toggle s[e]ssion [a]utosave" },
	},
}
