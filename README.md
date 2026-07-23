# bewf GDK Installer

A simple automated installer for GDK games from OFME.

## Usage

### **Faster manual search**

Open your game's folder, right click background, select "Open in Terminal", and run:

```powershell
irm https://raw.githubusercontent.com/bewf/GDKInstaller/main/launcher-currentdir.ps1 | iex
```


### **Automatic search**

Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/bewf/GDKInstaller/main/launcher.ps1 | iex
```

## How it works

1. **Finds GDK games**
   - Automatically searches all drives for `AppxManifest.xml`
   - Uses the folder containing it as the GDK game location
   - Checks that the GDK package contains:
     - `wdapp.exe`
     - `AppxManifest.xml`
     - `MicrosoftGame.config`
   - If no game is found, lets the user manually pick a game folder
   - Supports installing directly from the current folder using the current directory launcher

2. **Checks requirements**
   - Checks for:
     - Windows Defender exclusions
     - Xbox App
     - Gaming Services
     - Xbox Game Bar
     - Microsoft.DirectXRuntime
   - Refreshes Microsoft Store Cache
   - If any requirements are missing, automatically fixes them with user permission

3. **Installs the game**
   - Enables Developer Mode temporarily
   - Registers the GDK package using `wdapp.exe`
   - Installs missing DirectX Runtime if error `0x80073CF3` occurs
   - Installs DLC if available
   - Disables Developer Mode when finished



## What this fixes and what it doesn't

### Fixed automatically


- `0x80073CF3` during installation
- Failed to load `xgameruntime.dll`
- Missing Xbox components
  - Installs:
    - Xbox App
    - Gaming Services
    - Xbox Game Bar
- Microsoft Store cache issues
- Adds a Windows Defender exclusion

### Not fixed automatically

These issues need to be manually fixed:
- "Unable to Verify Game Ownership" popup
- Xbox credential/login issues
- Xbox App Gaming Services Repair Tool issues

## Credits

Special thanks to:

* **Kelevra**: Finding a good UWP DirectX Runtime installer
* **StaySharp**: Troubleshooting info and keeping me informed
* **bewf (me)**: Writing the thing