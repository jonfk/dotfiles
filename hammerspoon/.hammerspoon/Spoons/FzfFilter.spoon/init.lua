---
--- === FzfFilter ===
---
--- Filtering of lists using fzf
---
--- This Spoon provides a simple interface to use fzf for list filtering in Hammerspoon.
--- It requires the fzf binary to be installed on your system.

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "FzfFilter"
obj.version = "1.0"
obj.author = "Jonathan Fok kan <jonathan@fokkan.ca>"
obj.homepage = "https://github.com/jonfk/fzf-hammerspoon-window-switcher"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Configuration defaults
obj.fzfPath = nil -- User should set this, or it will be auto-detected in start()

-- Logger
obj.logger = hs.logger.new("FzfFilter")

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
		obj.logger.w("isFileAndExecutable: filePath is nil")
		return false, "Path is nil"
	end
	obj.logger.d(string.format("isFileAndExecutable: Checking path: '%s'", filePath))

	local attrs = hs.fs.attributes(filePath)
	if not attrs then
		obj.logger.w(string.format("isFileAndExecutable: hs.fs.attributes returned nil for '%s'", filePath))
		return false, string.format("Path '%s' not found or attributes unreadable", filePath)
	end

	obj.logger.d("isFileAndExecutable: Attributes for '" .. filePath .. "':", hs.inspect(attrs))

	if attrs.mode ~= "file" then
		obj.logger.w(string.format("isFileAndExecutable: Path '%s' is not a file (mode: %s)", filePath, attrs.mode))
		return false, string.format("Path '%s' is not a file (mode: %s)", filePath, attrs.mode)
	end

	if
		attrs.permissions:sub(3, 3) == "x"
		or attrs.permissions:sub(6, 6) == "x"
		or attrs.permissions:sub(9, 9) == "x"
	then
		obj.logger.d(string.format("isFileAndExecutable: Path '%s' is executable.", filePath))
		return true
	else
		obj.logger.w(
			string.format(
				"isFileAndExecutable: Path '%s' is not executable (permissions: %s).",
				filePath,
				attrs.permissions or "N/A"
			)
		)
		return false, string.format("Path '%s' is not executable.", filePath)
	end
end

--- FzfFilter:init()
--- Method
--- Initializes the FzfFilter spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The FzfFilter object
function obj:init()
	self.logger.i("Initializing FzfFilter")
	return self
end

--- FzfFilter:start()
--- Method
--- Starts the FzfFilter spoon and attempts to locate the fzf binary if not explicitly set
---
--- Parameters:
---  * None
---
--- Returns:
---  * The FzfFilter object
function obj:start()
	-- If fzfPath is not explicitly set, try to find it
	if not self.fzfPath then
		self.logger.d("No fzf path provided, trying defaults")

		-- Default fzf paths to try
		local defaultPaths = {
			"/opt/homebrew/bin/fzf",
			"/usr/local/bin/fzf",
			"/usr/bin/fzf",
		}

		-- Try to find a valid fzf binary
		for _, path in ipairs(defaultPaths) do
			local resolvedPath = hs.fs.pathToAbsolute(path)
			if resolvedPath then
				local isExec, _ = isFileAndExecutable(resolvedPath)
				if isExec then
					self.fzfPath = resolvedPath
					self.logger.i("Found fzf at default path: " .. resolvedPath)
					break
				end
			end
		end

		if not self.fzfPath then
			self.logger.e(
				"Could not find fzf binary path. Please install fzf or set fzfPath manually before calling start()."
			)
			return self
		end
	else
		-- Validate the user-provided path
		self.logger.d(string.format("start: Using user-provided fzfPath: '%s'", self.fzfPath))
		local resolvedPath = hs.fs.pathToAbsolute(self.fzfPath)
		if not resolvedPath then
			self.logger.e(string.format("start: Could not resolve '%s' to an absolute path.", self.fzfPath))
			return self
		end

		local isExecutable, execErr = isFileAndExecutable(resolvedPath)
		if not isExecutable then
			self.logger.e(
				string.format("start: fzf at resolved path '%s' is not suitable. Error: %s", resolvedPath, execErr)
			)
			return self
		end

		self.fzfPath = resolvedPath
	end

	self.logger.i(string.format("FzfFilter started successfully. fzf executable: %s", self.fzfPath))
	return self
end

--- FzfFilter:stop()
--- Method
--- Stops the FzfFilter spoon (this is a no-op as FzfFilter doesn't have background processes)
---
--- Parameters:
---  * None
---
--- Returns:
---  * The FzfFilter object
function obj:stop()
	return self
end

--- FzfFilter:filter(inputList, query, callback[, options])
--- Method
--- Filters a list of items using fzf non-interactively based on a query.
---
--- Parameters:
---  * inputList - A table of items to filter. Each item MUST be a table of the shape
---    `{ id = "string", searchText = "string for fzf to search" }`.
---  * query - A string containing the search query to pass to fzf
---  * callback - A function to be called when fzf completes with arguments: (matchedIds, errorInfo)
---  * options - (optional) A table containing additional options:
---    * fzfArgs - (optional) A table of additional arguments to pass to fzf
---    * delimiter - (optional) A string delimiter for separating id and searchText
---
--- Returns:
---  * An hs.task object if successful, or nil if an error occurred
---  * An error message if there was an immediate problem
function obj:filter(inputList, query, callback, options)
	if not self.fzfPath then
		self.logger.e("filter: fzfPath not initialized in this instance. Make sure to call start() first.")
		return nil, "FzfFilter instance not properly initialized (fzf path missing). Call start() first."
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
		self.logger.e("filter: " .. validationError)
		if type(callback) == "function" then
			callback(nil, { message = validationError })
		end
		return nil, validationError
	end

	options = options or {}
	if type(options) ~= "table" then
		validationError = "options, if provided, must be a table."
		self.logger.e("filter: " .. validationError)
		if type(callback) == "function" then
			callback(nil, { message = validationError })
		end
		return nil, validationError
	end

	local userFzfArgs = options.fzfArgs or {}
	if type(userFzfArgs) ~= "table" then
		validationError = "options.fzfArgs, if provided, must be a table of strings."
		self.logger.e("filter: " .. validationError)
		if type(callback) == "function" then
			callback(nil, { message = validationError })
		end
		return nil, validationError
	end

	local delimiter = options.delimiter or "\t"
	if type(delimiter) ~= "string" or #delimiter == 0 then
		validationError = "options.delimiter must be a non-empty string."
		self.logger.e("filter: " .. validationError)
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
			self.logger.e("filter: " .. validationError)
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
			self.logger.e("filter: " .. validationError)
			if type(callback) == "function" then
				callback(nil, { message = validationError })
			end
			return nil, validationError
		end
		table.insert(linesForFzf, item.id .. delimiter .. item.searchText)
	end

	-- If input list is empty, no need to run fzf.
	if #linesForFzf == 0 then
		self.logger.d("filter: Input list is empty. Calling callback with no matches immediately.")
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

	self.logger.d(
		string.format("filter: Running fzf with command: '%s' %s", self.fzfPath, table.concat(allFzfArgs, " "))
	)
	if #fzfInputString > 1000 then -- Avoid logging excessively large inputs
		self.logger.d(
			string.format(
				"filter: FZF input string has %d lines, total %d chars. (Content truncated in log)",
				#linesForFzf,
				#fzfInputString
			)
		)
	else
		self.logger.d(string.format("filter: FZF input string (%d lines):\n%s", #linesForFzf, fzfInputString))
	end

	local function fzfTaskCallback(exitCode, stdOut, stdErr)
		stdOut = stdOut or "" -- Ensure stdOut/stdErr are strings
		stdErr = stdErr or ""
		self.logger.d(string.format("fzfTaskCallback: ExitCode: %s", tostring(exitCode)))
		self.logger.d(
			string.format(
				"fzfTaskCallback: StdOut (length %d):\n%s",
				#stdOut,
				stdOut:sub(1, 500) .. (#stdOut > 500 and "..." or "")
			)
		)
		self.logger.d(
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
						self.logger.w(
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
			self.logger.d("fzfTaskCallback: Success. Matched IDs:", hs.inspect(matchedIds))
			callback(matchedIds, nil)
		elseif exitCode == 1 or exitCode == 130 then -- 1 = No match, 130 = Aborted (e.g. SIGINT if it were interactive)
			self.logger.d(string.format("fzfTaskCallback: No matches or aborted (exit code %d).", exitCode))
			callback({}, nil) -- Empty list for no matches or cancellation
		else -- Other error
			local errorInfo = {
				message = string.format("fzf task failed with exit code %d.", exitCode),
				exitCode = exitCode,
				stdOut = stdOut,
				stdErr = stdErr,
			}
			self.logger.e("fzfTaskCallback: Error. Details:", hs.inspect(errorInfo))
			callback(nil, errorInfo)
		end
	end

	local fzfTaskInstance = hs.task.new(self.fzfPath, fzfTaskCallback, allFzfArgs)

	if not fzfTaskInstance then
		local err = "Failed to create hs.task for fzf."
		self.logger.e("filter: " .. err)
		callback(nil, { message = err }) -- Notify callback of failure
		return nil, err
	end

	self.logger.d("filter: Setting input for fzf task.")
	fzfTaskInstance:setInput(fzfInputString)

	self.logger.d("filter: Starting fzf task.")
	if not fzfTaskInstance:start() then
		local err = "Failed to start fzf task."
		self.logger.e("filter: " .. err)
		callback(nil, { message = err }) -- Notify callback of failure
		return nil, err
	end

	self.logger.d("filter: Fzf task started. Closing input pipe.")
	fzfTaskInstance:closeInput() -- Crucial for fzf --filter mode to know input has ended.

	return fzfTaskInstance -- Return the task object to the caller
end

return obj
