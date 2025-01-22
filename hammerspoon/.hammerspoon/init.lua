-- Define your app shortcuts
local appShortcuts = {
	{ "1", "Google Chrome" },
	{ "2", "ghostty" },
}

-- Create shortcuts for each app
for _, shortcut in ipairs(appShortcuts) do
	local key, app = table.unpack(shortcut)
	hs.hotkey.bind({ "cmd", "alt" }, key, function()
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
