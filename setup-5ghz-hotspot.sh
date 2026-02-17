#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Script: setup-5ghz-hotspot.sh
# Purpose: Create / (re)configure a 5 GHz Wi-Fi hotspot with internet sharing via nmcli
# Requires: NetworkManager, nmcli, Wi-Fi adapter that supports AP mode on 5 GHz
# Usage:   sudo ./setup-5ghz-hotspot.sh
#          (or make it executable: chmod +x setup-5ghz-hotspot.sh)
# ------------------------------------------------------------------------------

set -euo pipefail

# ==================== CONFIGURABLE VARIABLES ====================

WIFI_IFACE="wlan0"                  # Your Wi-Fi interface (check: ip link or nmcli device)
CON_NAME="My5GHotspot"              # Connection profile name in NetworkManager
SSID="My5GHotspot"                  # Network name clients will see
PASSWORD="SuperSecretPass123"       # WPA2 password (8+ characters)
CHANNEL="36"                        # 5 GHz channel: 36,40,44,48,149,153,157,161,... 
                                    #   (use 'iw list' to see allowed channels in your region)

# Optional: set to "yes" to auto-start on boot (careful on laptops!)
AUTOCONNECT="no"

# Optional: fixed IP for the hotspot (clients get DHCP in 192.168.x.0/24 range)
HOTSPOT_IP="192.168.42.1/24"        # Comment out or leave empty to use default (usually 10.42.x.x)

# =================================================================

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root (sudo)."
   exit 1
fi

echo "Setting up 5 GHz Wi-Fi hotspot: $SSID on $WIFI_IFACE"

# 1. Remove any existing connection with the same name (clean start)
if nmcli con show "$CON_NAME" &>/dev/null; then
    echo "→ Deleting old connection profile '$CON_NAME'..."
    nmcli con delete "$CON_NAME" || true
fi

# 2. Create the base Wi-Fi AP connection
echo "→ Creating new connection profile..."
nmcli con add \
    type wifi \
    ifname "$WIFI_IFACE" \
    con-name "$CON_NAME" \
    autoconnect "$AUTOCONNECT" \
    ssid "$SSID" \
    >/dev/null

# 3. Configure as Access Point + force 5 GHz band
nmcli con modify "$CON_NAME" \
    802-11-wireless.mode ap \
    802-11-wireless.band a \
    802-11-wireless.channel "$CHANNEL"

# 4. Set WPA2-PSK security
nmcli con modify "$CON_NAME" \
    wifi-sec.key-mgmt wpa-psk \
    wifi-sec.psk "$PASSWORD"

# Optional: stricter WPA2 (only CCMP/AES) — usually not needed
# nmcli con modify "$CON_NAME" \
#     802-11-wireless-security.proto rsn \
#     802-11-wireless-security.pairwise ccmp \
#     802-11-wireless-security.group ccmp

# 5. Enable internet sharing (NAT + dnsmasq DHCP)
nmcli con modify "$CON_NAME" ipv4.method shared

if [[ -n "${HOTSPOT_IP:-}" ]]; then
    nmcli con modify "$CON_NAME" ipv4.addresses "$HOTSPOT_IP"
fi

# IPv6: usually auto — disable if you prefer
# nmcli con modify "$CON_NAME" ipv6.method ignore

# 6. Bring it up
echo "→ Activating hotspot..."
nmcli con up "$CON_NAME"

echo ""
echo "Hotspot is now running!"
echo "  • SSID     : $SSID"
echo "  • Password : $PASSWORD"
echo "  • Band     : 5 GHz (channel $CHANNEL)"
echo "  • Interface: $WIFI_IFACE"

# Show QR code / password reminder
echo ""
nmcli dev wifi show-password

echo ""
echo "To stop:      sudo nmcli con down '$CON_NAME'"
echo "To delete:    sudo nmcli con delete '$CON_NAME'"
echo "To check:     nmcli con show '$CON_NAME' | grep -E 'ssid|band|channel|method|psk'"
echo "              journalctl -u NetworkManager -f   (for live logs)"
echo ""

# Optional: quick status
nmcli -c yes device show "$WIFI_IFACE" | grep -E 'GENERAL.STATE|IP4.ADDRESS'