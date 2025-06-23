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

local customBindings = {
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
		windowTitle = "(coveo)",
		description = "Chrome Work",
	},
	{
		modifiers = { "alt", "ctrl", "cmd" },
		key = "a",
		appName = "slack",
		windowTitle = "",
		description = "Slack",
	},
	{
		modifiers = { "alt", "ctrl", "cmd" },
		key = "2",
		appName = "ghostty",
		windowTitle = "",
		description = "Ghostty Terminal",
	},
	{
		modifiers = { "alt", "ctrl", "cmd" },
		key = "'",
		appName = "claude",
		windowTitle = "",
		description = "Claude",
	},
	{
		modifiers = { "alt", "ctrl", "cmd" },
		key = "3",
		appName = "intellij idea",
		windowTitle = "",
		description = "IntelliJ IDEA",
	},
}

spoon.FzfWindowSwitcher:setExclusionFilters(customBindings)
spoon.FzfWindowSwitcher:start()

spoon.WindowSwitcherHotkeys:setHotKeyBindings(customBindings)
spoon.WindowSwitcherHotkeys:start()

-- Display a notification that the configuration is loaded
hs.alert.show("Hammerspoon configuration loaded!")
