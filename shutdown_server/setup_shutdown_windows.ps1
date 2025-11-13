<#
setup_shutdown_windows.ps1 -- Sets up Flask shutdown web server on Windows
#>

Write-Host "=== Installing Home Assistant Shutdown Web Server (Windows) ==="

# Step 1: Ensure Python
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "[*] Python not found. Installing Python via Winget..."
    winget install -e --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements
}
Write-Host "[*] Python installation check..."
python --version

# Step 2: Install Flask
Write-Host "[*] Installing Flask..."
pip install flask

# Step 3: Copy shutdown_server.py
$targetDir = "C:\shutdown_server"
if (!(Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir | Out-Null }

Copy-Item "$PSScriptRoot\shutdown_server.py" "$targetDir\shutdown_server.py" -Force

# Step 4: Firewall rule
Write-Host "[*] Adding firewall rule for port 5050..."
New-NetFirewallRule -DisplayName "Shutdown Server" -Direction Inbound -Protocol TCP -LocalPort 5050 -Action Allow -ErrorAction SilentlyContinue

# Step 5: Optional autostart setup
Write-Host "[*] Creating autostart script..."
$batPath = "$targetDir\autostart_shutdown.bat"
$vbsPath = "$targetDir\launch_hidden.vbs"

"@echo off
python $targetDir\shutdown_server.py" | Out-File -Encoding ASCII $batPath

"Set WshShell = CreateObject(""WScript.Shell"")
WshShell.Run chr(34) & ""$batPath"" & chr(34), 0
Set WshShell = Nothing" | Out-File -Encoding ASCII $vbsPath

# Add to Windows Startup
$shellStartup = [Environment]::GetFolderPath('Startup')
Copy-Item $vbsPath "$shellStartup\launch_hidden.vbs" -Force

Write-Host "✅ Flask shutdown server installed. Will auto-start on login."
Write-Host "Test with: curl -X POST http://<IP>:5050/shutdown"
