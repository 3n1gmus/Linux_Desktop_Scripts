#!/bin/bash
set -euo pipefail

# Ask for sudo upfront
echo "Requesting sudo permissions..."
sudo -v

# Keep-alive: update existing sudo time stamp until script finishes
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo "Updating pikman..."
pikman update

echo "Installing Kwallet Updates..."
pikman install libpam-kwallet-common libpam-kwallet5
