# bootstrap_phase1.ps1
Write-Host "=== Phase 1: Preparing Windows ==="

# Ensure TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install Winget if missing
Write-Host "Checking for Winget..."
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Winget..."
    Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile "$env:TEMP\winget.msixbundle"
    Add-AppxPackage -Path "$env:TEMP\winget.msixbundle"
}

# Install Git if missing
Write-Host "Checking for Git..."
if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Git..."
    winget install --id Git.Git -e --source winget
}

# Install python if missing
Write-Host "Checking for Python..."
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Python..."
    winget install --id Python.Python.3.14 -e --source winget
}

# Update Windows
Write-Host "Updating Windows..."
Install-Module PSWindowsUpdate -Force -Confirm:$false
Import-Module PSWindowsUpdate
Get-WindowsUpdate -AcceptAll -Install -AutoReboot
