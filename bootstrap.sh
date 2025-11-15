#!/usr/bin/env bash
set -e
echo "=== Automated Home Theater Setup (Linux) ==="

# --- Detect package manager ---
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

# --- Basic utilities ---
install_pkg git curl wget openssh-server firefox vlc gnome-tweaks

# --- Enable Wake on LAN ---
for iface in $(nmcli -t -f DEVICE device status | grep -v lo); do
    echo "Enabling WOL for $iface..."
    sudo nmcli connection modify "$iface" 802-3-ethernet.wake-on-lan magic || true
    sudo nmcli connection up "$iface" || true
done

# --- Install Tilix, ddcutil, and extension manager ---
if [ "$PKG" = "apt" ]; then
    install_pkg tilix ddcutil gnome-shell-extension-manager flatpak
elif [ "$PKG" = "dnf" ]; then
    install_pkg tilix ddcutil gnome-extensions-app flatpak
fi

# --- Enable automatic login for current user ---
CURRENT_USER=$(whoami)
TTY_PATH="/etc/systemd/system/getty@tty1.service.d"

echo "[*] Enabling auto-login for $CURRENT_USER..."

sudo mkdir -p "$TTY_PATH"
cat <<EOF | sudo tee "$TTY_PATH/override.conf" > /dev/null
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $CURRENT_USER --noclear %I \$TERM
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl restart getty@tty1.service

echo "[*] Automatic login enabled for user '$CURRENT_USER' on tty1."

# --- Install Jellyfin Media Player (Flatpak) ---
echo "[*] Installing Jellyfin Media Player..."
flatpak install -y flathub com.github.iwalton3.jellyfin-media-player

# --- Auto-start Jellyfin Media Player ---
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

# --- Plex fallback ---
firefox "https://www.plex.tv/media-server-downloads/?cat=computer&plat=linux" &

# --- Install Fish shell ---
echo "[*] Installing and setting Fish shell as default..."
install_pkg fish

# Change shell for current user
if command -v fish >/dev/null 2>&1; then
    sudo chsh -s "$(command -v fish)" "$USER"
    echo "[*] Default shell for user '$USER' set to Fish."
    # Change shell for root
    sudo chsh -s "$(command -v fish)" root
    echo "[*] Default shell for root set to Fish."
else
    echo "[!] Fish installation failed or binary not found."
fi

echo "=== ✅ Linux setup complete! ==="
echo "Fish shell set for both user and root, auto-login enabled."
