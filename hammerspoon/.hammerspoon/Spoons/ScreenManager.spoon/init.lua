--- === ScreenManager ===
---
--- A Hammerspoon spoon for managing windows across multiple screens
---
--- This spoon provides functionality to move windows between screens:
---
--- Default hotkey: Alt+Tab - Move the focused window to the next screen
---
--- Download: [https://github.com/Hammerspoon/Spoons/raw/master/Spoons/ScreenManager.spoon.zip](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/ScreenManager.spoon.zip)
---

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "ScreenManager"
obj.version = "1.0"
obj.author = "Hammerspoon Community"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

--- ScreenManager:moveWindowToNextScreen()
--- Method
--- Moves the currently focused window to the next screen
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function obj:moveWindowToNextScreen()
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

--- ScreenManager:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for ScreenManager
---
--- Parameters:
---  * mapping - A table containing hotkey objifier/key details for the various shortcuts
---
--- Returns:
---  * The ScreenManager object
---
--- Notes:
---  * The available actions are:
---    * next_screen - Move the focused window to the next screen
---
--- Example:
--- ```lua
--- spoon.ScreenManager:bindHotkeys({
---    next_screen = {{"alt"}, "tab"}
--- })
--- ```
function obj:bindHotkeys(mapping)
	local spec = {
		next_screen = hs.fnutils.partial(self.moveWindowToNextScreen, self),
	}

	hs.spoons.bindHotkeysToSpec(spec, mapping)
	return self
end

--- ScreenManager:init()
--- Method
--- Initializes the spoon
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ScreenManager object
function obj:init()
	return self
end

--- ScreenManager:start()
--- Method
--- Starts ScreenManager with default hotkeys
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ScreenManager object
function obj:start()
	-- Bind default hotkeys
	self:bindHotkeys({
		next_screen = { { "alt" }, "tab" },
	})

	return self
end

--- ScreenManager:stop()
--- Method
--- Stops ScreenManager and unbinds all hotkeys
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ScreenManager object
function obj:stop()
	-- No specific resources to clean up other than hotkeys
	-- hs.spoons.bindHotkeysToSpec will handle unbinding when given an empty table
	self:bindHotkeys({})
	return self
end

return obj
