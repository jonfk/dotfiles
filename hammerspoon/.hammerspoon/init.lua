-- Advanced Window Switcher for Hammerspoon
-- Shows a searchable list of windows and allows assigning keyboard shortcuts

-- Table to store window ID and shortcut key mappings
windowShortcuts = {}

-- Create a new chooser object
windowChooser = hs.chooser.new(function(selection)
	if not selection then
		return
	end

	-- Don't focus the window, but prompt for a shortcut key
	local win = selection.window
	if win then
		promptForShortcut(win)
	end
end)

-- Set placeholder text and search subtext
windowChooser:placeholderText("Select window to assign shortcut")
windowChooser:searchSubText(true)

-- Function to refresh the list of windows
function refreshWindowList()
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
				-- Use pcall to safely try getting the icon
				local success, icon = pcall(function()
					return app:icon()
				end)
				if success and icon then
					appIcon = icon
				end
			end

			-- Check if this window has a shortcut assigned
			local shortcutInfo = ""
			for key, id in pairs(windowShortcuts) do
				if id == winId then
					shortcutInfo = " [Shortcut: Alt+" .. key .. "]"
					break
				end
			end

			table.insert(windowList, {
				text = appName, -- Application name (main text)
				subText = title .. " (ID: " .. winId .. ")" .. shortcutInfo, -- Window title with ID and shortcut
				image = appIcon, -- Application icon (safely retrieved)
				window = win, -- Store window reference for later use
			})
		end
	end

	-- Update the chooser with the window list
	windowChooser:choices(windowList)
end

-- Function to prompt for a shortcut key
function promptForShortcut(window)
	-- Clear existing event tap if any
	if keyCapture then
		keyCapture:stop()
		keyCapture = nil
	end

	-- Show instructions
	hs.alert.show(
		"Press a key (0-9, a-z) to assign as a shortcut for the selected window.\nPress Escape to cancel.",
		10
	)

	-- Create event tap to capture the next keypress
	keyCapture = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
		local keyCode = event:getKeyCode()
		local char = hs.keycodes.map[keyCode]

		-- Cancel on escape
		if keyCode == hs.keycodes.map["escape"] then
			hs.alert.closeAll()
			hs.alert.show("Shortcut assignment canceled")
			keyCapture:stop()
			keyCapture = nil
			return true -- Consume the event
		end

		-- Only accept alphanumeric keys
		if char and (string.match(char, "[a-z0-9]")) then
			-- Remove any existing binding for this key
			removeBindingForKey(char)

			-- Save the window ID with the pressed key
			windowShortcuts[char] = window:id()

			-- Create a new hotkey for this binding
			createWindowShortcut(char, window:id())

			-- Notify the user
			hs.alert.closeAll()
			hs.alert.show("Window '" .. window:title() .. "' assigned to Alt+" .. char)

			-- Stop the event tap
			keyCapture:stop()
			keyCapture = nil

			return true -- Consume the event
		else
			hs.alert.closeAll()
			hs.alert.show("Invalid key. Please use a letter (a-z) or number (0-9).\nPress Escape to cancel.", 5)
			return true -- Consume the event
		end
	end)

	-- Start the event tap
	keyCapture:start()
end

-- Remove existing binding for a key
function removeBindingForKey(key)
	if windowShortcuts[key] then
		-- Remove from our table
		windowShortcuts[key] = nil

		-- Delete the existing hotkey if it exists
		if hotkeyBindings and hotkeyBindings[key] then
			hotkeyBindings[key]:delete()
			hotkeyBindings[key] = nil
		end
	end
end

-- Table to store hotkey objects
hotkeyBindings = {}

-- Create a hotkey binding for a window
function createWindowShortcut(key, windowId)
	-- Delete existing binding if any
	if hotkeyBindings[key] then
		hotkeyBindings[key]:delete()
	end

	-- Create new binding
	hotkeyBindings[key] = hs.hotkey.bind({ "alt" }, key, function()
		local win = hs.window.get(windowId)
		if win then
			win:focus()
		else
			hs.alert.show("Window not found! Removing shortcut Alt+" .. key)
			removeBindingForKey(key)
		end
	end)
end

-- Load existing shortcuts from previous sessions
function loadShortcuts()
	-- This would typically load from hs.settings
	-- For now, we'll just recreate the bindings from our table
	for key, windowId in pairs(windowShortcuts) do
		createWindowShortcut(key, windowId)
	end
end

-- Initialization
function init()
	-- Load any saved shortcuts
	loadShortcuts()

	-- Create the main keyboard shortcut
	hs.hotkey.bind({ "cmd", "alt", "shift" }, "w", function()
		refreshWindowList()
		windowChooser:show()
	end)

	-- Create a shortcut to list all bindings
	hs.hotkey.bind({ "cmd", "alt" }, "w", function()
		listAllShortcuts()
	end)

	print("Advanced window switcher loaded! Press cmd+alt+shift+w to assign shortcuts, cmd+alt+w to list shortcuts")
end

-- Function to list all shortcuts
function listAllShortcuts()
	local message = "Window Shortcuts:\n\n"
	local hasShortcuts = false

	for key, windowId in pairs(windowShortcuts) do
		local win = hs.window.get(windowId)
		if win then
			local app = win:application()
			local appName = app and app:name() or "Unknown"
			message = message .. "Alt+" .. key .. ": " .. appName .. " - " .. win:title() .. "\n"
			hasShortcuts = true
		end
	end

	if not hasShortcuts then
		message = "No window shortcuts assigned.\nUse Cmd+Alt+Shift+W to assign shortcuts."
	end

	hs.alert.show(message, 5)
end

-- Run initialization
init()
