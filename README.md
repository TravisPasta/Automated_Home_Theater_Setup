
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
├── benchmark.ps1               # Windows setup script (benchmarking)
├── benchmark.sh                # Linux setup script (benchmarking)
│
├── Win11Debloater/
│   └── Get.ps1                 # Local fallback debloater
│
├── shutdown_server/
│   ├── setup_shutdown_linux.sh
│   ├── setup_shutdown_windows.ps1
│   └── shutdown_server.py
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

### Phase 3 (optional: Windows 11 debloat)

Run the Windows 11 Debloater script located in the `Win11Debloater` folder of this repository. If the script is not present, download the latest release from [here](https://github.com/Raphire/Win11Debloat/releases/latest).

Or use the powershell command for an automatic download and execution:

```powershell
& ([scriptblock]::Create((irm "https://debloat.raphi.re/")))
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


---

### 🔌 Home Assistant Remote Shutdown

This optional feature allows you to **shut down or restart your media PC** using a single **Home Assistant automation** or any HTTP client.

#### Linux Setup

```bash
curl -fsSL https://raw.githubusercontent.com/TravisPasta/Automated_Home_Theater_Setup/benchmark/shutdown_server/setup_shutdown_linux.sh | bash
```

This script:

* Installs Python + Flask
* Copies the Flask web server to `/opt/shutdown_server/`
* Creates a systemd service for auto-start
* Opens port 5050 in the firewall


---

#### Windows Setup

Open **PowerShell (Admin)** and run:

```powershell
irm https://raw.githubusercontent.com/TravisPasta/Automated_Home_Theater_Setup/benchmark/shutdown_server/setup_shutdown_windows.ps1 | iex
```

This script:

* Installs Python 3 (if not installed)
* Installs Flask
* Copies the shutdown script to `C:\shutdown_server\`
* Adds a firewall rule for port 5050
* Creates auto-start scripts for startup

--- 

✅ **Test the functionality on a different machine using:**

```shell
curl -X POST http://192.168.178.xxx:5050/shutdown
```

---

### 🏠 Home Assistant Integration Example

In Home Assistant, add a button or automation like:

```yaml
service: rest_command.shut_down_pc
data: {}
```

and define the command:

```yaml
rest_command:
  shut_down_pc:
    url: "http://192.168.178.xxx:5050/shutdown"
    method: POST
```

Now, pressing that button shuts down your HTPC instantly.
