<#
setup_shutdown_windows.ps1 -- Sets up Flask shutdown web server on Windows
Requires: Administrator PowerShell
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Log { param($m) Write-Host "[*] $m" -ForegroundColor Cyan }
function Warn { param($m) Write-Host "[!] $m" -ForegroundColor Yellow }
function Err { param($m) Write-Host "[✖] $m" -ForegroundColor Red; exit 1 }

# Require admin
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Err "Please run this script as Administrator."
}

Log "=== Installing Home Assistant Shutdown Web Server (Windows) ==="

# Ensure TLS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Helper: install winget if missing
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Log "winget not found. Attempting to install App Installer (winget)..."
    try {
        $tmp = "$env:TEMP\AppInstaller.msixbundle"
        Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile $tmp -UseBasicParsing -ErrorAction Stop
        Add-AppxPackage -Path $tmp -ErrorAction Stop
        Remove-Item $tmp -ErrorAction SilentlyContinue
        Log "winget installed."
    } catch {
        Warn "Failed to install winget automatically. Please install winget manually and re-run this script."
    }
}

# Install Python using winget (if missing)
function Ensure-Python {
    if (Get-Command python -ErrorAction SilentlyContinue) {
        Log "Python already available: $(python --version 2>&1)"
        return
    }

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Err "winget is required to auto-install Python. Install winget first or install Python manually."
    }

    # Try common Python package ids; fall back to generic id
    $pythonCandidates = @(
        "Python.Python.3.12",    # if present
        "Python.Python.3.11",
        "Python.Python.3",
        "Python.Python"
    )

    $installed = $false
    foreach ($id in $pythonCandidates) {
        try {
            Log "Trying to install Python via winget id: $id"
            winget install --id $id --accept-package-agreements --accept-source-agreements -e -h
            Start-Sleep -Seconds 3
            if (Get-Command python -ErrorAction SilentlyContinue) { $installed = $true; break }
        } catch {
            Warn "winget install attempt for $id failed (will try next candidate)."
        }
    }

    if (-not $installed) {
        Warn "Automatic Python install failed via winget. Please install Python from https://www.python.org/ and re-run this script."
        Err "Python not installed."
    }

    # Ensure the new python is usable in this session
    $pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (-not $pythonPath) {
        Warn "python not found on PATH immediately after install. Attempting to read common install locations..."
        $possible = @(
            "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
            "$env:ProgramFiles\Python\python.exe",
            "$env:ProgramFiles(x86)\Python\python.exe"
        )
        foreach ($p in $possible) {
            if (Test-Path $p) {
                $pythonPath = $p
                break
            }
        }
    }

    if ($pythonPath) {
        Log "Python located at: $pythonPath"
    } else {
        Warn "Could not discover python executable path automatically. You may need to log out/in for PATH to refresh."
    }

    # Ensure pip is present
    try {
        & python -m pip --version
    } catch {
        Log "pip missing — attempting to bootstrap ensurepip..."
        try {
            & python -m ensurepip --upgrade
            & python -m pip install --upgrade pip
        } catch {
            Warn "Failed to ensure pip. You may need to install pip manually."
        }
    }
    Log "Python installed and pip available: $(python --version 2>&1)"
}

Ensure-Python

# Install Flask
Log "Installing Flask via pip..."
try {
    & python -m pip install --upgrade pip setuptools wheel
    & python -m pip install flask
    Log "Flask installed."
} catch {
    Err "Failed to install Flask using pip: $_"
}

# Copy shutdown_server.py to target folder
$targetDir = "C:\shutdown_server"
if (!(Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir | Out-Null
}
Copy-Item -Path (Join-Path $PSScriptRoot "shutdown_server.py") -Destination (Join-Path $targetDir "shutdown_server.py") -Force
Log "Copied shutdown_server.py to $targetDir"

# Add Firewall Rule
try {
    New-NetFirewallRule -DisplayName "Shutdown Server" -Direction Inbound -Protocol TCP -LocalPort 5050 -Action Allow -ErrorAction Stop
    Log "Firewall rule added for port 5050."
} catch {
    Warn "Could not add firewall rule (it may already exist): $_"
}

# Create hidden autostart (VBS + BAT) so server runs on login (user-level)
$batPath = Join-Path $targetDir "autostart_shutdown.bat"
$vbsPath = Join-Path $targetDir "launch_hidden.vbs"

$batContent = "@echo off`npython `"$targetDir\shutdown_server.py`""
Set-Content -Path $batPath -Value $batContent -Encoding ASCII

$vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run chr(34) & "$batPath" & chr(34), 0
Set WshShell = Nothing
"@
Set-Content -Path $vbsPath -Value $vbsContent -Encoding ASCII

# Place VBS into user's Startup folder (current user)
try {
    $startup = [Environment]::GetFolderPath('Startup')
    Copy-Item -Path $vbsPath -Destination (Join-Path $startup (Split-Path $vbsPath -Leaf)) -Force
    Log "Startup shortcut created for current user. Server will start after user login."
} catch {
    Warn "Failed to create autostart in Startup folder: $_"
}

# Alternatively, we can create a Windows Service (requires NSSM or sc.exe). For simplicity we use autostart here.

Log "✅ Shutdown Web Server installed. To test: curl -X POST http://<IP>:5050/shutdown"
