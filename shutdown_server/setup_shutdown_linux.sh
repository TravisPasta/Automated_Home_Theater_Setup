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
$INSTALL python3 python3-pip curl ufw

# --- Install Flask system-wide ---
echo "[*] Installing Flask..."
python3 -m pip install --user --upgrade pip setuptools wheel flask

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

echo "✅ Shutdown Web Server installed and running on port 5050 (user service)"
echo "Test with: curl -X POST http://<IP>:5050/shutdown"
echo "Service controlled via: systemctl --user status|restart|stop shutdown_server.service"
