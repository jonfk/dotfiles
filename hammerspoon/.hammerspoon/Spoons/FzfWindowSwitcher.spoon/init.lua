---
--- === FzfWindowSwitcher ===
---
--- A simple window switcher for Hammerspoon that uses fzf for filtering
---
--- This Spoon provides a window switcher interface powered by fzf for fast filtering.
--- It depends on the FzfFilter.spoon.

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "FzfWindowSwitcher"
obj.version = "1.0"
obj.author = "Jonathan Fok kan <jonathan@fokkan.ca>"
obj.homepage = "https://github.com/jonfk/fzf-hammerspoon-window-switcher"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.dependencies = {
	{
		["name"] = "FzfFilter",
		["version"] = "1.0",
	},
}

-- Configuration defaults
obj.searchWindowTitles = true -- Whether to search window titles in addition to app names
obj.maxTitleLength = 40 -- Maximum length for window titles in UI
obj.truncateTitles = true -- Whether to truncate long window titles in UI
obj.quickSwitchEnabled = true -- Whether to immediately switch to a window if there's only one match
obj.hotkey = { { "ctrl" }, "space" } -- Default hotkey to activate window switcher
obj.exclusionFilters = {} -- List of exclusion filters to hide windows that are handled by direct hotkeys

-- Module variables
obj.fzfFilter = nil
obj.currentFilterTask = nil
obj.filterSequence = 0
obj.fullWindowList = {}
obj.windowChooser = nil
obj.hotkeyBind = nil
obj.logger = hs.logger.new("FzfWindowSwitcher", "info")

--- FzfWindowSwitcher:init()
--- Method
--- Initializes the FzfWindowSwitcher spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The FzfWindowSwitcher object
function obj:init()
	self.logger.i("Initializing FzfWindowSwitcher")

	-- Create window chooser
	self.windowChooser = hs.chooser.new(function(selection)
		if not selection then
			self.logger.d("No selection made")
			return
		end

		self.windowChooser:query(nil) -- clear the chooser
		local win = hs.window.get(selection.windowId)
		if win then
			-- Focus the selected window
			self.logger.d("Focusing window: " .. selection.text .. " - " .. (selection.fullTitle or selection.subText))
			win:focus()
		else
			self.logger.w("Window not found: " .. tostring(selection.windowId))
		end
	end)

	-- Configure window selection chooser appearance
	self.windowChooser:placeholderText("Select window to focus")
	self.windowChooser:searchSubText(self.searchWindowTitles)

	self.windowChooser:hideCallback(function()
		self.windowChooser:query(nil) -- Clear the query
		self.logger.d("Window chooser hidden, query cleared")
	end)

	-- Add queryChangedCallback for fzf filtering
	self.windowChooser:queryChangedCallback(function(query)
		-- Cancel any ongoing filter task
		if self.currentFilterTask then
			self.logger.d("Cancelling previous filter task")
			self.currentFilterTask:terminate()
			self.currentFilterTask = nil
		end

		-- If query is empty, show all windows
		if not query or query == "" then
			self.logger.d("Empty query, showing all windows")
			self.windowChooser:choices(self.fullWindowList)
			return
		end

		self.logger.d("Filtering windows with query: " .. query)

		-- Increment the filter sequence
		self.filterSequence = self.filterSequence + 1
		local currentSequence = self.filterSequence

		-- Prepare input list for fzfFilter
		local inputList = {}
		for i, choice in ipairs(self.fullWindowList) do
			local searchText = choice.text
			if self.searchWindowTitles then
				-- Use the full title for searching, even if the displayed title is truncated
				searchText = searchText .. " " .. (choice.fullTitle or choice.subText)
			end

			table.insert(inputList, {
				id = tostring(i), -- Use the index as ID
				searchText = searchText, -- Text to search
			})
		end

		-- Use fzfFilter to filter the list
		self.currentFilterTask = self.fzfFilter:filter(inputList, query, function(matchedIds, errorInfo)
			self.currentFilterTask = nil

			-- Only process the result if it's from the most recent filter
			if currentSequence == self.filterSequence and matchedIds then
				-- Check if there's exactly one match and quickSwitch is enabled
				if #matchedIds == 1 and self.quickSwitchEnabled then
					local index = tonumber(matchedIds[1])
					local choice = self.fullWindowList[index]
					local win = hs.window.get(choice.windowId)

					if win then
						-- Focus the window
						self.logger.d(
							"QuickSwitch: Focusing window: "
								.. choice.text
								.. " - "
								.. (choice.fullTitle or choice.subText)
						)
						-- Clear query and close chooser
						self.windowChooser:query(nil)
						self.windowChooser:hide()

						win:focus()
						return
					end
				end

				-- Create filtered list of choices
				local filteredChoices = {}
				for _, id in ipairs(matchedIds) do
					local index = tonumber(id)
					if index and self.fullWindowList[index] then
						table.insert(filteredChoices, self.fullWindowList[index])
					end
				end

				self.logger.d("Found " .. #filteredChoices .. " matches")

				-- Update the chooser with filtered choices
				self.windowChooser:choices(filteredChoices)
			end

			-- Handle error if any
			if errorInfo then
				self.logger.e("fzfFilter error: " .. (errorInfo.message or "Unknown error"))
			end
		end)
	end)

	return self
end

--- FzfWindowSwitcher:truncateString(str, maxLen)
--- Method
--- Truncates a string to a maximum length, adding ellipsis if needed
---
--- Parameters:
---  * str - The string to truncate
---  * maxLen - The maximum length of the string
---
--- Returns:
---  * The truncated string
function obj:truncateString(str, maxLen)
	if str and #str > maxLen and self.truncateTitles then
		return string.sub(str, 1, maxLen - 3) .. "..."
	end
	return str
end

--- FzfWindowSwitcher:excludeWindows(windowList, exclusionFilters)
--- Method
--- Excludes windows from the list based on exclusion filters
--- Each filter can only exclude one window (first match)
---
--- Parameters:
---  * windowList - The list of windows to filter
---  * exclusionFilters - List of filters with appName and windowTitle fields
---
--- Returns:
---  * The filtered window list
function obj:excludeWindows(windowList, exclusionFilters)
	if not exclusionFilters or #exclusionFilters == 0 then
		return windowList
	end

	-- Create a copy of exclusion filters to track which ones have been used
	local unusedFilters = {}
	for i, filter in ipairs(exclusionFilters) do
		table.insert(unusedFilters, { index = i, filter = filter })
	end

	local filteredWindowList = {}

	for _, window in ipairs(windowList) do
		local shouldExclude = false

		-- Check against unused filters
		for i = #unusedFilters, 1, -1 do -- iterate backwards so we can remove items safely
			local filterEntry = unusedFilters[i]
			local filter = filterEntry.filter

			-- Check if window matches this filter
			local appMatches = string.find(string.lower(window.text), string.lower(filter.appName), 1, true) ~= nil
			local titleMatches = (filter.windowTitle == "")
				or (
					string.find(
						string.lower(window.fullTitle or window.subText),
						string.lower(filter.windowTitle),
						1,
						true
					) ~= nil
				)

			if appMatches and titleMatches then
				-- This window matches the filter, exclude it
				shouldExclude = true
				-- Remove this filter from unused filters so it won't be used again
				table.remove(unusedFilters, i)
				self.logger.d(
					"Excluding window: "
						.. window.text
						.. " - "
						.. (window.fullTitle or window.subText)
						.. " (matched filter: "
						.. filter.appName
						.. "/"
						.. (filter.windowTitle ~= "" and filter.windowTitle or "*")
						.. ")"
				)
				break
			end
		end

		if not shouldExclude then
			table.insert(filteredWindowList, window)
		end
	end

	return filteredWindowList
end

--- FzfWindowSwitcher:setExclusionFilters(filters)
--- Method
--- Sets the exclusion filters for the window switcher
---
--- Parameters:
---  * filters - A table of filters with the same format as hotkey bindings:
---    * Each filter should have `appName` and `windowTitle` fields
---    * `windowTitle` can be empty string to match any window title
---
--- Returns:
---  * The FzfWindowSwitcher object
function obj:setExclusionFilters(filters)
	self.exclusionFilters = filters or {}
	self.logger.d("Set " .. #self.exclusionFilters .. " exclusion filters")
	return self
end

--- FzfWindowSwitcher:getAllWindowsForChooserChoices()
--- Method
--- Gets all windows for the chooser
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of window choices for the chooser
function obj:getAllWindowsForChooserChoices()
	local windows = hs.window.allWindows()

	-- Sort windows by windowId for consistent ordering (oldest first)
	table.sort(windows, function(a, b)
		return a:id() < b:id()
	end)

	local windowList = {}

	for _, win in ipairs(windows) do
		-- Get window information
		local app = win:application()
		local appName = app and app:name() or "Unknown"
		local title = win:title()
		local winId = win:id()

		-- Skip windows without titles
		if title and title ~= "" then
			local appIcon = nil
			if app and app:bundleID() then
				appIcon = hs.image.imageFromAppBundle(app:bundleID())
			end

			-- Truncate the window title for display purposes only
			local truncatedTitle = self:truncateString(title, self.maxTitleLength)

			table.insert(windowList, {
				text = appName, -- Application name (main text)
				subText = truncatedTitle, -- Truncated window title for display
				fullTitle = title, -- Full window title for searching
				image = appIcon, -- Application icon
				windowId = winId,
			})
		end
	end

	-- Apply exclusion filters
	if #self.exclusionFilters > 0 then
		windowList = self:excludeWindows(windowList, self.exclusionFilters)
	end

	self.logger.d("Found " .. #windowList .. " windows after filtering")
	return windowList
end

--- FzfWindowSwitcher:refreshWindowList()
--- Method
--- Refreshes the list of windows for the chooser
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:refreshWindowList()
	self.logger.d("Refreshing window list")
	local windowList = self:getAllWindowsForChooserChoices()

	-- Update the chooser with the window list
	self.windowChooser:choices(windowList)
	self.fullWindowList = windowList
end

--- FzfWindowSwitcher:showWindowSwitcher()
--- Method
--- Shows the window switcher
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:showWindowSwitcher()
	self.logger.d("Showing window switcher")
	self:refreshWindowList()
	self.windowChooser:show()
end

--- FzfWindowSwitcher:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for FzfWindowSwitcher
---
--- Parameters:
---  * mapping - A table containing hotkey details for the following items:
---    * show - Show the window switcher
---
--- Returns:
---  * The FzfWindowSwitcher object
function obj:bindHotkeys(mapping)
	local spec = {
		show = hs.fnutils.partial(self.showWindowSwitcher, self),
	}

	-- Unbind existing hotkey if it exists
	if self.hotkeyBind then
		self.hotkeyBind:delete()
		self.hotkeyBind = nil
	end

	-- Use the Spoons hotkey binding utility
	hs.spoons.bindHotkeysToSpec(spec, mapping)

	return self
end

--- FzfWindowSwitcher:start()
--- Method
--- Starts the FzfWindowSwitcher spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The FzfWindowSwitcher object
function obj:start()
	self.logger.i("Starting FzfWindowSwitcher")

	-- Check if FzfFilter spoon is loaded
	if not spoon.FzfFilter then
		self.logger.e(
			"FzfFilter spoon is required but not loaded. Please load it first with: hs.loadSpoon('FzfFilter')"
		)
		return self
	end

	-- Use the FzfFilter spoon
	self.fzfFilter = spoon.FzfFilter

	-- Make sure FzfFilter is initialized
	if not self.fzfFilter.fzfPath then
		self.logger.i("FzfFilter not started yet, starting it now")
		self.fzfFilter:start()
	end

	-- Check if FzfFilter is properly initialized after start
	if not self.fzfFilter.fzfPath then
		self.logger.e("FzfFilter could not be initialized properly. Please check its configuration.")
		return self
	end

	-- Set up default hotkey if none provided through bindHotkeys
	if not self.hotkeyBind and self.hotkey then
		self.logger.d("Setting up default hotkey: " .. table.concat(self.hotkey[1], "+") .. "+" .. self.hotkey[2])
		self.hotkeyBind = hs.hotkey.bind(self.hotkey[1], self.hotkey[2], function()
			self:showWindowSwitcher()
		end)
	end

	self.logger.i(
		"FzfWindowSwitcher loaded! Use " .. table.concat(self.hotkey[1], "+") .. "+" .. self.hotkey[2] .. " to activate"
	)

	return self
end

--- FzfWindowSwitcher:stop()
--- Method
--- Stops the FzfWindowSwitcher spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The FzfWindowSwitcher object
function obj:stop()
	self.logger.i("Stopping FzfWindowSwitcher")

	-- Unbind hotkey if it exists
	if self.hotkeyBind then
		self.hotkeyBind:delete()
		self.hotkeyBind = nil
	end

	return self
end

return obj
