<#
benchmark_windows.ps1 -- HTPC Benchmark Setup (Windows)
Usage (Admin PowerShell)
#>

Write-Host "=== HTPC Benchmark Setup (Windows) ==="

# Ensure TLS and policy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy Bypass -Scope Process -Force

# Install Git and Winget if needed (assuming phase1 script ran; but check)
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[*] Installing Git..."
    winget install --id Git.Git --accept-source-agreements --accept-package-agreements -e
}

Write-Host "[*] Installing benchmark applications via Winget / manual fallback..."

# Cinebench (Windows) :contentReference[oaicite:3]{index=3}
Write-Host "Installing Cinebench..."
winget install --id Maxon.CinebenchR23 -e --accept-source-agreements --accept-package-agreements

# Geekbench 6 :contentReference[oaicite:4]{index=4}
Write-Host "Installing Geekbench 6..."
winget install --id PrimateLabs.Geekbench.6 -e --accept-source-agreements --accept-package-agreements

# HandBrake video encoding test
Write-Host "Installing HandBrake..."
winget install --id HandBrake.HandBrake -e --accept-source-agreements --accept-package-agreements

# Install 3DMark benchmarks via Steam (free demo) :contentReference[oaicite:5]{index=5}
Write-Host "Installing Steam (for Rocket League and 3DMark) ..."
winget install --id Valve.Steam -e --accept-source-agreements --accept-package-agreements
Write-Host "Note: After Steam installation, install 3DMark, Time Spy, Fire Strike, Steel Nomad Light via Steam."

# Rocket League (note: you will configure settings manually)
Write-Host "Via Steam: install Rocket League. Then set graphics settings manually."

# 3DMark Storage Benchmark – manual note
Write-Host "Note: For Storage Benchmark (3DMark Storage), install appropriate 3DMark DLC via Steam after base install."

Write-Host "=== Windows benchmark setup done ==="
