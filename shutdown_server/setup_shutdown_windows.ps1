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

# Ensure winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Log "winget not found. Attempting to install App Installer (winget)..."
    try {
        $tmp = "$env:TEMP\AppInstaller.msixbundle"
        Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile $tmp -UseBasicParsing -ErrorAction Stop
        Add-AppxPackage -Path $tmp -ErrorAction Stop
        Remove-Item $tmp -ErrorAction SilentlyContinue
        Log "winget installed."
    } catch {
        Warn "Failed to install winget automatically. Please install it manually, then re-run."
    }
}

# --- Install Python if missing ---
function Ensure-Python {
    if (Get-Command python -ErrorAction SilentlyContinue) {
        Log "Python found: $(python --version 2>&1)"
        return
    }

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Err "winget is required to install Python. Please install it first."
    }

    $ids = @("Python.Python.3.14", "Python.Python.3.12", "Python.Python.3")
    $installed = $false
    foreach ($id in $ids) {
        try {
            Log "Trying to install Python via winget id: $id"
            winget install --id $id --accept-package-agreements --accept-source-agreements -e -h
            Start-Sleep -Seconds 3
            if (Get-Command python -ErrorAction SilentlyContinue) { $installed = $true; break }
        } catch { Warn "Python install attempt for $id failed." }
    }

    if (-not $installed) { Err "Python install failed. Install manually and re-run." }

    try { python -m ensurepip --upgrade; python -m pip install --upgrade pip } catch { Warn "Could not upgrade pip." }
    Log "Python installed and pip ready: $(python --version 2>&1)"
}

Ensure-Python

# --- Install Flask ---
Log "Installing Flask via pip..."
try {
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install flask
} catch { Err "Failed to install Flask: $_" }
Log "Flask installed."

# --- Ensure target folder ---
Log "Setting up shutdown server directory..."
$targetDir = "C:\shutdown_server"
if (!(Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir | Out-Null
}

# --- Download shutdown_server.py ---
Log "Downloading shutdown_server.py..."

# Handle cases where the script is run via iex (no $PSScriptRoot)
if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $scriptTempDir = Join-Path $env:TEMP "shutdown_setup"
    if (!(Test-Path $scriptTempDir)) {
        New-Item -ItemType Directory -Path $scriptTempDir | Out-Null
    }
    $PSScriptRoot = $scriptTempDir
    Log "No script root detected (running from iex). Using temp path: $PSScriptRoot"
}

$localFile = Join-Path $PSScriptRoot "shutdown_server.py"

if (!(Test-Path $localFile)) {
    Log "shutdown_server.py not found locally — downloading from GitHub..."
    try {
        $repoUrl = "https://raw.githubusercontent.com/TravisPasta/Automated_Home_Theater_Setup/main/shutdown_server/shutdown_server.py"
        Invoke-WebRequest -Uri $repoUrl -OutFile $localFile -UseBasicParsing -ErrorAction Stop
        Log "Downloaded shutdown_server.py successfully."
    } catch {
        Err "Could not download shutdown_server.py from GitHub: $_"
    }
}


# --- Copy file into target dir ---
Log "Copying shutdown_server.py to $targetDir ..."
Copy-Item -Path $localFile -Destination (Join-Path $targetDir "shutdown_server.py") -Force
Log "Copied shutdown_server.py to $targetDir"

# --- Add Firewall Rule ---
try {
    New-NetFirewallRule -DisplayName "Shutdown Server" -Direction Inbound -Protocol TCP -LocalPort 5050 -Action Allow -ErrorAction Stop
    Log "Firewall rule added for port 5050."
} catch {
    Warn "Firewall rule might already exist: $_"
}

# --- Create Autostart ---
Log "Creating autostart entry..."
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

try {
    $startup = [Environment]::GetFolderPath('Startup')
    Copy-Item -Path $vbsPath -Destination (Join-Path $startup (Split-Path $vbsPath -Leaf)) -Force
    Log "Autostart added to startup folder."
} catch {
    Warn "Failed to add to startup folder: $_"
}

Log "✅ Setup complete! Test with: curl -X POST http://<PC_IP>:5050/shutdown"
