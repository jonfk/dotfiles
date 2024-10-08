local wezterm = require("wezterm")

local config = wezterm.config_builder()

local is_windows = function()
	return wezterm.target_triple:find("windows") ~= nil
end

-- config.color_scheme = ""

config.font = wezterm.font({ family = "Hack Nerd Font" })
config.font_size = 14

-- Slightly transparent and blurred background
config.window_background_opacity = 0.9
config.macos_window_background_blur = 30
-- Removes the title bar, leaving only the tab bar. Keeps
-- the ability to resize by dragging the window's edges.
-- On macOS, 'RESIZE|INTEGRATED_BUTTONS' also looks nice if
-- you want to keep the window controls visible and integrate
-- them into the tab bar.
config.window_decorations = "RESIZE"
-- Sets the font for the window frame (tab bar)
config.window_frame = {
	-- Berkeley Mono for me again, though an idea could be to try a
	-- serif font here instead of monospace for a nicer look?
	font = wezterm.font({ family = "Berkeley Mono", weight = "Bold" }),
	font_size = 11,
}

if not is_windows() then
	config.hide_tab_bar_if_only_one_tab = true
end

if is_windows() then
	config.wsl_domains = {
		{
			-- The name of this specific domain.  Must be unique amonst all types
			-- of domain in the configuration file.
			name = "WSL:Ubuntu-20.04",

			-- The name of the distribution.  This identifies the WSL distribution.
			-- It must match a valid distribution from your `wsl -l -v` output in
			-- order for the domain to be useful.
			distribution = "Ubuntu",
		},
	}
	config.default_domain = "WSL:Ubuntu-20.04"
end

return config
