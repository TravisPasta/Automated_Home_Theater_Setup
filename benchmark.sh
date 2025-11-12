#!/usr/bin/env bash
set -euo pipefail
echo "=== HTPC Benchmark Setup (Linux) ==="

# Detect package manager (apt/dnf)
if command -v apt >/dev/null 2>&1; then
  PKG="apt"
  sudo apt update -y
  INSTALL="sudo apt install -y"
elif command -v dnf >/dev/null 2>&1; then
  PKG="dnf"
  sudo dnf makecache -y
  INSTALL="sudo dnf install -y"
else
  echo "Unsupported distro (no apt or dnf). Aborting." >&2
  exit 1
fi
echo "[*] Using package manager: $PKG"

# Install general tools
$INSTALL git wget curl

# Install/unpack benchmarks
echo "[*] Installing benchmarks..."

# Cinebench (download from Maxon) :contentReference[oaicite:0]{index=0}
wget -O Cinebench.zip "https://download.maxon.net/Cinebench_2024_x64_Linux.zip" || echo "Failed to download Cinebench; you will need to fetch manually"

# Geekbench 6 :contentReference[oaicite:1]{index=1}
wget -O geekbench6.tar.gz "https://cdn.geekbench.com/Geekbench-6.5.0-Linux.tar.gz" || echo "Failed to download Geekbench 6; manual required"

# HandBrake (video encoding test) – install HandBrake CLI or GUI
$INSTALL handbrake-cli || echo "Install HandBrake manually"

# 3DMark variants – note: 3DMark official support is mostly Windows. :contentReference[oaicite:2]{index=2}
echo "[!] 3DMark Fire Strike / Time Spy / Steel Nomad may require Windows. On Linux you may skip or use benchmarking via Proton/Steam."

# Steam install for Rocket League (you’ll launch it manually later for graphics settings)
$INSTALL steam || echo "Install Steam manually"

echo "[*] Manual steps required:"
echo "    – Unzip/run Cinebench, Geekbench"
echo "    – For Rocket League: launch Steam → install & set your graphics settings (e.g., resolution, quality, vsync) manually"

echo "=== Linux benchmark setup done ==="
