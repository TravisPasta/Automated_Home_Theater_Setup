#!/usr/bin/env bash
set -euo pipefail
echo "=== Installing Home Assistant Shutdown Web Server (Linux) ==="

# --- Detect package manager ---
if command -v apt >/dev/null 2>&1; then
    sudo apt update -y
    INSTALL="sudo apt install -y"
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf makecache -y
    INSTALL="sudo dnf install -y"
else
    echo "Unsupported distro (no apt or dnf)"
    exit 1
fi

# --- Install Python + tools ---
$INSTALL python3 python3-pip curl ufw ethtool

# --- Install Flask for user ---
echo "[*] Installing Flask..."
python3 -m pip install --user --upgrade pip setuptools wheel flask

# -------------------------------------------------------------------
#                         WAKE-ON-LAN SETUP
# -------------------------------------------------------------------

echo "=== Enabling Wake-on-LAN (MagicPacket) ==="

# Automatically detect primary interface (non-loopback, UP state)
INTERFACE=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2; exit}')

echo "[*] Detected network interface: $INTERFACE"

# Check if interface supports WoL
SUPPORTS=$(sudo ethtool "$INTERFACE" | grep "Supports Wake-on" | awk '{print $3}')
CURRENT=$(sudo ethtool "$INTERFACE" | grep "Wake-on" | awk '{print $2}' | tail -1)

echo "[*] Interface supports WoL modes: $SUPPORTS"
echo "[*] Current WoL setting: $CURRENT"

if [[ "$SUPPORTS" != *g* ]]; then
    echo "[✖] This network card does NOT support MagicPacket (g). WoL cannot be enabled."
else
    echo "[*] Enabling WoL now..."
    sudo ethtool -s "$INTERFACE" wol g

    # Persistent WoL via NetworkManager
    CONN_NAME=$(nmcli -t -f NAME connection show | head -n 1)
    echo "[*] Detected NetworkManager connection: $CONN_NAME"

    echo "[*] Making WoL persistent..."
    sudo nmcli connection modify "$CONN_NAME" 802-3-ethernet.wake-on-lan magic

    echo "[*] Reapplying connection..."
    sudo nmcli device reapply "$INTERFACE" || true

    echo "✅ Wake-on-LAN enabled and made persistent (MagicPacket mode)"
fi

# -------------------------------------------------------------------
#                       SHUTDOWN SERVER INSTALL
# -------------------------------------------------------------------

# --- Prepare target directory in home folder ---
TARGET_DIR="$HOME/shutdown_server"
mkdir -p "$TARGET_DIR"

# --- Download shutdown_server.py ---
echo "[*] Downloading shutdown_server.py from GitHub..."
DOWNLOAD_URL="https://raw.githubusercontent.com/TravisPasta/Automated_Home_Theater_Setup/benchmark/shutdown_server/shutdown_server.py"
TARGET_FILE="$TARGET_DIR/shutdown_server.py"

if curl -fsSL "$DOWNLOAD_URL" -o "$TARGET_FILE"; then
    echo "[*] Download successful."
else
    echo "[✖] Failed to download shutdown_server.py"
    exit 1
fi

chmod +x "$TARGET_FILE"

# --- Create user-level systemd service ---
echo "[*] Creating user systemd service..."
mkdir -p ~/.config/systemd/user

cat <<EOF > ~/.config/systemd/user/shutdown_server.service
[Unit]
Description=Simple Shutdown Web Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 $TARGET_FILE
Restart=always

[Install]
WantedBy=default.target
EOF

# --- Enable and start as user service ---
systemctl --user daemon-reload
systemctl --user enable shutdown_server.service
systemctl --user start shutdown_server.service

# --- Allow firewall port ---
sudo ufw allow 5050/tcp || true

# --- Auto-start on login for user session ---
loginctl enable-linger "$USER"

echo "==============================================="
echo "  ✅ Shutdown Web Server installed"
echo "  ✅ Service running on port 5050"
echo "  ✅ Persistent Wake-on-LAN configured"
echo "==============================================="
echo "Test shutdown with: curl -X POST http://<IP>:5050/shutdown"
