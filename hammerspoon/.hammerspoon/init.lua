-- Load the spoons
--
-- hs.loadSpoon("WindowSwitcher")
-- hs.loadSpoon("WindowSwitcherWebView")
-- hs.loadSpoon("ScreenManager")
--
-- -- Start the spoons with default settings
--
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

hs.loadSpoon("FzfFilter")
hs.loadSpoon("WindowSwitcherHotkeys")
hs.loadSpoon("FzfWindowSwitcher")

spoon.FzfFilter:start()

-- local mods = { "alt" }
local mods = { "alt", "ctrl", "cmd" }

local customBindings = {
	{
		modifiers = mods,
		key = ",",
		appName = "chrome",
		windowTitle = "personal",
		description = "Chrome Personal",
	},
	{
		modifiers = mods,
		key = "p",
		appName = "chrome",
		windowTitle = "private",
		description = "Chrome Private",
	},
	{
		modifiers = mods,
		key = "1",
		appName = "chrome",
		windowTitle = "(coveo)",
		description = "Chrome Work",
	},
	{
		modifiers = mods,
		key = "a",
		appName = "slack",
		windowTitle = "",
		description = "Slack",
	},
	{
		modifiers = mods,
		key = "2",
		appName = "ghostty",
		windowTitle = "",
		description = "Ghostty Terminal",
	},
	{
		modifiers = mods,
		key = "'",
		appName = "claude",
		windowTitle = "",
		description = "Claude",
	},
	{
		modifiers = mods,
		key = "3",
		appName = "intellij idea",
		windowTitle = "",
		description = "IntelliJ IDEA",
	},
	{
		modifiers = mods,
		key = "o",
		appName = "microsoft outlook",
		windowTitle = "",
		description = "Microsoft Outlook",
	},
	{
		modifiers = mods,
		key = "e",
		appName = "obsidian",
		windowTitle = "coveo-work-notes",
		description = "Obsidian coveo-work-notes",
	},
}

spoon.FzfWindowSwitcher:setExclusionFilters(customBindings)
spoon.FzfWindowSwitcher:start()

spoon.WindowSwitcherHotkeys:setHotKeyBindings(customBindings)
spoon.WindowSwitcherHotkeys:start()

-- Display a notification that the configuration is loaded
hs.alert.show("Hammerspoon configuration loaded!")
