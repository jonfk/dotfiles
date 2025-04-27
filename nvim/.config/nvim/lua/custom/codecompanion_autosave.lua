local config = {
	-- Define the directory where chat history will be saved.
	-- Using vim.fn.stdpath('data') is generally preferred for storing plugin data.
	save_dir = vim.fn.stdpath("data") .. "/codecompanion_history",
	-- Define the events that trigger saving.
	-- 'TextChanged' saves very frequently. Remove it if you prefer saving only on losing focus or leaving the buffer.
	save_events = { "InsertLeave", "TextChanged", "BufLeave", "FocusLost" },
	-- Set to true to show a notification when a buffer is saved.
	show_save_notification = false,
}

-- Ensure the save directory exists; create it if it doesn't.
vim.fn.mkdir(config.save_dir, "p")

-- Create a dedicated autocommand group.
-- Using a group allows easy clearing and management of these specific autocommands.
-- `clear = true` ensures that reloading this script doesn't duplicate autocommands.
local augroup = vim.api.nvim_create_augroup("CodeCompanionAutoSave", { clear = true })

-- Function to save the content of a CodeCompanion buffer.
local function save_codecompanion_buffer(bufnr)
	-- Ensure the buffer number is valid.
	if not vim.api.nvim_buf_is_valid(bufnr) then
		vim.notify("CodeCompanion AutoSave: Invalid buffer number " .. bufnr, vim.log.levels.WARN)
		return
	end

	-- Get the buffer name.
	local bufname = vim.api.nvim_buf_get_name(bufnr)

	-- Double-check if it's actually a CodeCompanion buffer (safety measure).
	if not bufname or not bufname:match("%[CodeCompanion%]") then
		return
	end

	-- Extract the unique ID from the buffer name (e.g., "[CodeCompanion] 123").
	local id = bufname:match("%[CodeCompanion%] (%d+)")
	local date_str = os.date("%Y-%m-%d")
	local save_path

	-- Construct the save path. Use date and ID if available, otherwise fallback to timestamp.
	if id then
		-- Format: /path/to/save_dir/YYYY-MM-DD_codecompanion_ID.md
		save_path = config.save_dir .. "/" .. date_str .. "_codecompanion_" .. id .. ".md"
	else
		-- Fallback format: /path/to/save_dir/YYYY-MM-DD_codecompanion_HHMMSS.md
		local time_str = os.date("%H%M%S")
		save_path = config.save_dir .. "/" .. date_str .. "_codecompanion_" .. time_str .. ".md"
		vim.notify(
			"CodeCompanion AutoSave: Could not extract ID from buffer name '" .. bufname .. "'. Using timestamp.",
			vim.log.levels.WARN
		)
	end

	-- Get all lines from the buffer.
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	-- Attempt to open the file for writing.
	local file, err_open = io.open(save_path, "w")
	if not file then
		vim.notify(
			"CodeCompanion AutoSave: Error opening file '" .. save_path .. "': " .. (err_open or "Unknown error"),
			vim.log.levels.ERROR
		)
		return
	end

	-- Attempt to write the buffer content to the file.
	local ok, err_write = file:write(table.concat(lines, "\n"))
	if not ok then
		vim.notify(
			"CodeCompanion AutoSave: Error writing to file '" .. save_path .. "': " .. (err_write or "Unknown error"),
			vim.log.levels.ERROR
		)
	else
		if config.show_save_notification then
			vim.notify(
				"CodeCompanion buffer saved to: " .. vim.fn.fnamemodify(save_path, ":t"),
				vim.log.levels.INFO,
				{ title = "CodeCompanion AutoSave" }
			)
		end
	end

	-- Close the file handle.
	file:close()
end

vim.api.nvim_create_autocmd(config.save_events, {
	group = augroup,
	-- Setting a pattern here doesn't work because they are meant to match file buffers while this is a nofile buffer
	pattern = "*",
	desc = "Auto-save CodeCompanion chat buffer content",
	callback = function(args)
		local bufnr = args.buf
		local bufname = vim.api.nvim_buf_get_name(bufnr)

		if bufname:match("%[CodeCompanion%]") then
			save_codecompanion_buffer(args.buf)
		end
	end,
})
