# bootstrap.ps1
Write-Host "=== Phase 2: Automated Home Theater Setup (Windows) ==="

# Ensure TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Detect if OS is Windows 11
$osVersion = (Get-ComputerInfo).WindowsProductName
$isWin11 = $osVersion -match "Windows 11"

# Run Windows 11 Debloater
if ($isWin11) {
    Write-Host "Detected Windows 11 – running debloater..."
    $debloaterUrl = "https://github.com/Raphire/Win11Debloat/releases/latest/download/Get.ps1"
    $debloaterPath = "$env:TEMP\Get.ps1"
    try {
        Invoke-WebRequest -Uri $debloaterUrl -OutFile $debloaterPath -ErrorAction Stop
        Write-Host "Running latest downloaded debloater..."
        & PowerShell -ExecutionPolicy Bypass -File $debloaterPath
    } catch {
        Write-Host "Download failed. Using local debloater..."
        & PowerShell -ExecutionPolicy Bypass -File "$PSScriptRoot\Win11Debloater\Get.ps1"
    }
}

# Install applications
$apps = @(
    "VideoLAN.VLC",
    "Mozilla.Firefox",
    "Git.Git",
    "Jellyfin.JellyfinMediaPlayer",
    "9N95Q1ZZPMH4",   # Twinkle Tray (Microsoft Store)
    "Discord.Discord",
    "Spotify.Spotify"
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

Write-Host "=== Windows Setup Complete! ==="
