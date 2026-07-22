# bewf GDK Installer

A simple automated installer for GDK games from OFME.



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
     - Microsoft.DirectXRuntime
   - If any requirements are missing, automatically fixes them with user permission

3. **Installs the game**
   - Enables Developer Mode temporarily
   - Registers the GDK package using `wdapp.exe`
   - Installs missing DirectX Runtime if error `0x80073CF3` occurs
   - Installs DLC if available
   - Disables Developer Mode when finished



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