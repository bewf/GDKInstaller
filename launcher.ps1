$url = "https://raw.githubusercontent.com/bewf/GDKInstaller/main/installer/bewf_GDK_Installer.ps1"

$temp = "$env:TEMP\bewf_GDK_Installer.ps1"

Invoke-WebRequest `
    -Uri $url `
    -OutFile $temp

Start-Process powershell `
    "-ExecutionPolicy Bypass -File `"$temp`"" `
    -Verb RunAs