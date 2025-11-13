#!/usr/bin/env bash
set -euo pipefail
echo "=== Installing Home Assistant Shutdown Web Server (Linux) ==="

# Detect package manager
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

# Install Python
$INSTALL python3 python3-pip ufw

# Install Flask
pip3 install flask

# Copy shutdown server file
sudo mkdir -p /opt/shutdown_server
sudo cp "$(dirname "$0")/shutdown_server.py" /opt/shutdown_server/
sudo chmod +x /opt/shutdown_server/shutdown_server.py

# Create systemd service
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

# Enable firewall for port 5050
sudo ufw allow 5050/tcp || true

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable shutdown_server
sudo systemctl start shutdown_server

echo "✅ Shutdown Web Server installed and running on port 5050"
echo "Test with: curl -X POST http://<IP>:5050/shutdown"
