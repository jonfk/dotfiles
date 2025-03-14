-- Window Switcher for Hammerspoon
-- Shows a searchable list of all windows and allows quick switching

-- Create a new chooser object
windowChooser = hs.chooser.new(function(selection)
	if not selection then
		return
	end

	-- Focus the selected window
	local win = selection.window
	if win then
		win:focus()
	end
end)

-- Set placeholder text and search subtext
windowChooser:placeholderText("Type to search window titles")
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

		-- Skip windows without titles
		if title and title ~= "" then
			-- Create an item for the chooser
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

			table.insert(windowList, {
				text = appName, -- Application name (main text)
				subText = title .. " (ID: " .. win:id() .. ")", -- Window title with ID
				image = appIcon, -- Application icon (safely retrieved)
				window = win, -- Store window reference for later use
			})
		end
	end

	-- Update the chooser with the window list
	windowChooser:choices(windowList)
end

-- Create a keyboard shortcut to show the window switcher
hs.hotkey.bind({ "cmd", "alt" }, "w", function()
	refreshWindowList()
	windowChooser:show()
end)

-- Log a message to confirm the script is loaded
print("Window switcher loaded! Press cmd+alt+w to activate.")
