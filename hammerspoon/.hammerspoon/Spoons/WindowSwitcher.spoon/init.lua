--- === WindowSwitcher ===
---
--- Advanced window switcher for Hammerspoon
---
--- This spoon provides comprehensive window management functionality:
---
--- 1. Window Shortcut Assignment
---    - Assign Alt+key shortcuts to specific windows for quick access
---    - Default hotkeys:
---      * Cmd+Alt+Shift+W: Opens window selector to assign shortcuts
---      * Cmd+Alt+W: Displays a list of all current window shortcuts
---      * Alt+[key]: Activates window shortcut
---    - When using a window shortcut (Alt+[key]):
---      * If window is not focused: Focuses the window
---      * If window is already focused: Moves mouse cursor to center of window
---
--- 2. Window Selection
---    - Default hotkey: Alt+Space: Opens a window selector to quickly focus any window
---    - Shows application name, window title, and any shortcuts assigned
---    - Supports searching by application name or window title
---

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "WindowSwitcher"
obj.version = "1.0"
obj.author = "Hammerspoon Community"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Global variables for mouse highlighting
obj.mouseCircle = nil
obj.mouseCircleTimer = nil

-- Store window ID and shortcut key mappings
obj.bindings = {}
obj.hotkeyObjects = {}
obj.keyCapture = nil

-- Store window shortname
obj.shortnameToWinID = {}

-- Configure window selection chooser appearance
obj.windowChooser = nil
obj.chooser = nil

-- Maximum length for window titles
local MAX_TITLE_LENGTH = 40

-- List of keys to exclude from shortcuts
obj.excludedKeys = {
	-- Function keys
	"f1",
	"f2",
	"f3",
	"f4",
	"f5",
	"f6",
	"f7",
	"f8",
	"f9",
	"f10",
	"f11",
	"f12",
	"f13",
	"f14",
	"f15",
	"f16",
	"f17",
	"f18",
	"f19",
	"f20",
	-- Navigation keys
	"escape",
	"delete",
	"help",
	"home",
	"pageup",
	"forwarddelete",
	"end",
	"pagedown",
	"return",
	"tab",
	"left",
	"right",
	"down",
	"up",
	-- Modifier keys
	"shift",
	"rightshift",
	"cmd",
	"rightcmd",
	"alt",
	"rightalt",
	"ctrl",
	"rightctrl",
	"capslock",
	"fn",
	-- Media keys
	"volumeup",
	"volumedown",
	"mute",
	"play",
	"previous",
	"next",
	-- Other special keys
	"space",
	"eject",
	"power",
	"brightnessup",
	"brightnessdown",
}

-- Function to highlight mouse position with a circle
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

-- Helper function to truncate long window titles
function obj:truncateString(str, maxLen)
	if str and #str > maxLen then
		return string.sub(str, 1, maxLen - 3) .. "..."
	end
	return str
end

--- WindowSwitcher:refreshWindowSelectionList()
--- Method
--- Refreshes the list of windows for the window selection chooser
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:refreshWindowSelectionList()
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
					shortcutInfo = " [Alt+" .. key .. "]"
					break
				end
			end

			-- Truncate the window title to avoid overly wide UI
			local truncatedTitle = self:truncateString(title, MAX_TITLE_LENGTH)

			table.insert(windowList, {
				text = appName, -- Application name (main text)
				subText = truncatedTitle .. shortcutInfo, -- Window title with shortcut info
				image = appIcon, -- Application icon (safely retrieved)
				window = win, -- Store window reference for later use
			})
		end
	end

	-- Update the chooser with the window list
	self.windowChooser:choices(windowList)
end

--- WindowSwitcher:refreshWindowList()
--- Method
--- Refreshes the list of windows in the chooser for shortcut assignment
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
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

--- WindowSwitcher:promptForShortcut(window)
--- Method
--- Prompts for a shortcut key assignment for the given window
---
--- Parameters:
---  * window - A window object to assign a shortcut to
---
--- Returns:
---  * None
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

--- WindowSwitcher:removeBindingForKey(key)
--- Method
--- Removes an existing binding for a key
---
--- Parameters:
---  * key - The key to remove binding for
---
--- Returns:
---  * None
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

--- WindowSwitcher:createWindowShortcut(key, windowId)
--- Method
--- Creates a hotkey binding for a window
---
--- Parameters:
---  * key - The key to bind
---  * windowId - The window ID to associate with this key
---
--- Returns:
---  * None
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

--- WindowSwitcher:listAllShortcuts()
--- Method
--- Lists all current shortcuts in an alert
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
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

--- WindowSwitcher:loadShortcuts()
--- Method
--- Loads existing shortcuts
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:loadShortcuts()
	-- This would typically load from hs.settings
	-- For now, we'll just recreate the bindings from our table
	for key, windowId in pairs(self.bindings) do
		self:createWindowShortcut(key, windowId)
	end
end

--- WindowSwitcher:exportShortcuts()
--- Method
--- Exports window shortcuts to a JSON file
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:exportShortcuts()
	local exportData = {
		description = "Hammerspoon window shortcuts configuration. Edit 'hotkey' values and import with Alt+Shift+L.",
		windows = {},
	}

	-- Create a reverse mapping of window IDs to keys for easy lookup
	local windowToKey = {}
	for key, windowId in pairs(self.bindings) do
		windowToKey[windowId] = key
	end
	local windowToShortname = {}
	for shortname, windowId in pairs(self.shortnameToWinID) do
		windowToShortname[windowId] = shortname
	end

	-- Get all windows and add them to the export
	local windows = hs.window.allWindows()
	for _, win in ipairs(windows) do
		-- Skip windows without titles
		if win:title() and win:title() ~= "" then
			local app = win:application()
			local appName = app and app:name() or "Unknown"

			-- Create window entry
			table.insert(exportData.windows, {
				windowId = win:id(),
				appName = appName,
				windowTitle = win:title(),
				hotkey = windowToKey[win:id()] or nil, -- Use nil for JSON null
				shortname = windowToShortname[win:id()],
			})
		end
	end

	-- Convert to JSON
	local jsonData = hs.json.encode(exportData, true)

	-- Write to file
	local filePath = os.getenv("HOME") .. "/.hammerspoon/windowshortcuts_state.json"
	local file = io.open(filePath, "w")
	if file then
		file:write(jsonData)
		file:close()
		hs.alert.show("All window information exported to " .. filePath)
	else
		hs.alert.show("Failed to write window information to file!")
	end
end

--- WindowSwitcher:importShortcuts()
--- Method
--- Imports window shortcuts from a JSON file
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:importShortcuts()
	local filePath = os.getenv("HOME") .. "/.hammerspoon/windowshortcuts_state.json"
	local file = io.open(filePath, "r")

	if file then
		local jsonData = file:read("*all")
		file:close()

		local success, importData = pcall(function()
			return hs.json.decode(jsonData)
		end)

		if success and importData and importData.windows then
			-- Clear all existing bindings
			for key, _ in pairs(self.bindings) do
				self:removeBindingForKey(key)
			end
			self.shortnameToWinID = {}

			-- Import new bindings
			local importCount = 0
			for _, windowInfo in ipairs(importData.windows) do
				if
					(windowInfo.hotkey and windowInfo.hotkey ~= "")
					or (windowInfo.shortname and windowInfo.shortname ~= "")
				then
					local win = hs.window.get(windowInfo.windowId)
					if win then
						if windowInfo.hotkey and windowInfo.hotkey ~= "" then
							-- Add the binding
							self.bindings[windowInfo.hotkey] = windowInfo.windowId
							self:createWindowShortcut(windowInfo.hotkey, windowInfo.windowId)
						end
						if windowInfo.shortname and windowInfo.shortname ~= "" then
							self.shortnameToWinID[windowInfo.shortname] = windowInfo.windowId
						end
						importCount = importCount + 1
					end
				end
			end

			hs.alert.show("Imported " .. importCount .. " window shortcuts")
		else
			hs.alert.show("Failed to parse shortcuts file!")
		end
	else
		hs.alert.show("Shortcuts file not found!")
	end
end

--- WindowSwitcher:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for WindowSwitcher
---
--- Parameters:
---  * mapping - A table containing hotkey objifier/key details for the various shortcuts
---
--- Returns:
---  * The WindowSwitcher object
---
--- Notes:
---  * The available actions are:
---    * open_window_chooser - Display the window selection chooser
---    * assign_shortcut - Display the shortcut assignment chooser
---    * list_shortcuts - Display a list of all shortcuts
---    * export_shortcuts - Export shortcuts to a file
---    * import_shortcuts - Import shortcuts from a file
---
--- Example:
--- ```lua
--- spoon.WindowSwitcher:bindHotkeys({
---    open_window_chooser = {{"alt"}, "space"},
---    assign_shortcut = {{"cmd", "alt", "shift"}, "w"},
---    list_shortcuts = {{"cmd", "alt"}, "w"},
---    export_shortcuts = {{"alt"}, "l"},
---    import_shortcuts = {{"alt", "shift"}, "l"}
--- })
--- ```
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
		export_shortcuts = hs.fnutils.partial(function()
			self:exportShortcuts()
		end),
		import_shortcuts = hs.fnutils.partial(function()
			self:importShortcuts()
		end),
	}

	hs.spoons.bindHotkeysToSpec(spec, mapping)
	return self
end

--- WindowSwitcher:init()
--- Method
--- Initializes the spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The WindowSwitcher object
function obj:init()
	-- Create window selection chooser
	self.windowChooser = hs.chooser.new(function(selection)
		if not selection then
			return
		end

		local win = selection.window
		if win then
			-- Focus the selected window
			win:focus()
		end
		self.windowChooser:query(nil) -- clear the chooser
	end)

	-- Configure window selection chooser appearance
	self.windowChooser:placeholderText("Select window to focus")
	self.windowChooser:searchSubText(true)

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
		end
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

--- WindowSwitcher:start()
--- Method
--- Starts WindowSwitcher with default hotkeys
---
--- Parameters:
---  * None
---
--- Returns:
---  * The WindowSwitcher object
function obj:start()
	-- Bind default hotkeys
	self:bindHotkeys({
		open_window_chooser = { { "alt" }, "space" },
		assign_shortcut = { { "cmd", "alt", "shift" }, "w" },
		list_shortcuts = { { "cmd", "alt" }, "w" },
		export_shortcuts = { { "alt" }, "l" },
		import_shortcuts = { { "alt", "shift" }, "l" },
	})

	return self
end

--- WindowSwitcher:stop()
--- Method
--- Stops WindowSwitcher and unbinds all hotkeys
---
--- Parameters:
---  * None
---
--- Returns:
---  * The WindowSwitcher object
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
