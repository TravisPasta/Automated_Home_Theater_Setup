# bootstrap.ps1
Write-Host "=== Phase 2: Automated Home Theater Setup (Windows) ==="

# Ensure TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install applications
$apps = @(
    "VideoLAN.VLC",
    "Mozilla.Firefox",
    "Git.Git",
    "Jellyfin.JellyfinMediaPlayer",
    "9N95Q1ZZPMH4",   # Twinkle Tray (Microsoft Store)
    "Python.Python.3.14"  # Python 3.14
)

foreach ($app in $apps) {
    Write-Host "Installing $app..."
    try { winget install --id $app -e --accept-source-agreements --accept-package-agreements } catch { Write-Host "Failed to install $app" }
}

# Enable SSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Enable Wake on LAN (best effort)
Write-Host "Attempting to enable Wake on LAN..."
Get-NetAdapter | ForEach-Object {
    powercfg -deviceenablewake "$($_.Name)"
}

# Plex manual download link
Start-Process "https://www.plex.tv/media-server-downloads/?cat=computer&plat=windows"

Write-Host "Please go into this repository and run the Windows 11 Debloater script manually."
Write-Host "If desired, get the new Debloater from: https://github.com/Raphire/Win11Debloat/releases/latest"

Write-Host "=== Windows Setup Complete! ==="
