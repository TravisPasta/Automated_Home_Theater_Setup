# bootstrap.ps1
Write-Host "=== Phase 2: Automated Home Theater Setup (Windows) ==="

# Ensure TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Additional installs
$apps += @(
    "7zip.7zip",
    "Audacity.Audacity",
    "AutoHotkey.AutoHotkey",
    "Blizzard.BattleNet",
    "BlenderFoundation.Blender",
    "JetBrains.Toolbox",
    "Overwolf.CurseForge",
    "Discord.Discord",
    "EpicGames.EpicGamesLauncher",
    "FluxSoftware.F.lux",
    "Flameshot.Flameshot",
    "GitHub.GitHubDesktop",
    "GitHub.GitLFS",
    "HandBrake.HandBrake",
    "Jellyfin.JellyfinMediaPlayer",
    "KDE.Kdenlive",
    "Microsoft.VisualStudioCode",
    "Microsoft.MinecraftLauncher",
    "Notepad++.Notepad++",
    "OBSProject.OBSStudio",
    "RedHat.Podman",
    "Microsoft.PowerShell",
    "Microsoft.PowerToys",
    "Mozilla.Firefox",
    "Plex.Plex",
    "Python.Python.3.14",
    "Spotify.Spotify",
    "Valve.Steam",
    "Telegram.TelegramDesktop",
    "Microsoft.WindowsTerminal",
    "JAMSoftware.TreeSize.Free",
    "xanderfrangos.TwinkleTray",
    "Ultimaker.Cura",
    "Unity.UnityHub",
    "RARLab.WinRAR",
    "WireGuard.WireGuard",
    "VideoLAN.VLC",
    "Git.Git",
    "XPDDT99J9GKB5C"        # Samsung Magician Serial
)


foreach ($app in $apps) {
    Write-Host "Installing $app..."
    try { winget install --id $app -e --accept-source-agreements --accept-package-agreements } catch { Write-Host "Failed to install $app" }
}

# Manual install instructions
Write-Host "⚠ Manual install required for:
- DaVinci Resolve
- Native Instruments/ Native Access
- Samsung Magician (Serial: XPDDT99J9GKB5C)
- adobe:
    - media encoder
    - photoshop
    - premiere pro
- AMD Software
- Bakkesmod
- DaVinci Resolve
- Elgato Game Capture HD
- EOS Webcam Utility
- Gaomon Tablet
- Insta360 Studio
- Logi Options+
- Make MKV
- Native Instruments/Native Access (?)
- Soundcraft Multi-channel USB Audio Interface Driver and Software
"


Write-Host "Please go into this repository and run the Windows 11 Debloater script manually."

Write-Host "=== Windows Setup Complete! ==="
