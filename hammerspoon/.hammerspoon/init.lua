--[[
Advanced Window Manager for Hammerspoon
=======================================

This module provides comprehensive window management functionality:

1. Window Shortcut Assignment
   - Assign Alt+key shortcuts to specific windows for quick access
   - Cmd+Alt+Shift+W: Opens window selector to assign shortcuts
   - Cmd+Alt+W: Displays a list of all current window shortcuts
   - When using a window shortcut (Alt+[key]):
     * If window is not focused: Focuses the window
     * If window is already focused: Moves mouse cursor to center of window

2. Window Selection
   - Alt+Space: Opens a window selector to quickly focus any window
   - Shows application name, window title, and any shortcuts assigned
   - Supports searching by application name or window title

3. Window Movement
   - Alt+Tab: Move focused window to next screen (cycles through available screens)

Usage:
- To assign a window shortcut:
  1. Press Cmd+Alt+Shift+W to open the window selector
  2. Select a window from the list
  3. Press any character key to assign Alt+[key] as shortcut for that window
  4. Use Alt+[key] to instantly focus the window from anywhere
  5. Press Alt+[key] again when already on that window to center your mouse cursor

- To quickly select and focus any window: Press Alt+Space

- To view all shortcuts: Press Cmd+Alt+W

- To move a window between screens: Press Alt+Tab while the window is focused

Note: Window shortcuts persist while Hammerspoon is running but are not currently saved
between sessions (this could be implemented with hs.settings).
--]]

--- Module: Window Shortcut Manager
local WindowShortcuts = {}

-- Global variables for mouse highlighting
local mouseCircle = nil
local mouseCircleTimer = nil

-- Function to highlight mouse position with a circle
function mouseHighlight()
	-- Delete an existing highlight if it exists
	if mouseCircle then
		mouseCircle:delete()
		if mouseCircleTimer then
			mouseCircleTimer:stop()
		end
	end
	-- Get the current co-ordinates of the mouse pointer
	local mousepoint = hs.mouse.getAbsolutePosition()
	-- Prepare a big red circle around the mouse pointer
	mouseCircle = hs.drawing.circle(hs.geometry.rect(mousepoint.x - 40, mousepoint.y - 40, 80, 80))
	mouseCircle:setStrokeColor({ ["red"] = 1, ["blue"] = 0, ["green"] = 0, ["alpha"] = 1 })
	mouseCircle:setFill(false)
	mouseCircle:setStrokeWidth(5)
	mouseCircle:show()

	-- Set a timer to delete the circle after 1 seconds
	mouseCircleTimer = hs.timer.doAfter(1, function()
		mouseCircle:delete()
		mouseCircle = nil
		mouseCircleTimer = nil
	end)
end

-- Helper function to truncate long window titles
function truncateString(str, maxLen)
	if str and #str > maxLen then
		return string.sub(str, 1, maxLen - 3) .. "..."
	end
	return str
end

-- Maximum length for window titles
local MAX_TITLE_LENGTH = 40

-- Store window ID and shortcut key mappings
WindowShortcuts.bindings = {}
WindowShortcuts.hotkeyObjects = {}
WindowShortcuts.keyCapture = nil

-- Create window selection chooser
WindowShortcuts.windowChooser = hs.chooser.new(function(selection)
	if not selection then
		return
	end

	local win = selection.window
	if win then
		-- Focus the selected window
		win:focus()
	end
	WindowShortcuts.windowChooser:query(nil) -- clear the chooser
end)

-- Configure window selection chooser appearance
WindowShortcuts.windowChooser:placeholderText("Select window to focus")
WindowShortcuts.windowChooser:searchSubText(true)

-- Refresh the list of windows for the window selection chooser
function WindowShortcuts:refreshWindowSelectionList()
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
			local truncatedTitle = truncateString(title, MAX_TITLE_LENGTH)

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

-- Create window chooser
WindowShortcuts.chooser = hs.chooser.new(function(selection)
	if not selection then
		return
	end

	local win = selection.window
	if win then
		WindowShortcuts:promptForShortcut(win)
	end
	WindowShortcuts.chooser:query(nil) -- clear the chooser
end)

-- Configure chooser appearance
WindowShortcuts.chooser:placeholderText("Select window to assign shortcut")
WindowShortcuts.chooser:searchSubText(true)

-- List of keys to exclude from shortcuts
WindowShortcuts.excludedKeys = {
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

-- Refresh the list of windows in the chooser
function WindowShortcuts:refreshWindowList()
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
			local truncatedTitle = truncateString(title, MAX_TITLE_LENGTH)

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

-- Prompt for a shortcut key
function WindowShortcuts:promptForShortcut(window)
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
			local truncatedTitle = truncateString(window:title(), MAX_TITLE_LENGTH)
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

-- Remove existing binding for a key
function WindowShortcuts:removeBindingForKey(key)
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

-- Create a hotkey binding for a window
function WindowShortcuts:createWindowShortcut(key, windowId)
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
				mouseHighlight()
			end
		else
			hs.alert.show("Window not found! Removing shortcut Alt+" .. key)
			self:removeBindingForKey(key)
		end
	end)
end

-- List all shortcuts
function WindowShortcuts:listAllShortcuts()
	local message = "Window Shortcuts:\n\n"
	local hasShortcuts = false

	for key, windowId in pairs(self.bindings) do
		local win = hs.window.get(windowId)
		if win then
			local app = win:application()
			local appName = app and app:name() or "Unknown"
			-- Truncate the window title for the alert display
			local truncatedTitle = truncateString(win:title(), MAX_TITLE_LENGTH)
			message = message .. "Alt+" .. key .. ": " .. appName .. " - " .. truncatedTitle .. "\n"
			hasShortcuts = true
		end
	end

	if not hasShortcuts then
		message = "No window shortcuts assigned.\nUse Cmd+Alt+Shift+W to assign shortcuts."
	end

	hs.alert.show(message, 5)
end

-- Load existing shortcuts (for future implementation)
function WindowShortcuts:loadShortcuts()
	-- This would typically load from hs.settings
	-- For now, we'll just recreate the bindings from our table
	for key, windowId in pairs(self.bindings) do
		self:createWindowShortcut(key, windowId)
	end
end

-- Initialize shortcuts
function WindowShortcuts:init()
	-- Load any saved shortcuts
	self:loadShortcuts()

	-- Bind shortcut for opening window chooser
	hs.hotkey.bind({ "cmd", "alt", "shift" }, "w", function()
		self:refreshWindowList()
		self.chooser:show()
	end)

	-- Bind shortcut for listing all shortcuts
	hs.hotkey.bind({ "cmd", "alt" }, "w", function()
		self:listAllShortcuts()
	end)

	-- Bind Alt+Space for window selection
	hs.hotkey.bind({ "alt" }, "space", function()
		self:refreshWindowSelectionList()
		self.windowChooser:show()
	end)

	print("Window Shortcut Manager loaded!")
end

--- Module: Screen Management
local ScreenManager = {}

-- Move current window to next screen
function ScreenManager.moveWindowToNextScreen()
	-- Get the currently focused window
	local win = hs.window.focusedWindow()

	-- If no window is focused, do nothing
	if not win then
		return
	end

	-- Get all available screens
	local screens = hs.screen.allScreens()

	-- If there's only one screen, do nothing
	if #screens <= 1 then
		return
	end

	-- Get the current screen
	local currentScreen = win:screen()

	-- Get the next screen (screen:next() handles the cycling back to first screen)
	local nextScreen = currentScreen:next()

	-- Move the window to the next screen
	win:moveToScreen(nextScreen)

	-- Make sure the window stays focused
	win:focus()
end

-- Initialize screen management
function ScreenManager:init()
	-- Bind Alt+Tab to move window to next screen
	hs.hotkey.bind({ "alt" }, "tab", self.moveWindowToNextScreen)

	print("Screen Manager loaded!")
end

--- Main Initialization
local function init()
	WindowShortcuts:init()
	ScreenManager:init()
	print("Advanced window manager loaded! Use Cmd+Alt+Shift+W to assign shortcuts, Cmd+Alt+W to list shortcuts")
end

-- Run initialization
init()
