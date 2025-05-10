--- Get the escaped session name for the current working directory
--- This function returns the session name that auto-session would use for the current directory.
--- It assumes there is always exactly one session per working directory.
---
--- @return string Returns the escaped version of the CWD's session name.
---   The string has path characters escaped and works with both *nix and Windows.
---   NOTE: This string is NOT escaped for use in Vim commands
local function get_current_cwd_session_name()
	local Lib = require("auto-session.lib")

	local cwd_session_name = vim.fn.getcwd(-1, -1)

	-- Return the escaped session name
	return Lib.escape_session_name(cwd_session_name)
end

--- Get detailed information about a terminal buffer
--- This function extracts various pieces of information from a terminal buffer,
--- including job ID, CWD, scrollback content, and cursor position.
---
--- @param buf_id number The buffer ID to check
--- @return table|nil Returns a table with terminal information or nil if not a valid terminal buffer
---   The returned table contains these fields:
---     - pid: The process id of the top-level process assumed to be the shell
---     - buffer_name: The name of the buffer
---     - cwd: The current working directory of the terminal process
---     - scrollback: A table containing the terminal's scrollback content (limited to max_save_lines)
local function get_terminal_info(buf_id)
	local info = {}

	-- Check if buffer is a terminal
	if vim.bo[buf_id].buftype ~= "terminal" then
		return nil
	end

	-- Get job ID (process PID)
	local job_id = vim.b[buf_id].terminal_job_id
	if not job_id then
		return nil
	end

	local pid = vim.fn.jobpid(job_id)

	info.pid = pid
	info.buffer_name = vim.api.nvim_buf_get_name(buf_id)

	-- Get CWD based on OS
	local uname = vim.loop.os_uname()
	local os_type = uname.sysname

	if os_type == "Windows" or os_type == "Windows_NT" then
		vim.notify("Windows is unsupported", vim.log.levels.WARN)
		return nil
	end

	if os_type == "Darwin" then
		-- For macOS
		-- Using vim.fn.system with proper error handling
		local cmd = string.format('lsof -a -d cwd -p %d | tail -1 | awk "{print \\$9}"', pid)

		-- Use pcall to catch any exceptions in the system call
		local ok, result = pcall(vim.fn.system, cmd)

		if ok and vim.v.shell_error == 0 and result and result ~= "" then
			-- Command succeeded and returned a non-empty result
			result = result:gsub("^%s*(.-)%s*$", "%1")
			info.cwd = result
			vim.notify("Terminal CWD found: " .. result, vim.log.levels.INFO)
		else
			-- Command failed or returned empty result
			local error_msg = ok and "empty result" or result
			vim.notify("lsof command failed: " .. error_msg .. ", using Neovim CWD", vim.log.levels.WARN)
			info.cwd = vim.fn.getcwd()
		end
	elseif os_type == "Linux" then
		-- For Linux
		local success = false

		-- Try reading /proc/{pid}/cwd
		local cwd_path = string.format("/proc/%d/cwd", job_id)
		local cwd = vim.fn.resolve(cwd_path)

		if cwd and cwd ~= "" then
			info.cwd = cwd
			success = true
		end

		-- Fallback to ps if proc approach doesn't work
		if not success then
			local cmd = string.format("ps -o cwd= -p %d", job_id)
			local handle, err = io.popen(cmd)
			if handle then
				local result = handle:read("*l")
				handle:close()

				if result and result ~= "" then
					info.cwd = result
					success = true
				end
			end
		end
	end

	-- Default to current working directory if we couldn't determine it
	if not info.cwd or info.cwd == "" then
		info.cwd = vim.fn.getcwd()
	end

	-- Get terminal buffer content (scrollback)
	local scrollback = {}
	local max_lines = vim.api.nvim_buf_line_count(buf_id)

	-- Limit the number of lines to save to avoid huge files
	local max_save_lines = 1000
	local start_line = math.max(0, max_lines - max_save_lines)

	-- Only load if there are lines to load and if the buffer isn't too large
	if start_line < max_lines then
		-- Use pcall to catch any potential errors
		local ok, lines = pcall(vim.api.nvim_buf_get_lines, buf_id, start_line, max_lines, false)
		if ok then
			scrollback = lines
		else
			vim.notify("Failed to get buffer lines: " .. tostring(lines), vim.log.levels.WARN)
			scrollback = {}
		end
	end

	info.scrollback = scrollback

	return info
end

--- Save the state of all terminal buffers in the current session
--- This function identifies all terminal buffers, collects their state information,
--- and saves it to a JSON file in the Neovim data directory. The file is named
--- based on the current working directory's session name.
---
--- The information saved includes:
---   - Terminal process IDs
---   - Working directories
---   - Scrollback content (limited to 1000 lines per terminal)
---
--- @return nil
--- @see get_current_cwd_session_name
--- @see get_terminal_info
local function save_terminal_state()
	local uname = vim.loop.os_uname()
	local os_type = uname.sysname

	if os_type == "Windows" or os_type == "Windows_NT" then
		vim.notify("Windows is unsupported", vim.log.levels.WARN)
		return
	end

	local terminal_info = {}

	-- Get all buffers
	local buffers = vim.api.nvim_list_bufs()

	for _, buf_id in ipairs(buffers) do
		-- Check if buffer exists and is loaded
		if vim.api.nvim_buf_is_valid(buf_id) and vim.api.nvim_buf_is_loaded(buf_id) then
			-- Check if buffer is a terminal
			if vim.bo[buf_id].buftype == "terminal" then
				local info = get_terminal_info(buf_id)
				if info then
					table.insert(terminal_info, info)
				end
			end
		end
	end

	-- Only proceed if we found terminal buffers
	if #terminal_info == 0 then
		vim.notify("No terminal buffers found to save", vim.log.levels.INFO)
		return
	end

	-- Save to file
	local session_name = get_current_cwd_session_name()
	local terminal_data_path = vim.fn.stdpath("data") .. "/terminal_sessions/" .. session_name .. ".json"

	-- Create directory if it doesn't exist
	local dir_path = vim.fn.fnamemodify(terminal_data_path, ":h")
	local ok, err = pcall(vim.fn.mkdir, dir_path, "p")
	if not ok then
		vim.notify("Failed to create directory: " .. tostring(err), vim.log.levels.ERROR)
		return
	end

	-- Convert to JSON
	local ok, json = pcall(vim.fn.json_encode, terminal_info)
	if not ok then
		vim.notify("Failed to encode terminal data to JSON: " .. tostring(json), vim.log.levels.ERROR)
		return
	end

	-- Save to file with proper resource management
	local ok, err = pcall(function()
		local file = io.open(terminal_data_path, "w")
		if not file then
			error("Could not open file for writing")
		end

		local write_ok, write_err = file:write(json)
		if not write_ok then
			file:close()
			error("Failed to write data: " .. tostring(write_err))
		end

		file:close()
		return true
	end)

	if ok then
		vim.notify("Terminal state saved for session: " .. session_name, vim.log.levels.INFO)
	else
		vim.notify("Failed to save terminal state: " .. tostring(err), vim.log.levels.ERROR)
	end
end

return {
	save_terminal_state = save_terminal_state,
}
