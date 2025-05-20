-- Load the spoons

hs.loadSpoon("FzfFilter")
hs.loadSpoon("WindowSwitcher")
hs.loadSpoon("WindowSwitcherWebView")
hs.loadSpoon("ScreenManager")

-- Start the spoons with default settings

spoon.FzfFilter:start()
spoon.WindowSwitcher:start()
spoon.ScreenManager:start()

spoon.WindowSwitcherWebView.windowSwitcher = spoon.WindowSwitcher
spoon.WindowSwitcherWebView:start()

spoon.WindowSwitcherWebView:bindHotkeys({
	toggle = { { "cmd", "alt" }, "v" }, -- Cmd+Alt+V to toggle the web UI
})

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

-- Display a notification that the configuration is loaded
hs.alert.show("Hammerspoon configuration loaded!")
