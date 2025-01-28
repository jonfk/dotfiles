-- Table to store window bindings
local windowBindings = {}

-- Function to create or update a binding
local function createWindowBinding(key, window)
	-- Check if this window is already bound to this key
	if windowBindings[key] and windowBindings[key].window == window then
		-- Remove the binding if it exists (toggle behavior)
		if windowBindings[key].hotkey then
			windowBindings[key].hotkey:delete()
		end
		windowBindings[key] = nil

		hs.notify
			.new({
				title = "Binding Removed",
				informativeText = string.format(
					"Window '%s - %s' unbound from Alt+%s",
					window:application():name(),
					window:title(),
					key
				),
			})
			:send()
		return
	end

	-- Remove existing binding if there is one
	if windowBindings[key] and windowBindings[key].hotkey then
		windowBindings[key].hotkey:delete()
	end

	-- Create new binding
	windowBindings[key] = {
		window = window,
		hotkey = hs.hotkey.bind({ "alt" }, key, function()
			if window:isVisible() then
				window:focus()
			else
				hs.notify
					.new({
						title = "Window Not Found",
						informativeText = string.format(
							"Window '%s - %s' is no longer visible",
							window:application():name(),
							window:title()
						),
					})
					:send()
				-- Clean up the binding since the window is gone
				windowBindings[key].hotkey:delete()
				windowBindings[key] = nil
			end
		end),
	}

	-- Show notification
	hs.notify
		.new({
			title = "Hotkey Assigned",
			informativeText = string.format(
				"Window '%s - %s' bound to Alt+%s",
				window:application():name(),
				window:title(),
				key
			),
		})
		:send()
end

-- Create assignment hotkeys (Alt+Shift+Number)
for i = 1, 9 do
	local key = tostring(i)
	hs.hotkey.bind({ "alt", "shift" }, key, function()
		local win = hs.window.focusedWindow()
		if win then
			createWindowBinding(key, win)
		end
	end)
end

-- Define your static app shortcuts
local appShortcuts = {
	{ "1", "Google Chrome" },
	{ "2", "ghostty" },
	{ "3", "Obsidian" },
}

-- Create shortcuts for each app
for _, shortcut in ipairs(appShortcuts) do
	local key, app = table.unpack(shortcut)
	hs.hotkey.bind({ "alt" }, key, function()
		hs.application.launchOrFocus(app)
	end)
end

-- Create a window filter to watch for window focus changes
local windowFilter = hs.window.filter.new()

windowFilter:subscribe(hs.window.filter.windowFocused, function(window)
	if window then
		local frame = window:frame()
		local currentMousePos = hs.mouse.absolutePosition()

		-- Check if the cursor is already within the window frame
		local isInWindow = currentMousePos.x >= frame.x
			and currentMousePos.x <= frame.x + frame.w
			and currentMousePos.y >= frame.y
			and currentMousePos.y <= frame.y + frame.h

		-- Only move the cursor if it's not already in the window
		if not isInWindow then
			local center = hs.geometry.point(frame.x + frame.w / 2, frame.y + frame.h / 2)
			hs.mouse.absolutePosition(center)
		end
	end
end)
