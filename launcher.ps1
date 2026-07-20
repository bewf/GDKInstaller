$installer = "$env:TEMP\bewfgdk_installer.ps1"

Invoke-WebRequest `
"https://raw.githubusercontent.com/bewf/GDKInstaller/main/installer/bewf_GDK_Installer.ps1" `
-OutFile $installer

powershell -ExecutionPolicy Bypass -File $installer