#
# Neovim Terminal Server Function (nv)
nv() {
  local NVIM_SOCKET="/tmp/nvim-server"
  
  # Start a neovim server if it doesn't exist
  if ! [ -e "$NVIM_SOCKET" ]; then
    # Start a normal (not headless) neovim server in the current terminal
    nvim --listen "$NVIM_SOCKET" "$@"
    return
  fi
  
  # If arguments are provided, open them in the existing server
  if [ "$#" -gt 0 ]; then
    nvim --server "$NVIM_SOCKET" --remote "$@"
  fi
}

# Neovide GUI Server Function (nvg)
nvg() {
  local NVIM_SOCKET="/tmp/nvim-server"
  
  # Start a neovim server if it doesn't exist
  if ! [ -e "$NVIM_SOCKET" ]; then
    # Start a headless neovim server
    nvim --headless --listen "$NVIM_SOCKET" &
    sleep 0.5  # Give it a moment to start
  fi
  
  # Check if neovide is already running with this server
  if pgrep -f "neovide --server=$NVIM_SOCKET" > /dev/null; then
    # Neovide is running
    if [ "$#" -gt 0 ]; then
      # Open files in the existing instance
      nvim --server "$NVIM_SOCKET" --remote "$@"
    fi
    # TODO: Add focus window if neovide already exists
  else
    # Neovide is not running, start it
    neovide --server="$NVIM_SOCKET" &
    
    # If arguments provided, wait a moment then open them
    if [ "$#" -gt 0 ]; then
      sleep 0.8  # Give neovide time to connect
      nvim --server "$NVIM_SOCKET" --remote "$@"
    fi
  fi
}
