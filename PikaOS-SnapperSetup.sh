#!/bin/bash
set -euo pipefail

# Ask for sudo upfront
echo "Requesting sudo permissions..."
sudo -v

# Keep-alive: update existing sudo time stamp until script finishes
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo "Updating pikman..."
pikman update

echo "Installing Snapper and Snapper GUI..."
pikman install snapper snapper-gui

echo "Creating Snapper configuration for root..."
sudo snapper create-config /

echo "Creating /var/lib/refind-btrfs directory with proper permissions..."
sudo mkdir -p /var/lib/refind-btrfs
sudo chmod 755 /var/lib/refind-btrfs

echo "Installing rEFInd Btrfs hooks and refind-btrfs..."
pikman install pika-refind-btrfs-hooks refind-btrfs btrfs-assistant

echo "Enabling refind-btrfs service..."
sudo systemctl enable refind-btrfs --now

echo "All done!"
