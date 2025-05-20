---
-- WindowSwitcherWebView - Web UI for WindowSwitcher Spoon
-- @author Jonathan Fok kan
-- @copyright MIT - https://opensource.org/licenses/MIT
-- @release 1.0
-- @description
-- This spoon provides a web-based UI for the WindowSwitcher spoon.
-- It displays all windows with their shortcuts and allows assigning new shortcuts.

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "WindowSwitcherWebView"
obj.version = "1.0"
obj.author = "Jonathan Fok kan"
obj.homepage = "https://github.com/jonfk/dotfiles"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.dependencies = {
	{
		["name"] = "WindowSwitcher",
		["version"] = "1.0",
	},
}

-- Configuration defaults
obj.windowSwitcher = nil -- Reference to WindowSwitcher spoon
obj.webview = nil -- The webview object
obj.userContent = nil -- User content controller for message handling
obj.width = 700 -- Default width of the webview
obj.height = 550 -- Default height of the webview

-- Initialize the spoon
function obj:init()
	return self
end

-- Bind hotkeys for WindowSwitcherWebView
function obj:bindHotkeys(mapping)
	local spec = {
		show = hs.fnutils.partial(self.show, self),
		hide = hs.fnutils.partial(self.hide, self),
		toggle = hs.fnutils.partial(self.toggle, self),
	}

	hs.spoons.bindHotkeysToSpec(spec, mapping)
	return self
end

-- Toggle the visibility of the webview
function obj:toggle()
	if self.webview and self.webview:isVisible() then
		self:hide()
	else
		self:show()
	end
end

-- Convert all window data to JSON for the webview
function obj:getWindowDataJSON()
	if not self.windowSwitcher then
		return "[]"
	end

	-- Get window data with bindings from WindowSwitcher
	local windowData = self.windowSwitcher:getAllWindowsWithBindings()

	-- Prepare data for JSON conversion
	local jsonReady = {}
	for _, window in ipairs(windowData) do
		-- Convert image to base64 URL string if available
		local imageURL = nil
		if window.image then
			imageURL = window.image:encodeAsURLString(false, "PNG")
		end

		-- Create table with window information
		table.insert(jsonReady, {
			id = window.windowId,
			appName = window.text,
			title = window.fullTitle,
			truncatedTitle = window.subText,
			imageURL = imageURL,
			keybindings = window.keybindings or {},
			shortnames = window.shortnames or {},
		})
	end

	-- Convert to JSON
	return hs.json.encode(jsonReady)
end

-- Create HTML for the webview
function obj:createHTML()
	-- Get window data in JSON format
	local windowDataJSON = self:getWindowDataJSON()

	-- Create HTML with embedded window data
	local html = [[
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>WindowSwitcher</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: #f5f5f7;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 100%;
            margin: 0 auto;
            padding-bottom: 20px; /* Add padding at the bottom */
        }
        .search-container {
            margin-bottom: 15px;
        }
        #searchInput {
            width: 100%;
            padding: 8px;
            font-size: 16px;
            border-radius: 6px;
            border: 1px solid #ccc;
        }
        .window-list {
            border-radius: 10px;
            background-color: white;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            overflow: hidden;
            max-height: 380px; /* Increased max height */
            overflow-y: auto;
        }
        .window-item {
            display: flex;
            align-items: center;
            padding: 12px 15px;
            border-bottom: 1px solid #eee;
            cursor: pointer;
            transition: background-color 0.2s;
        }
        .window-item:last-child {
            border-bottom: none;
        }
        .window-item:hover {
            background-color: #f0f0f5;
        }
        .window-icon {
            width: 32px;
            height: 32px;
            margin-right: 15px;
            flex-shrink: 0;
        }
        .window-details {
            flex: 1;
        }
        .app-name {
            font-weight: bold;
            margin-bottom: 3px;
        }
        .window-title {
            color: #666;
            font-size: 13px;
        }
        .window-bindings {
            display: flex;
            flex-direction: column;
            text-align: right;
            min-width: 120px;
        }
        .binding-tag {
            font-size: 12px;
            background-color: #e0e0e0;
            border-radius: 4px;
            padding: 2px 8px;
            margin: 2px 0;
            display: inline-block;
        }
        .key-binding {
            background-color: #007aff;
            color: white;
        }
        .shortname-binding {
            background-color: #34c759;
            color: white;
        }
        .action-buttons {
            margin-top: 20px; /* Increased top margin */
            margin-bottom: 10px; /* Added bottom margin */
            display: flex;
            justify-content: space-between;
        }
        button {
            background-color: #007aff;
            color: white;
            border: none;
            border-radius: 6px;
            padding: 8px 15px;
            font-size: 14px;
            cursor: pointer;
            transition: background-color 0.2s;
        }
        button:hover {
            background-color: #0062cc;
        }
        button:focus {
            outline: 2px solid #0062cc;
            outline-offset: 2px;
        }
        #assignShortcutBtn.active {
            background-color: #34c759; /* Green to indicate active shortcut assignment */
            animation: pulse 1.5s infinite;
        }
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.7; }
            100% { opacity: 1; }
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }
        .title {
            font-size: 20px;
            font-weight: bold;
        }
        #windowCount {
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="title">Window Switcher</div>
            <div id="windowCount"></div>
        </div>
        
        <div class="search-container">
            <input type="text" id="searchInput" placeholder="Search windows...">
        </div>
        
        <div class="window-list" id="windowList">
            <!-- Window items will be populated here via JavaScript -->
        </div>
        
        <div class="action-buttons">
            <button id="refreshBtn">Refresh</button>
            <button id="assignShortcutBtn">Assign Shortcut</button>
            <button id="assignShortnameBtn">Assign Shortname</button>
            <button id="closeBtn">Close</button>
        </div>
    </div>
    
    <script>
        // Window data from Hammerspoon
        const windowData = ]] .. windowDataJSON .. [[;
        
        // DOM elements
        const windowList = document.getElementById('windowList');
        const searchInput = document.getElementById('searchInput');
        const windowCount = document.getElementById('windowCount');
        const refreshBtn = document.getElementById('refreshBtn');
        const assignShortcutBtn = document.getElementById('assignShortcutBtn');
        const assignShortnameBtn = document.getElementById('assignShortnameBtn');
        const closeBtn = document.getElementById('closeBtn');
        
        // Current selected window
        let selectedWindowId = null;
        
        // Update window count display
        function updateWindowCount() {
            windowCount.textContent = `${windowData.length} windows`;
        }
        
        // Render all windows in the list
        function renderWindowList(windows) {
            windowList.innerHTML = '';
            
            windows.forEach(window => {
                const item = document.createElement('div');
                item.className = 'window-item';
                item.dataset.windowId = window.id;
                
                // Highlight selected item
                if (window.id === selectedWindowId) {
                    item.style.backgroundColor = '#f0f0f5';
                }
                
                item.innerHTML = `
                    <img class="window-icon" src="${window.imageURL || 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiM5OTkiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIj48cmVjdCB4PSIzIiB5PSIzIiB3aWR0aD0iMTgiIGhlaWdodD0iMTgiIHJ4PSIyIiByeT0iMiI+PC9yZWN0Pjwvc3ZnPg=='}" alt="${window.appName}">
                    <div class="window-details">
                        <div class="app-name">${window.appName}</div>
                        <div class="window-title">${window.truncatedTitle}</div>
                    </div>
                    <div class="window-bindings">
                        ${window.keybindings.map(key => `<span class="binding-tag key-binding">Alt+${key}</span>`).join('')}
                        ${window.shortnames.map(name => `<span class="binding-tag shortname-binding">${name}</span>`).join('')}
                    </div>
                `;
                
                item.addEventListener('click', () => {
                    // Update selected window
                    document.querySelectorAll('.window-item').forEach(el => {
                        el.style.backgroundColor = '';
                    });
                    item.style.backgroundColor = '#f0f0f5';
                    selectedWindowId = window.id;
                });
                
                windowList.appendChild(item);
            });
        }
        
        // Filter windows based on search input
        function filterWindows() {
            const searchTerm = searchInput.value.toLowerCase();
            const filteredWindows = windowData.filter(window => {
                return window.appName.toLowerCase().includes(searchTerm) || 
                       window.title.toLowerCase().includes(searchTerm);
            });
            renderWindowList(filteredWindows);
        }
        
        // Initial render
        updateWindowCount();
        renderWindowList(windowData);
        
        // Event listeners
        searchInput.addEventListener('input', filterWindows);
        
        refreshBtn.addEventListener('click', () => {
            window.webkit.messageHandlers.windowSwitcherHandler.postMessage({
                action: 'refresh'
            });
        });
        
        assignShortcutBtn.addEventListener('click', () => {
            if (selectedWindowId) {
                // Toggle the active state for visual feedback during shortcut assignment
                assignShortcutBtn.classList.add('active');
                
                window.webkit.messageHandlers.windowSwitcherHandler.postMessage({
                    action: 'assignShortcut',
                    windowId: selectedWindowId
                });
                
                // Remove the active state after a delay (shortcut assignment should be done by then)
                setTimeout(() => {
                    assignShortcutBtn.classList.remove('active');
                }, 2000);
            } else {
                alert('Please select a window first');
            }
        });
        
        assignShortnameBtn.addEventListener('click', () => {
            if (selectedWindowId) {
                window.webkit.messageHandlers.windowSwitcherHandler.postMessage({
                    action: 'assignShortname',
                    windowId: selectedWindowId
                });
            } else {
                alert('Please select a window first');
            }
        });
        
        closeBtn.addEventListener('click', () => {
            window.webkit.messageHandlers.windowSwitcherHandler.postMessage({
                action: 'close'
            });
        });
    </script>
</body>
</html>
    ]]

	return html
end

-- Refresh the webview data
function obj:refresh()
	if self.webview then
		-- Update the HTML content with fresh data
		self.webview:html(self:createHTML())
	end
	return self
end

-- Update the webview after shortcuts change
function obj:updateAfterShortcutChange()
	-- Add a small delay to ensure shortcut was set and WindowSwitcher has updated its data
	hs.timer.doAfter(5, function()
		self:refresh()
	end)
end

-- Show the webview
function obj:show()
	-- If no WindowSwitcher spoon reference, try to find it
	if not self.windowSwitcher then
		if spoon.WindowSwitcher then
			self.windowSwitcher = spoon.WindowSwitcher
		else
			hs.alert.show("WindowSwitcher spoon not found")
			return
		end
	end

	-- Calculate frame for the webview (centered on screen)
	local screenFrame = hs.screen.mainScreen():frame()
	local x = screenFrame.x + (screenFrame.w - self.width) / 2
	local y = screenFrame.y + (screenFrame.h - self.height) / 2
	local frame = hs.geometry.rect(x, y, self.width, self.height)

	-- Create user content controller for message handling
	self.userContent = hs.webview.usercontent.new("windowSwitcherHandler")
	self.userContent:setCallback(function(message)
		self:handleWebviewMessage(message)
	end)

	-- Create and show the webview
	self.webview = hs.webview.new(frame, {
		developerExtrasEnabled = true,
	}, self.userContent)

	-- Set webview properties
	self.webview:windowTitle("WindowSwitcher")
	self.webview:allowTextEntry(true)
	self.webview:allowNewWindows(false)
	self.webview:windowStyle({ "titled", "closable", "resizable" })
	self.webview:level(hs.drawing.windowLevels.floating) -- Set window level to stay on top

	-- Show the webview
	self.webview:html(self:createHTML())

	-- Show the webview and ensure it's focused
	self.webview:show()
	self.webview:bringToFront(true) -- Explicitly bring to front and focus

	return self
end

-- Hide the webview
function obj:hide()
	if self.webview then
		self.webview:delete()
		self.webview = nil
	end

	return self
end

-- Handle messages from the webview
function obj:handleWebviewMessage(message)
	local body = message.body
	local action = body.action

	if action == "close" then
		-- Close the webview
		self:hide()
	elseif action == "focusWindow" then
		-- Focus a window
		local windowId = body.windowId
		if windowId then
			local win = hs.window.get(windowId)
			if win then
				win:focus()
			end
		end
	elseif action == "assignShortcut" then
		-- Assign a shortcut to a window
		local windowId = body.windowId
		if windowId then
			local win = hs.window.get(windowId)
			if win and self.windowSwitcher then
				-- Prompt for shortcut assignment without hiding webview
				self.windowSwitcher:promptForShortcut(win)
				-- Update the webview after shortcut change
				self:updateAfterShortcutChange()
			end
		end
	elseif action == "assignShortname" then
		-- Assign a shortname to a window
		local windowId = body.windowId
		if windowId then
			local win = hs.window.get(windowId)
			if win and self.windowSwitcher then
				-- Prompt for shortname assignment without hiding webview
				self.windowSwitcher:promptForShortname(win)
				-- Update the webview after shortname change
				self:updateAfterShortcutChange()
			end
		end
	elseif action == "refresh" then
		-- Refresh the window list
		self:refresh()
	end
end

-- Start method (for API consistency)
function obj:start()
	-- Ensure WindowSwitcher spoon is available
	if not self.windowSwitcher then
		if spoon.WindowSwitcher then
			self.windowSwitcher = spoon.WindowSwitcher
		else
			hs.notify.show("WindowSwitcherWebView", "Error", "WindowSwitcher spoon is required but not loaded")
			return self
		end
	end

	-- Add a hotkey to show the interface
	self:bindHotkeys({
		toggle = { { "cmd", "alt" }, "v" },
	})

	return self
end

-- Stop method (for API consistency)
function obj:stop()
	self:hide()
	return self
end

return obj
