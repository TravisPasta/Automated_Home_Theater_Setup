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

# --- Install Flask ---
echo "[*] Installing Flask..."
python3 -m pip install --upgrade pip setuptools wheel
python3 -m pip install flask

# --- Prepare target directory ---
echo "[*] Setting up shutdown server directory..."
sudo mkdir -p /opt/shutdown_server

# --- Download shutdown_server.py ---
echo "[*] Downloading shutdown_server.py from GitHub..."
DOWNLOAD_URL="https://raw.githubusercontent.com/TravisPasta/Automated_Home_Theater_Setup/benchmark/shutdown_server/shutdown_server.py"
TMP_FILE="/tmp/shutdown_server.py"

if curl -fsSL "$DOWNLOAD_URL" -o "$TMP_FILE"; then
    echo "[*] Download successful."
else
    echo "[✖] Failed to download shutdown_server.py"
    exit 1
fi

# --- Copy file into /opt/shutdown_server ---
sudo cp "$TMP_FILE" /opt/shutdown_server/shutdown_server.py
sudo chmod +x /opt/shutdown_server/shutdown_server.py

# --- Create systemd service ---
echo "[*] Creating systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/shutdown_server.service > /dev/null
[Unit]
Description=Simple Shutdown Web Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/shutdown_server/shutdown_server.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# --- Open firewall port ---
sudo ufw allow 5050/tcp || true

# --- Enable + start service ---
echo "[*] Enabling and starting shutdown_server service..."
sudo systemctl daemon-reload
sudo systemctl enable shutdown_server
sudo systemctl start shutdown_server

echo "✅ Shutdown Web Server installed and running on port 5050"
echo "Test with: curl -X POST http://<IP>:5050/shutdown"
