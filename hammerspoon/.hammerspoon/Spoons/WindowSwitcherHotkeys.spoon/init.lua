--- === WindowSwitcherHotkeys ===
---
--- A Spoon to create hotkeys for switching between specific windows based on app name and window title
---
--- Download: https://github.com/Hammerspoon/Spoons/raw/master/Spoons/WindowSwitcherHotkeys.spoon.zip

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "WindowSwitcherHotkeys"
obj.version = "1.0"
obj.author = "Your Name <your.email@example.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- WindowSwitcherHotkeys.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the messages coming from the Spoon.
obj.logger = hs.logger.new("WindowSwitcherHotkeys")

--- WindowSwitcherHotkeys.hotKeyBindings
--- Variable
--- Table defining hotkeys and their corresponding window targets
--- Default value: {} (empty table - no default keybindings)
--- Use setHotKeyBindings() to configure your custom hotkeys before calling start()
obj.hotKeyBindings = {}

--- WindowSwitcherHotkeys.maxFocusAttempts
--- Variable
--- Maximum number of focus attempts when trying to focus a window
--- Default value: 5
obj.maxFocusAttempts = 5

-- Internal variables
obj._hotkeys = {}

--- WindowSwitcherHotkeys:focusWindowBySelector(appName, windowTitle)
--- Method
--- Focus a Window based on app name and window title matches
---
--- Parameters:
---  * appName - string to match against application name (partial match)
---  * windowTitle - string to match against window title (partial match)
---
--- Returns:
---  * boolean indicating if a matching window was found and focused
function obj:focusWindowBySelector(appName, windowTitle)
	-- Validate input
	if type(appName) ~= "string" or type(windowTitle) ~= "string" then
		self.logger.e("Error: both appName and windowTitle must be strings")
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
		self.logger.i(string.format("No window found matching app: '%s' and title: '%s'", appName, windowTitle))
		return false
	end

	-- Try to focus the window with retry logic
	for attempt = 1, self.maxFocusAttempts do
		targetWindow:focus()
		-- Small delay to allow the system to process the focus change
		hs.timer.usleep(50000) -- 50ms delay

		-- Check if the target window is now focused
		local currentFocusedWindow = hs.window.focusedWindow()
		if currentFocusedWindow and currentFocusedWindow:id() == targetWindow:id() then
			self.logger.i(
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
		if attempt < self.maxFocusAttempts then
			self.logger.d(string.format("Focus attempt %d failed, retrying...", attempt))
		end
	end

	-- All attempts failed
	self.logger.w(
		string.format(
			"Failed to focus window after %d attempts: %s - %s",
			self.maxFocusAttempts,
			targetWindow:application():name(),
			targetWindow:title()
		)
	)
	return false
end

--- WindowSwitcherHotkeys:start()
--- Method
--- Start the spoon by creating hotkey bindings
---
--- Parameters:
---  * None
---
--- Returns:
---  * The WindowSwitcherHotkeys object
---
--- Notes:
---  * Hotkey bindings must be configured using setHotKeyBindings() before calling start()
---  * If no hotkey bindings are configured, a warning will be logged and no hotkeys will be created
function obj:start()
	self:stop() -- Clean up any existing hotkeys
	self.logger.setLogLevel("info")

	-- Check if hotkey bindings are configured
	if #self.hotKeyBindings == 0 then
		self.logger.w(
			"No hotkey bindings configured. Use setHotKeyBindings() to configure hotkeys before calling start()."
		)
		return self
	end

	-- Create hotkey bindings from the table
	for _, binding in ipairs(self.hotKeyBindings) do
		local hotkey = hs.hotkey.bind(binding.modifiers, binding.key, function()
			self.logger.d(
				string.format(
					"Hotkey pressed: %s+%s (%s)",
					table.concat(binding.modifiers, "+"),
					binding.key,
					binding.description or ""
				)
			)
			self:focusWindowBySelector(binding.appName, binding.windowTitle)
		end)
		table.insert(self._hotkeys, hotkey)
	end

	-- Print all configured hotkeys for reference
	self.logger.i("Configured hotkeys:")
	for _, binding in ipairs(self.hotKeyBindings) do
		self.logger.i(
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

	return self
end

--- WindowSwitcherHotkeys:stop()
--- Method
--- Stop the spoon by removing all hotkey bindings
---
--- Parameters:
---  * None
---
--- Returns:
---  * The WindowSwitcherHotkeys object
function obj:stop()
	for _, hotkey in ipairs(self._hotkeys) do
		hotkey:delete()
	end
	self._hotkeys = {}
	self.logger.i("WindowSwitcherHotkeys stopped")
	return self
end

--- WindowSwitcherHotkeys:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for WindowSwitcherHotkeys
---
--- Parameters:
---  * mapping - A table containing hotkey mapping. Not used in this spoon as hotkeys are defined in hotKeyBindings
---
--- Returns:
---  * The WindowSwitcherHotkeys object
---
--- Notes:
---  * This method is provided for Spoon API compatibility but hotkeys are configured via the hotKeyBindings variable
function obj:bindHotkeys(mapping)
	-- This spoon doesn't use the standard bindHotkeys pattern
	-- Hotkeys are configured via the hotKeyBindings variable
	self.logger.w("bindHotkeys called but this spoon uses hotKeyBindings variable for configuration")
	return self
end

--- WindowSwitcherHotkeys:setHotKeyBindings(bindings)
--- Method
--- Set the hotkey bindings configuration
---
--- Parameters:
---  * bindings - A table defining hotkeys and their corresponding window targets
---
--- Returns:
---  * The WindowSwitcherHotkeys object
---
--- Notes:
---  * Call this method before start() to customize the hotkey bindings
---  * If the spoon is already running, you need to call stop() and start() again for changes to take effect
function obj:setHotKeyBindings(bindings)
	if type(bindings) ~= "table" then
		self.logger.e("setHotKeyBindings: bindings must be a table")
		return self
	end

	self.hotKeyBindings = bindings
	self.logger.i("Hotkey bindings updated")
	return self
end

return obj
