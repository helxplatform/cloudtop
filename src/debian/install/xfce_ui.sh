#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install Xfce4 UI components"
apt-get install systemd -y
apt install task-xfce-desktop -y
