-- fzfFilter.lua
-- Module for non-interactive filtering of lists using fzf.

local M = {}
local mt = { __index = M }

local fs = require("hs.fs")
local task = require("hs.task")
local inspect = require("hs.inspect")
local log = hs.logger.new("fzfFilter") -- Get a logger instance

-- Helper function to escape characters that have special meaning in Lua patterns
-- (used for the delimiter when parsing fzf output).
local function pattern_escape(str)
	if not str then
		return ""
	end
	-- Escapes: ( ) . % + - * ? [ ] ^ $
	return str:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
end

-- Internal function to check if a path is a file and executable.
local function isFileAndExecutable(filePath)
	if not filePath then
		log.w("isFileAndExecutable: filePath is nil")
		return false, "Path is nil"
	end
	log.d(string.format("isFileAndExecutable: Checking path: '%s'", filePath))

	local attrs = fs.attributes(filePath)
	if not attrs then
		log.w(string.format("isFileAndExecutable: hs.fs.attributes returned nil for '%s'", filePath))
		return false, string.format("Path '%s' not found or attributes unreadable", filePath)
	end

	log.d("isFileAndExecutable: Attributes for '" .. filePath .. "':", inspect(attrs))

	if attrs.mode ~= "file" then
		log.w(string.format("isFileAndExecutable: Path '%s' is not a file (mode: %s)", filePath, attrs.mode))
		return false, string.format("Path '%s' is not a file (mode: %s)", filePath, attrs.mode)
	end

	if
		attrs.permissions:sub(3, 3) == "x"
		or attrs.permissions:sub(6, 6) == "x"
		or attrs.permissions:sub(9, 9) == "x"
	then
		log.d(string.format("isFileAndExecutable: Path '%s' is executable.", filePath))
		return true
	else
		log.w(
			string.format(
				"isFileAndExecutable: Path '%s' is not executable (permissions: %s).",
				filePath,
				attrs.permissions or "N/A"
			)
		)
		return false, string.format("Path '%s' is not executable.", filePath)
	end
end

--- Initializes a new fzfFilter instance.
-- If `fzfBinaryPathInput` is provided, it will be used and validated.
-- Otherwise, it assumes 'fzf' is on the system PATH and will use "fzf" as the command.
--
-- @param fzfBinaryPathInput (string) An absolute path to the fzf binary. Required because of hs.task.new requires full path to binary.
-- @return (table|nil) An fzfFilter instance if initialization is successful.
-- @return (string|nil) An error message if initialization fails (e.g., a provided path is invalid).
function M.new(fzfBinaryPathInput)
	local self = setmetatable({}, mt)
	local errMessage

	if fzfBinaryPathInput then
		-- User provided a specific path, validate it
		log.d(string.format("M.new: Using provided fzfBinaryPathInput: '%s'", fzfBinaryPathInput))
		local resolvedPath = fs.pathToAbsolute(fzfBinaryPathInput)
		if not resolvedPath then
			errMessage = string.format("Could not resolve '%s' to an absolute path.", fzfBinaryPathInput)
			log.e("M.new: " .. errMessage)
			return nil, errMessage
		end
		log.d(string.format("M.new: Resolved fzf path to: '%s'", resolvedPath))

		local isExecutable, execErr = isFileAndExecutable(resolvedPath)
		if not isExecutable then
			errMessage = string.format("fzf at resolved path '%s' is not suitable. Error: %s", resolvedPath, execErr)
			log.e("M.new: " .. errMessage)
			return nil, errMessage
		end
		self.fzfPath = resolvedPath
		log.i(string.format("fzfFilter initialized successfully. fzf executable: %s", self.fzfPath))
	else
		errMessage = string.format("fzfBinaryPathInput not provided.")
		log.e("M.new: " .. errMessage)
		return nil, "fzfBinaryPathInput is required."
	end

	return self
end

--- Filters a list of items using fzf non-interactively based on a query.
--
-- @param inputList (table) An array of items to filter. Each item MUST be a table
--        of the shape `{ id = "string", searchText = "string for fzf to search" }`.
--        The `id` MUST be a string and SHOULD NOT contain the chosen delimiter.
-- @param query (string) The search query string to pass to fzf's `--filter` argument.
-- @param callback (function) A function to be called when fzf completes.
--        It will receive two arguments: `(matchedIds, errorInfo)`
--        - `matchedIds` (table|nil): An array containing the string `id` values of the items
--          that matched the query. This will be an empty table `{}` if there were
--          no matches (fzf exit code 1) or if fzf was cancelled (e.g. exit code 130).
--          It will be `nil` if a more significant fzf error occurred.
--        - `errorInfo` (table|nil): If an error occurred during fzf execution (other than
--          no-match or cancel), this table will contain details:
--          `{ message = "string", exitCode = number, stdOut = "string", stdErr = "string" }`.
--          Will be `nil` on successful completion (including no matches).
-- @param options (table, optional) A table of additional options:
--        - `fzfArgs` (table, optional): An array of strings representing additional
--          command-line arguments to pass to fzf (e.g., `{"-i"}` for case-insensitivity,
--          `{"--tiebreak=index"}`). Defaults to `{}`.
--        - `delimiter` (string, optional): A string used to separate
--          the `id` from the `searchText` when feeding data to fzf. Should ideally be short.
--          Should not contain charactrs special to fzf regex engine (e.g. . * + ? ( ) [ ] { } \ ^ $).
--          Default: `"\t"` (tab character). It's crucial that `id` strings do not contain this delimiter.
--
-- @return (hs.task|nil) The hs.task object if the task was successfully created and started, or nil if filtering was completed synchronously (e.g. empty input list) or an immediate error occurred.
-- @return (string|nil) An error message if there was an immediate problem creating or
--                      starting the task (e.g., fzf path not initialized, invalid params).
function M:filter(inputList, query, callback, options)
	if not self.fzfPath then
		log.e("filter: fzfPath not initialized in this instance.")
		return nil, "fzfFilter instance not properly initialized (fzf path missing)."
	end

	-- Parameter validation
	local validationError
	if type(inputList) ~= "table" then
		validationError = "inputList must be a table."
	elseif type(query) ~= "string" then
		validationError = "query must be a string."
	elseif type(callback) ~= "function" then
		validationError = "callback must be a function."
	end
	if validationError then
		log.e("filter: " .. validationError)
		if type(callback) == "function" then
			callback(nil, { message = validationError })
		end
		return nil, validationError
	end

	options = options or {}
	if type(options) ~= "table" then
		validationError = "options, if provided, must be a table."
		log.e("filter: " .. validationError)
		if type(callback) == "function" then
			callback(nil, { message = validationError })
		end
		return nil, validationError
	end

	local userFzfArgs = options.fzfArgs or {}
	if type(userFzfArgs) ~= "table" then
		validationError = "options.fzfArgs, if provided, must be a table of strings."
		log.e("filter: " .. validationError)
		if type(callback) == "function" then
			callback(nil, { message = validationError })
		end
		return nil, validationError
	end

	local delimiter = options.delimiter or "\t"
	if type(delimiter) ~= "string" or #delimiter == 0 then
		validationError = "options.delimiter must be a non-empty string."
		log.e("filter: " .. validationError)
		if type(callback) == "function" then
			callback(nil, { message = validationError })
		end
		return nil, validationError
	end
	local escapedDelimiterPattern = pattern_escape(delimiter)

	-- Prepare input for fzf and validate items
	local linesForFzf = {}
	for i, item in ipairs(inputList) do
		if type(item) ~= "table" or type(item.id) ~= "string" or type(item.searchText) ~= "string" then
			validationError =
				string.format('Invalid item at index %d in inputList. Expected {id="string", searchText="string"}.', i)
			log.e("filter: " .. validationError)
			if type(callback) == "function" then
				callback(nil, { message = validationError })
			end
			return nil, validationError
		end
		-- Critical check: ID must not contain the delimiter
		if item.id:find(delimiter, 1, true) then
			validationError = string.format(
				"Invalid item at index %d: id '%s' contains the delimiter '%s'. This is not allowed as it breaks output parsing.",
				i,
				item.id,
				delimiter
			)
			log.e("filter: " .. validationError)
			if type(callback) == "function" then
				callback(nil, { message = validationError })
			end
			return nil, validationError
		end
		table.insert(linesForFzf, item.id .. delimiter .. item.searchText)
	end

	-- If input list is empty, no need to run fzf.
	if #linesForFzf == 0 then
		log.d("filter: Input list is empty. Calling callback with no matches immediately.")
		callback({}, nil) -- No data to filter, so no matches.
		return nil -- No task to return as it wasn't created.
	end

	local fzfInputString = table.concat(linesForFzf, "\n")

	-- Core fzf arguments for non-interactive filtering:
	-- --filter=<query>: The search term.
	-- --delimiter=<delimiter>: Specifies how fzf should parse fields in the input.
	-- --with-nth=2: Tells fzf to perform matching only against the 2nd field (searchText).
	--               FZF will still output the *entire original line* that matched.
	local fzfBaseArgs = {
		"--filter=" .. query,
		"--delimiter=" .. delimiter,
		"--with-nth=2",
	}

	local allFzfArgs = {}
	for _, arg in ipairs(fzfBaseArgs) do
		table.insert(allFzfArgs, arg)
	end
	for _, arg in ipairs(userFzfArgs) do
		table.insert(allFzfArgs, arg)
	end

	log.d(string.format("filter: Running fzf with command: '%s' %s", self.fzfPath, table.concat(allFzfArgs, " ")))
	if #fzfInputString > 1000 then -- Avoid logging excessively large inputs
		log.d(
			string.format(
				"filter: FZF input string has %d lines, total %d chars. (Content truncated in log)",
				#linesForFzf,
				#fzfInputString
			)
		)
	else
		log.d(string.format("filter: FZF input string (%d lines):\n%s", #linesForFzf, fzfInputString))
	end

	local function fzfTaskCallback(exitCode, stdOut, stdErr)
		stdOut = stdOut or "" -- Ensure stdOut/stdErr are strings
		stdErr = stdErr or ""
		log.d(string.format("fzfTaskCallback: ExitCode: %s", tostring(exitCode)))
		log.d(
			string.format(
				"fzfTaskCallback: StdOut (length %d):\n%s",
				#stdOut,
				stdOut:sub(1, 500) .. (#stdOut > 500 and "..." or "")
			)
		)
		log.d(
			string.format(
				"fzfTaskCallback: StdErr (length %d):\n%s",
				#stdErr,
				stdErr:sub(1, 500) .. (#stdErr > 500 and "..." or "")
			)
		)

		if exitCode == 0 then -- Success
			local matchedIds = {}
			if stdOut ~= "" then
				for line in stdOut:gmatch("[^\r\n]+") do
					-- Extract the part before the first delimiter, which is our ID.
					local idPart = line:match("^(.-)" .. escapedDelimiterPattern)
					if idPart then
						table.insert(matchedIds, idPart)
					else
						log.w(
							string.format(
								"fzfTaskCallback: Could not parse ID from fzf output line: '%s' using delimiter '%s'. Pattern: '^(.-)%s'",
								line,
								delimiter,
								escapedDelimiterPattern
							)
						)
					end
				end
			end
			log.d("fzfTaskCallback: Success. Matched IDs:", inspect(matchedIds))
			callback(matchedIds, nil)
		elseif exitCode == 1 or exitCode == 130 then -- 1 = No match, 130 = Aborted (e.g. SIGINT if it were interactive)
			log.d(string.format("fzfTaskCallback: No matches or aborted (exit code %d).", exitCode))
			callback({}, nil) -- Empty list for no matches or cancellation
		else -- Other error
			local errorInfo = {
				message = string.format("fzf task failed with exit code %d.", exitCode),
				exitCode = exitCode,
				stdOut = stdOut,
				stdErr = stdErr,
			}
			log.e("fzfTaskCallback: Error. Details:", inspect(errorInfo))
			callback(nil, errorInfo)
		end
	end

	local fzfTaskInstance = task.new(self.fzfPath, fzfTaskCallback, allFzfArgs)

	if not fzfTaskInstance then
		local err = "Failed to create hs.task for fzf."
		log.e("filter: " .. err)
		callback(nil, { message = err }) -- Notify callback of failure
		return nil, err
	end

	log.d("filter: Setting input for fzf task.")
	fzfTaskInstance:setInput(fzfInputString)

	log.d("filter: Starting fzf task.")
	if not fzfTaskInstance:start() then
		local err = "Failed to start fzf task."
		log.e("filter: " .. err)
		callback(nil, { message = err }) -- Notify callback of failure
		return nil, err
	end

	log.d("filter: Fzf task started. Closing input pipe.")
	fzfTaskInstance:closeInput() -- Crucial for fzf --filter mode to know input has ended.

	return fzfTaskInstance -- Return the task object to the caller
end

return M
