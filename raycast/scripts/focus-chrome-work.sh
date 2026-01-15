#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Focus Work Chrome
# @raycast.mode silent
# @raycast.packageName Browser
# @raycast.icon 👷

/usr/bin/osascript <<'APPLESCRIPT'
set targetPrefix to "https://coveord.atlassian.net"

tell application "Google Chrome"
	-- If Chrome isn't running or has no windows, do nothing
	if not (exists window 1) then return

	repeat with w in windows
		set tabIndex to 0
		repeat with t in (tabs of w)
			set tabIndex to tabIndex + 1
			if tabIndex > 10 then exit repeat
			set theURL to (URL of t)
			if theURL is not missing value then
				if theURL starts with targetPrefix then
					set index of w to 1 -- bring window to front
					activate
					return
				end if
			end if
		end repeat
	end repeat
end tell
APPLESCRIPT
