#!/usr/bin/env bash
set -euo pipefail

echo "[+] Setting up I2C access for OpenRGB (AMD)..."

# 1. Create the i2c system group if it does not already exist
if ! getent group i2c >/dev/null 2>&1; then
    echo " -> Creating 'i2c' group..."
    sudo groupadd --system i2c
else
    echo " -> 'i2c' group already exists."
fi

# 2. Add current user to the i2c group
if groups "$USER" | grep &>/dev/null '\bi2c\b'; then
    echo " -> User '$USER' is already in the 'i2c' group."
else
    echo " -> Adding user '$USER' to 'i2c' group..."
    sudo usermod -aG i2c "$USER"
fi

# 3. Configure modules to load automatically on boot
echo " -> Writing /etc/modules-load.d/openrgb-i2c.conf..."
echo -e "i2c-dev\ni2c-piix4" | sudo tee /etc/modules-load.d/openrgb-i2c.conf >/dev/null

# 4. Load modules into active session if not already loaded
echo " -> Loading kernel modules..."
sudo modprobe i2c-dev 2>/dev/null || true
sudo modprobe i2c-piix4 2>/dev/null || true

# 5. Create udev rule for device permissions
echo " -> Setting up /etc/udev/rules.d/99-i2c.rules..."
echo 'KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"' | sudo tee /etc/udev/rules.d/99-i2c.rules >/dev/null

# 6. Reload udev rules to apply permissions to current /dev/i2c-* nodes
echo " -> Reloading udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=i2c-dev 2>/dev/null || sudo udevadm trigger

echo ""
echo "[+] Verifying I2C device node permissions..."

# 7. Test read/write permissions on available /dev/i2c-* nodes
i2c_nodes=( /dev/i2c-* )

if [ ! -e "${i2c_nodes[0]}" ]; then
    echo " [!] Warning: No /dev/i2c-* devices found. Ensure modules loaded properly."
else
    accessible_count=0
    total_count=0

    for dev in "${i2c_nodes[@]}"; do
        [ -e "$dev" ] || continue
        ((total_count++))
        if [ -r "$dev" ] && [ -w "$dev" ]; then
            ((accessible_count++))
        fi
    done

    if [ "$accessible_count" -eq "$total_count" ] && [ "$total_count" -gt 0 ]; then
        echo " [✓] Success: Read/Write access confirmed on all $total_count I2C device nodes."
    else
        echo " [!] Notice: User has R/W access to $accessible_count of $total_count I2C device nodes."
        echo "     This is expected in the current shell session before logging out or running 'exec su -l $USER'."
    fi
fi

echo ""
echo "[✓] Setup complete!"
echo "NOTE: If verification reported partial access, refresh your session with: exec su -l $USER"