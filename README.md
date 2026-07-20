# bewf GDK Installer

A simple automated installer for GDK games from OFME.



## How it works

1. **Finds GDK games**
   - Searches all drives for `GDK_Helper.bat`
   - Uses the folder containing it as the GDK game location
   - Checks that the GDK package contains:
     - `wdapp.exe`
     - `AppxManifest.xml`
   - Says if the game contains:
     - `OnlineFix64.dll`

2. **Checks requirements**
   - Checks for:
     - Windows Defender exclusions
     - Xbox App
     - Gaming Services
     - Microsoft.DirectXRuntime

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