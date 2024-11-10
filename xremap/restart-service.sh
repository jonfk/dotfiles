#!/bin/bash
sudo cp /home/jonfk/dotfiles/xremap/xremap.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl restart xremap
echo "Service file updated and restarted"
