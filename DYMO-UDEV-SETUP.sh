#!/usr/bin/env bash
set -euo pipefail

DYMO_LINE="$(lsusb | grep -i -m1 dymo || true)"
if [[ -z "$DYMO_LINE" ]]; then
  echo "No DYMO device found by 'lsusb | grep -i dymo'." >&2
  exit 1
fi

# Example line:
# Bus 001 Device 081: ID 0922:1002 Dymo-CoStar Corp. DYMO LabelManager PnP
VENDOR_ID="$(echo "$DYMO_LINE" | sed -n 's/.* ID \([0-9a-fA-F]\{4\}\):\([0-9a-fA-F]\{4\}\).*/\1/p' | tr '[:upper:]' '[:lower:]')"
PRODUCT_ID="$(echo "$DYMO_LINE" | sed -n 's/.* ID \([0-9a-fA-F]\{4\}\):\([0-9a-fA-F]\{4\}\).*/\2/p' | tr '[:upper:]' '[:lower:]')"

if [[ -z "${VENDOR_ID:-}" || -z "${PRODUCT_ID:-}" ]]; then
  echo "Could not parse vendor/product IDs from:" >&2
  echo "$DYMO_LINE" >&2
  exit 1
fi

RULE_FILE="/etc/udev/rules.d/99-dymo-labelmanager-pnp.rules"

echo "Found: $DYMO_LINE"
echo "Using udev rule for idVendor=$VENDOR_ID idProduct=$PRODUCT_ID"

cat <<EOF | sudo tee "$RULE_FILE" >/dev/null
SUBSYSTEM=="usb", ATTR{idVendor}=="$VENDOR_ID", ATTR{idProduct}=="$PRODUCT_ID", MODE="0666"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger

echo "Created $RULE_FILE"
echo "Unplug/replug the DYMO, then run: labelle-gui"