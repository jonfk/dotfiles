-- Load the spoons
--
-- hs.loadSpoon("FzfFilter")
-- hs.loadSpoon("WindowSwitcher")
-- hs.loadSpoon("WindowSwitcherWebView")
-- hs.loadSpoon("ScreenManager")
--
-- -- Start the spoons with default settings
--
-- spoon.FzfFilter:start()
-- spoon.WindowSwitcher:start()
-- spoon.ScreenManager:start()
--
-- spoon.WindowSwitcherWebView.windowSwitcher = spoon.WindowSwitcher
-- spoon.WindowSwitcherWebView:start()
--
-- spoon.WindowSwitcherWebView:bindHotkeys({
-- 	toggle = { { "cmd", "alt" }, "v" }, -- Cmd+Alt+V to toggle the web UI
-- })

-- You can also customize hotkeys if needed:
--[[
spoon.WindowSwitcher:bindHotkeys({
    open_window_chooser = {{"alt"}, "space"},
    assign_shortcut = {{"cmd", "alt", "shift"}, "w"},
    list_shortcuts = {{"cmd", "alt"}, "w"},
    export_shortcuts = {{"alt"}, "l"},
    import_shortcuts = {{"alt", "shift"}, "l"}
})

spoon.ScreenManager:bindHotkeys({
    next_screen = {{"alt"}, "tab"}
})
--]]

-- Configuration: Maximum number of focus attempts
local MAX_FOCUS_ATTEMPTS = 5

-- Function to focus a Window based on app name and window title matches
-- @param appName: string to match against application name (partial match)
-- @param windowTitle: string to match against window title (partial match)
-- @return: boolean indicating if a matching window was found and focused
function focusWindowBySelector(appName, windowTitle)
	-- Validate input
	if type(appName) ~= "string" or type(windowTitle) ~= "string" then
		print("Error: both appName and windowTitle must be strings")
		return false
	end
	-- Convert parameters to lowercase for case-insensitive matching
	local targetAppName = string.lower(appName)
	local targetWindowTitle = string.lower(windowTitle)
	-- Get all windows
	local allWindows = hs.window.allWindows()
	local targetWindow = nil
	-- Find the target window
	for _, window in ipairs(allWindows) do
		-- Skip if window is nil or minimized
		if window and not window:isMinimized() then
			local app = window:application()
			if app then
				local actualAppName = string.lower(app:name() or "")
				local actualWindowTitle = string.lower(window:title() or "")
				-- Check if both app name and window title contain the target strings
				if
					string.find(actualAppName, targetAppName, 1, true)
					and string.find(actualWindowTitle, targetWindowTitle, 1, true)
				then
					targetWindow = window
					break
				end
			end
		end
	end
	-- If no matching window found, return false
	if not targetWindow then
		print(string.format("No window found matching app: '%s' and title: '%s'", appName, windowTitle))
		return false
	end
	-- Try to focus the window with retry logic
	for attempt = 1, MAX_FOCUS_ATTEMPTS do
		targetWindow:focus()
		-- Small delay to allow the system to process the focus change
		hs.timer.usleep(50000) -- 50ms delay
		-- Check if the target window is now focused
		local currentFocusedWindow = hs.window.focusedWindow()
		if currentFocusedWindow and currentFocusedWindow:id() == targetWindow:id() then
			print(
				string.format(
					"Successfully focused window: %s - %s (attempt %d)",
					targetWindow:application():name(),
					targetWindow:title(),
					attempt
				)
			)
			return true
		end
		-- If not the last attempt, log the retry
		if attempt < MAX_FOCUS_ATTEMPTS then
			print(string.format("Focus attempt %d failed, retrying...", attempt))
		end
	end
	-- All attempts failed
	print(
		string.format(
			"Failed to focus window after %d attempts: %s - %s",
			MAX_FOCUS_ATTEMPTS,
			targetWindow:application():name(),
			targetWindow:title()
		)
	)
	return false
end

-- Table defining hotkeys and their corresponding window targets
local hotKeyBindings = {
	{
		modifiers = { "alt", "ctrl", "cmd" },
		key = ",",
		appName = "chrome",
		windowTitle = "personal",
		description = "Chrome Personal",
	},
	{
		modifiers = { "alt", "ctrl", "cmd" },
		key = "1",
		appName = "chrome",
		windowTitle = "coveo",
		description = "Chrome Work",
	},
	{ modifiers = { "alt", "ctrl", "cmd" }, key = "a", appName = "slack", windowTitle = "", description = "Slack" },
	{
		modifiers = { "alt", "ctrl", "cmd" },
		key = "2",
		appName = "ghostty",
		windowTitle = "",
		description = "Ghostty Terminal",
	},
}

-- Create hotkey bindings from the table
for _, binding in ipairs(hotKeyBindings) do
	hs.hotkey.bind(binding.modifiers, binding.key, function()
		print(
			string.format(
				"Hotkey pressed: %s+%s (%s)",
				table.concat(binding.modifiers, "+"),
				binding.key,
				binding.description or ""
			)
		)
		focusWindowBySelector(binding.appName, binding.windowTitle)
	end)
end

-- Optional: Print all configured hotkeys for reference
print("Configured hotkeys:")
for _, binding in ipairs(hotKeyBindings) do
	print(
		string.format(
			"  %s+%s: %s - %s (%s)",
			table.concat(binding.modifiers, "+"),
			binding.key,
			binding.appName,
			binding.windowTitle == "" and "any window" or binding.windowTitle,
			binding.description or ""
		)
	)
end

-- Display a notification that the configuration is loaded
hs.alert.show("Hammerspoon configuration loaded!")
