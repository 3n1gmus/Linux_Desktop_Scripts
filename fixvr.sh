# Site: https://fixvr.miguvt.com/
# A tiny udev rule that cures the blank EDID bug - no more kernel seeing your HMD as a 640×480 monitor.

#Install Fix-VR
curl -fsSL https://raw.githubusercontent.com/MiguVT/fixvr/main/src/install.sh | bash

# Uninstall
# sudo rm /etc/udev/rules.d/99-valve-index-reboot.rules
# sudo udevadm control --reload-rules