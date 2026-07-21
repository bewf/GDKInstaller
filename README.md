# bewf GDK Installer

A simple automated installer for GDK games from OFME.



## How it works

1. **Finds GDK games**
   - Searches all drives for `AppxManifest.xml`
   - Uses the folder containing it as the GDK game location
   - Checks that the GDK package contains:
     - `wdapp.exe`
     - `AppxManifest.xml`
     - `MicrosoftGame.config`
   - If it can't find a game automatically, lets the user pick one manually

2. **Checks requirements**
   - Checks for:
     - Windows Defender exclusions
     - Xbox App
     - Gaming Services
     - Microsoft.DirectXRuntime
   - If any requirements are missing, automatically fixes it with user permission

3. **Installs the game**
   - Enables Developer Mode temporarily
   - Registers the GDK package using `wdapp.exe`
   - Installs missing DirectX Runtime if error `0x80073CF3` occurs
   - Installs DLC if possible
   - Disables Developer Mode when finished
 


## Usage

Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/bewf/GDKInstaller/main/launcher.ps1 | iex 
```

## Credits
Special thanks to:
- **Kelevra**: Finding a good UWP DirectX Runtime installer
- **StaySharp**: Troubleshooting info and keeping me informed
- **bewf (me)**: Writing the thing