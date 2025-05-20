--- WindowSwitcher - Advanced window switcher for Hammerspoon
-- @module WindowSwitcher
-- @author Jonathan Fok kan
-- @copyright MIT - https://opensource.org/licenses/MIT
-- @release 1.0
-- @description
-- This spoon provides comprehensive window management functionality:
--
-- 1. Window Shortcut Assignment
--    - Assign Alt+key shortcuts to specific windows for quick access
--    - Default hotkeys:
--      * Cmd+Alt+Shift+W: Opens window selector to assign shortcuts
--      * Cmd+Alt+W: Displays a list of all current window shortcuts
--      * Alt+[key]: Activates window shortcut
--    - When using a window shortcut (Alt+[key]):
--      * If window is not focused: Focuses the window
--      * If window is already focused: Moves mouse cursor to center of window
--
-- 2. Window Selection
--    - Default hotkey: Alt+Space: Opens a window selector to quickly focus any window
--    - Shows application name, window title, and any shortcuts assigned
--    - Supports searching by application name or window title

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "WindowSwitcher"
obj.version = "1.0"
obj.author = "Jonathan Fok kan"
obj.homepage = "https://github.com/jonfk/dotfiles"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.dependencies = {
	{
		["name"] = "FzfFilter",
		["version"] = "1.0",
	},
}

-- Configuration defaults
obj.maxTitleLength = 40 -- Maximum length for window titles in UI
obj.searchWindowTitles = false -- Whether to search window titles in addition to app names
obj.maxTitleLength = 40 -- Maximum length for window titles in UI
obj.truncateTitles = true -- Whether to truncate long window titles in UI
obj.quickSwitchEnabled = true -- Whether to immediately switch to a window if there's only one match

-- Global variables for mouse highlighting
obj.mouseCircle = nil
obj.mouseCircleTimer = nil

-- Store window ID and shortcut key mappings
obj.bindings = {}
obj.hotkeyObjects = {}
obj.keyCapture = nil

-- Store window shortname
obj.shortnameToWinID = {}

-- obj.windowChooser filter variables
obj.fzfFilter = nil
obj.currentFilterTask = nil
obj.filterSequence = 0
obj.fullWindowList = {}

-- Configure window selection chooser appearance
obj.windowChooser = nil
obj.chooser = nil

obj.logger = hs.logger.new("WindowSwitcher", "info")

-- Maximum length for window titles
local MAX_TITLE_LENGTH = 40

-- stylua: ignore start
-- List of keys to exclude from shortcuts
obj.excludedKeys = {
	-- Function keys
	"f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12",
	"f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20",
	-- Navigation keys
	"escape", "delete", "help", "home", "pageup", "forwarddelete", "end",
	"pagedown", "return", "tab", "left", "right", "down", "up",
	-- Modifier keys
	"shift", "rightshift", "cmd", "rightcmd", "alt", "rightalt", "ctrl",
	"rightctrl", "capslock", "fn",
	-- Media keys
	"volumeup", "volumedown", "mute", "play", "previous", "next",
	-- Other special keys
	"space", "eject", "power", "brightnessup", "brightnessdown",
}
-- stylua: ignore end

--- Highlight mouse position with a circle
-- Creates a visual highlight around the current mouse position
-- @function mouseHighlight
function obj:mouseHighlight()
	-- Delete an existing highlight if it exists
	if self.mouseCircle then
		self.mouseCircle:delete()
		if self.mouseCircleTimer then
			self.mouseCircleTimer:stop()
		end
	end
	-- Get the current co-ordinates of the mouse pointer
	local mousepoint = hs.mouse.getAbsolutePosition()
	-- Prepare a big red circle around the mouse pointer
	self.mouseCircle = hs.drawing.circle(hs.geometry.rect(mousepoint.x - 40, mousepoint.y - 40, 80, 80))
	self.mouseCircle:setStrokeColor({ ["red"] = 1, ["blue"] = 0, ["green"] = 0, ["alpha"] = 1 })
	self.mouseCircle:setFill(false)
	self.mouseCircle:setStrokeWidth(5)
	self.mouseCircle:show()

	-- Set a timer to delete the circle after 1 seconds
	self.mouseCircleTimer = hs.timer.doAfter(1, function()
		self.mouseCircle:delete()
		self.mouseCircle = nil
		self.mouseCircleTimer = nil
	end)
end

--- Truncate long strings to a maximum length
-- @param str The string to truncate
-- @param maxLen Maximum length of the string
-- @return The truncated string with ellipsis if needed
function obj:truncateString(str, maxLen)
	if str and #str > maxLen then
		return string.sub(str, 1, maxLen - 3) .. "..."
	end
	return str
end

--- Gets comprehensive information about all active windows in the system
-- This function serves as the main abstraction for retrieving window data throughout the spoon.
-- It collects and formats all active windows with their essential properties.
-- Windows without titles are skipped, and titles are truncated according to maxTitleLength.
-- @return Array of tables with window information, each containing:
--   - text: Application name that owns the window (displayed as main text)
--   - subText: Truncated window title displayed as secondary text
--   - fullTitle: Complete window title without truncation (used for searching)
--   - image: Application icon from the application's bundle ID (can be nil)
--   - windowId: Unique identifier for the window (used to focus when selected)
-- @usage local windows = obj:getAllWindowsInfo()
function obj:getAllWindowsInfo()
	local windows = hs.window.allWindows()
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

	return windowList
end

--- Gets all windows with their associated keybindings and short names
-- This function extends getAllWindowsInfo by adding keybinding and shortname arrays to each window.
-- @return Array of tables with window information, each containing:
--   - text: Application name that owns the window
--   - subText: Truncated window title displayed as secondary text
--   - fullTitle: Complete window title without truncation
--   - image: Application icon from the application's bundle ID
--   - windowId: Unique identifier for the window
--   - keybindings: Array of keys bound to this window
--   - shortnames: Array of short names associated with this window
-- @usage local windowsWithBindings = obj:getAllWindowsWithBindings()
-- @see getAllWindowsInfo
-- @note A window can have multiple keybindings and/or multiple short names
-- @note Windows without keybindings or short names will have empty arrays
-- @note This function combines data from obj.bindings and obj.shortnameToWinID
function obj:getAllWindowsWithBindings()
	-- Get all windows information using the existing function
	local windowList = self:getAllWindowsInfo()

	-- Create a map of window IDs to their indices in the windowList for quick lookup
	local windowIdToIndex = {}
	for i, window in ipairs(windowList) do
		windowIdToIndex[window.windowId] = i

		-- Initialize arrays for keybindings and short names
		window.keybindings = {}
		window.shortnames = {}
	end

	-- Add keybindings information
	for key, winId in pairs(self.bindings) do
		local index = windowIdToIndex[winId]
		if index then
			table.insert(windowList[index].keybindings, key)
		end
	end

	-- Add short names information
	for shortname, winId in pairs(self.shortnameToWinID) do
		local index = windowIdToIndex[winId]
		if index then
			table.insert(windowList[index].shortnames, shortname)
		end
	end

	return windowList
end

--- Refreshes the list of windows for the window selection chooser
-- @return nil
function obj:refreshWindowSelectionList()
	local windowList = self:getAllWindowsInfo()

	self.fullWindowList = windowList
	self.windowChooser:choices(windowList)
end

--- Refreshes the list of windows in the chooser for shortcut assignment
-- @return nil
function obj:refreshWindowList()
	local windows = hs.window.allWindows()
	local windowList = {}

	for _, win in ipairs(windows) do
		-- Get window information
		local app = win:application()
		local appName = app and app:name() or "Unknown"
		local title = win:title()
		local winId = win:id()

		-- Skip windows without titles
		if title and title ~= "" then
			-- Safely get the application icon with error handling
			local appIcon = nil
			if app then
				local success, icon = pcall(function()
					return app:icon()
				end)
				if success and icon then
					appIcon = icon
				end
			end

			-- Check if this window has a shortcut assigned
			local shortcutInfo = ""
			for key, id in pairs(self.bindings) do
				if id == winId then
					shortcutInfo = " [Shortcut: Alt+" .. key .. "]"
					break
				end
			end

			-- Truncate the window title to avoid overly wide UI
			local truncatedTitle = self:truncateString(title, MAX_TITLE_LENGTH)

			table.insert(windowList, {
				text = appName, -- Application name (main text)
				subText = truncatedTitle .. " (ID: " .. winId .. ")" .. shortcutInfo, -- Window title with ID and shortcut
				image = appIcon, -- Application icon (safely retrieved)
				window = win, -- Store window reference for later use
			})
		end
	end

	-- Update the chooser with the window list
	self.chooser:choices(windowList)
end

--- Prompts for a shortcut key assignment for the given window
-- @param window A window object to assign a shortcut to
-- @return nil
function obj:promptForShortcut(window)
	-- Clear existing event tap if any
	if self.keyCapture then
		self.keyCapture:stop()
		self.keyCapture = nil
	end

	-- Show instructions
	hs.alert.show(
		"Press any key (letters, numbers, or special characters) to assign as a shortcut for the selected window.\n"
			.. "Press Escape to cancel.",
		10
	)

	-- Create event tap to capture the next keypress
	self.keyCapture = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
		local keyCode = event:getKeyCode()
		local char = hs.keycodes.map[keyCode]

		-- Cancel on escape
		if keyCode == hs.keycodes.map["escape"] then
			hs.alert.closeAll()
			hs.alert.show("Shortcut assignment canceled")
			self.keyCapture:stop()
			self.keyCapture = nil
			return true -- Consume the event
		end

		-- Check if the key is in our excluded list
		local isExcluded = false
		for _, excludedKey in ipairs(self.excludedKeys) do
			if char == excludedKey then
				isExcluded = true
				break
			end
		end

		-- Accept any key that's not in our excluded list
		if char and not isExcluded then
			-- Remove any existing binding for this key
			self:removeBindingForKey(char)

			-- Save the window ID with the pressed key
			self.bindings[char] = window:id()

			-- Create a new hotkey for this binding
			self:createWindowShortcut(char, window:id())

			-- Truncate the window title and notify the user
			local truncatedTitle = self:truncateString(window:title(), MAX_TITLE_LENGTH)
			hs.alert.closeAll()
			hs.alert.show("Window '" .. truncatedTitle .. "' assigned to Alt+" .. char)

			-- Stop the event tap
			self.keyCapture:stop()
			self.keyCapture = nil

			return true -- Consume the event
		else
			hs.alert.closeAll()
			hs.alert.show("Invalid key. This key cannot be used as a shortcut.\nPress Escape to cancel.", 5)
			return true -- Consume the event
		end
	end)

	-- Start the event tap
	self.keyCapture:start()
end

--- Removes an existing binding for a key
-- @param key The key to remove binding for
-- @return nil
function obj:removeBindingForKey(key)
	if self.bindings[key] then
		-- Remove from our table
		self.bindings[key] = nil

		-- Delete the existing hotkey if it exists
		if self.hotkeyObjects[key] then
			self.hotkeyObjects[key]:delete()
			self.hotkeyObjects[key] = nil
		end
	end
end

--- Creates a hotkey binding for a window
-- @param key The key to bind
-- @param windowId The window ID to associate with this key
-- @return nil
function obj:createWindowShortcut(key, windowId)
	-- Delete existing binding if any
	if self.hotkeyObjects[key] then
		self.hotkeyObjects[key]:delete()
	end

	-- Create new binding
	self.hotkeyObjects[key] = hs.hotkey.bind({ "alt" }, key, function()
		local win = hs.window.get(windowId)
		if win then
			local currentFocused = hs.window.focusedWindow()
			local isAlreadyFocused = currentFocused and (currentFocused:id() == windowId)

			-- Always focus the window
			win:focus()

			-- If window was already focused, move mouse to center of window
			if isAlreadyFocused then
				local frame = win:frame()
				local centerX = frame.x + frame.w / 2
				local centerY = frame.y + frame.h / 2
				hs.mouse.absolutePosition({ x = centerX, y = centerY })

				-- Highlight the mouse position with a circle
				self:mouseHighlight()
			end
		else
			hs.alert.show("Window not found! Removing shortcut Alt+" .. key)
			self:removeBindingForKey(key)
		end
	end)
end

--- Lists all current shortcuts in an alert
-- @return nil
function obj:listAllShortcuts()
	local message = "Window Shortcuts:\n\n"
	local hasShortcuts = false

	for key, windowId in pairs(self.bindings) do
		local win = hs.window.get(windowId)
		if win then
			local app = win:application()
			local appName = app and app:name() or "Unknown"
			-- Truncate the window title for the alert display
			local truncatedTitle = self:truncateString(win:title(), MAX_TITLE_LENGTH)
			message = message .. "Alt+" .. key .. ": " .. appName .. " - " .. truncatedTitle .. "\n"
			hasShortcuts = true
		end
	end

	if not hasShortcuts then
		message = "No window shortcuts assigned.\nUse Cmd+Alt+Shift+W to assign shortcuts."
	end

	hs.alert.show(message, 5)
end

--- Loads existing shortcuts
-- @return nil
function obj:loadShortcuts()
	-- This would typically load from hs.settings
	-- For now, we'll just recreate the bindings from our table
	for key, windowId in pairs(self.bindings) do
		self:createWindowShortcut(key, windowId)
	end
end

--- Binds hotkeys for WindowSwitcher
-- @param mapping A table containing hotkey modifier/key details for the various shortcuts
-- @return The WindowSwitcher object
-- @usage
-- ```lua
-- spoon.WindowSwitcher:bindHotkeys({
--    open_window_chooser = {{"alt"}, "space"},
--    assign_shortcut = {{"cmd", "alt", "shift"}, "w"},
--    list_shortcuts = {{"cmd", "alt"}, "w"},
-- })
-- ```
-- @note The available actions are:
--   * open_window_chooser - Display the window selection chooser
--   * assign_shortcut - Display the shortcut assignment chooser
--   * list_shortcuts - Display a list of all shortcuts
function obj:bindHotkeys(mapping)
	local spec = {
		open_window_chooser = hs.fnutils.partial(function()
			self:refreshWindowSelectionList()
			self.windowChooser:show()
		end),
		assign_shortcut = hs.fnutils.partial(function()
			self:refreshWindowList()
			self.chooser:show()
		end),
		list_shortcuts = hs.fnutils.partial(function()
			self:listAllShortcuts()
		end),
	}

	hs.spoons.bindHotkeysToSpec(spec, mapping)
	return self
end

--- Initializes the spoon
-- @return The WindowSwitcher object
function obj:init()
	-- Create window selection chooser
	self.windowChooser = hs.chooser.new(function(selection)
		if not selection then
			return
		end

		self.windowChooser:query(nil) -- clear the chooser
		local win = hs.window.get(selection.windowId)
		if win then
			-- Focus the selected window
			win:focus()
		end
	end)

	-- Configure window selection chooser appearance
	self.windowChooser:placeholderText("Select window to focus")
	self.windowChooser:searchSubText(true)
	self.windowChooser:hideCallback(function()
		self.windowChooser:query(nil) --clear the chooser query
	end)

	-- Add queryChangedCallback for shortname matching
	-- If the query matches the shortname assigned to a window, it focuses the window
	self.windowChooser:queryChangedCallback(function(query)
		-- If query matches a shortname, immediately focus the window
		if query and self.shortnameToWinID[query] then
			local winId = self.shortnameToWinID[query]
			local win = hs.window.get(winId)

			if win then
				-- Clear query and close chooser
				self.windowChooser:query(nil)
				self.windowChooser:hide()

				-- Focus the window
				win:focus()
			end
			return
		end

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

				-- Update the chooser with filtered choices
				self.windowChooser:choices(filteredChoices)
			end

			-- Handle error if any
			if errorInfo then
				self.logger.e("fzfFilter error: " .. (errorInfo.message or "Unknown error"))
			end
		end)
	end)

	-- Create window chooser for shortcut assignment
	self.chooser = hs.chooser.new(function(selection)
		if not selection then
			return
		end

		local win = selection.window
		if win then
			self:promptForShortcut(win)
		end
		self.chooser:query(nil) -- clear the chooser
	end)

	-- Configure chooser appearance
	self.chooser:placeholderText("Select window to assign shortcut")
	self.chooser:searchSubText(true)

	-- Load any saved shortcuts
	self:loadShortcuts()

	return self
end

--- Starts WindowSwitcher with default hotkeys
-- @return The WindowSwitcher object
function obj:start()
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

	-- Bind default hotkeys
	self:bindHotkeys({
		open_window_chooser = { { "alt" }, "space" },
		assign_shortcut = { { "cmd", "alt", "shift" }, "w" },
		list_shortcuts = { { "cmd", "alt" }, "w" },
	})

	return self
end

--- Stops WindowSwitcher and unbinds all hotkeys
-- @return The WindowSwitcher object
function obj:stop()
	-- Clean up any event taps
	if self.keyCapture then
		self.keyCapture:stop()
		self.keyCapture = nil
	end

	-- Clean up any mouse highlighting
	if self.mouseCircle then
		self.mouseCircle:delete()
		self.mouseCircle = nil
	end
	if self.mouseCircleTimer then
		self.mouseCircleTimer:stop()
		self.mouseCircleTimer = nil
	end

	-- Remove all hotkey bindings
	for key, hotkeyObj in pairs(self.hotkeyObjects) do
		if hotkeyObj then
			hotkeyObj:delete()
		end
	end
	self.hotkeyObjects = {}

	return self
end

return obj
