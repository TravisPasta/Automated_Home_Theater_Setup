
# Automated Home Theater Setup

This repository sets up a **home theater PC** (Windows or Linux) with all essential media applications, SSH access, and Wake-on-LAN support — completely automatically.

---

## 🗂 Repository structure

```
Automated_Home_Theater_Setup/
│
├── bootstrap.sh                # Linux setup script
├── bootstrap.ps1               # Windows setup script (main logic)
├── bootstrap_phase1.ps1        # Windows setup phase 1 (installs Git, Winget, updates)
│
├── Win11Debloater/
│   └── Get.ps1                 # Local fallback debloater
│
└── README.md                   # Full usage guide
```
---

## 🧩 Features

### ✅ Universal
Works on:
- **Windows 11** (PowerShell)
- **Ubuntu / Debian (APT)** or **Fedora (DNF)** Linux distributions

### 🎬 Software installed
| Type | Software |
|------|-----------|
| Media | Jellyfin Media Player, VLC, Plex (manual download) |
| Tools | Git, Firefox, SSH Server |
| System | Wake-on-LAN enabled |
| Linux-only | Tilix, ddcutil, Extension Manager |
| Windows-only | Twinkle Tray, Windows 11 Debloater, Winget |

---

## 🪟 Windows Usage

### Phase 1 (prepare system)
Run **PowerShell as Administrator**:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
irm https://raw.githubusercontent.com/TravisPasta/Automated_Home_Theater_Setup/main/bootstrap_phase1.ps1 | iex
````

Reboot, then continue with Phase 2.

### Phase 2 (install everything)

```powershell
irm https://raw.githubusercontent.com/TravisPasta/Automated_Home_Theater_Setup/main/bootstrap.ps1 | iex
```

---

## 🐧 Linux Usage

```bash
curl -fsSL https://raw.githubusercontent.com/TravisPasta/Automated_Home_Theater_Setup/main/bootstrap.sh | bash
```

---

## 🧠 Notes

* **Wake-on-LAN** uses NetworkManager’s built-in feature.
* **Jellyfin Media Player** auto-starts on login.
* If Plex cannot be installed automatically, Firefox opens the official download page.
* Windows 11 debloater automatically downloads the latest release if possible.
