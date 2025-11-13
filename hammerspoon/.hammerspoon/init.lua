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

local baseBindingTemplates = {
	{
		key = ",",
		appName = "chrome",
		windowTitle = "personal",
		description = "Chrome Personal",
	},
	-- {
	-- 	key = "p",
	-- 	appName = "chrome",
	-- 	windowTitle = "private",
	-- 	description = "Chrome Private",
	-- },
	{
		key = "p",
		appName = "brave",
		windowTitle = "",
		description = "Brave",
	},
	{
		key = "1",
		appName = "chrome",
		windowTitle = "(coveo)",
		description = "Chrome Work",
	},
	{
		key = "a",
		appName = "slack",
		windowTitle = "",
		description = "Slack",
	},
	{
		key = "2",
		appName = "ghostty",
		windowTitle = "",
		description = "Ghostty Terminal",
	},
	{
		key = "'",
		appName = "claude",
		windowTitle = "",
		description = "Claude",
	},
	{
		key = ".",
		appName = "chatgpt",
		windowTitle = "",
		description = "ChatGPT",
	},
	{
		key = "3",
		appName = "intellij idea",
		windowTitle = "",
		description = "IntelliJ IDEA",
	},
	{
		key = "o",
		appName = "microsoft outlook",
		windowTitle = "",
		description = "Microsoft Outlook",
	},
	{
		key = "e",
		appName = "obsidian",
		windowTitle = "coveo-work-notes",
		description = "Obsidian coveo-work-notes",
	},
	{
		key = "j",
		appName = "code",
		windowTitle = "",
		description = "VS Code",
	},
}

local layoutModifiersMap = {
	["com.apple.keylayout.Dvorak"] = { "alt" },
	["com.apple.keylayout.ABC"] = { "alt", "ctrl", "cmd" },
}

local fallbackModifiers = layoutModifiersMap["com.apple.keylayout.ABC"]

local function cloneList(list)
	local copy = {}
	for index, value in ipairs(list) do
		copy[index] = value
	end
	return copy
end

local function buildBindingsWithModifiers(modifiers)
	local bindings = {}
	for _, template in ipairs(baseBindingTemplates) do
		local binding = {}
		for key, value in pairs(template) do
			binding[key] = value
		end
		binding.modifiers = cloneList(modifiers)
		table.insert(bindings, binding)
	end
	return bindings
end

local function modifiersForSource(sourceID)
	return cloneList(layoutModifiersMap[sourceID] or fallbackModifiers)
end

local function signature(modifiers)
	return table.concat(modifiers, "-")
end

local activeModifierSignature = nil

local function applyBindingsForModifiers(modifiers)
	local bindings = buildBindingsWithModifiers(modifiers)
	spoon.FzfWindowSwitcher:setExclusionFilters(bindings)
	spoon.WindowSwitcherHotkeys:setModifiers(bindings)
	activeModifierSignature = signature(modifiers)
end

local currentSourceID = hs.keycodes.currentSourceID()
applyBindingsForModifiers(modifiersForSource(currentSourceID))

spoon.FzfWindowSwitcher:start()

spoon.WindowSwitcherHotkeys:start()

-- Keep watcher reference to prevent garbage collection
windowSwitcherLayoutWatcher = hs.keycodes.inputSourceChanged(function()
	local newModifiers = modifiersForSource(hs.keycodes.currentSourceID())
	local newSignature = signature(newModifiers)
	if newSignature ~= activeModifierSignature then
		applyBindingsForModifiers(newModifiers)
	end
end)

-- Display a notification that the configuration is loaded
hs.alert.show("Hammerspoon configuration loaded!")
