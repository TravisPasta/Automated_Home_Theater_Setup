#!/usr/bin/env bash
set -e
echo "=== Automated Home Theater Setup (Linux) ==="

# Detect package manager
if command -v apt &>/dev/null; then
    PKG="apt"
elif command -v dnf &>/dev/null; then
    PKG="dnf"
else
    echo "Unsupported Linux distro!"
    exit 1
fi

install_pkg() {
    if [ "$PKG" = "apt" ]; then
        sudo apt update -y
        sudo apt install -y "$@"
    else
        sudo dnf install -y "$@"
    fi
}

# Basic utilities
install_pkg git curl wget openssh-server firefox vlc

# Enable SSH
sudo systemctl enable --now ssh

# Enable Wake on LAN using NetworkManager
for iface in $(nmcli -t -f DEVICE device status | grep -v lo); do
    echo "Enabling WOL for $iface..."
    sudo nmcli connection modify "$iface" 802-3-ethernet.wake-on-lan magic || true
    sudo nmcli connection up "$iface" || true
done

# Install Tilix & ddcutil / extension manager (for supported distros)
if [ "$PKG" = "apt" ]; then
    install_pkg tilix ddcutil gnome-shell-extension-manager flatpak
elif [ "$PKG" = "dnf" ]; then
    install_pkg tilix ddcutil gnome-extensions-app flatpak
fi

# Install Jellyfin Media Player (Flatpak)
flatpak install -y flathub com.github.iwalton3.jellyfin-media-player

# Auto-start Jellyfin Media Player
mkdir -p ~/.config/autostart
cat <<EOF > ~/.config/autostart/jellyfin-media-player.desktop
[Desktop Entry]
Type=Application
Exec=flatpak run com.github.iwalton3.jellyfin-media-player
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Jellyfin Media Player
EOF

# Plex fallback link
firefox "https://www.plex.tv/media-server-downloads/?cat=computer&plat=linux" &

echo "=== Linux setup complete! ==="
