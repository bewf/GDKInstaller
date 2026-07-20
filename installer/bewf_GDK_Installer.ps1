# =====================================================
# bewf GDK Installer
# =====================================================

$ErrorActionPreference = "SilentlyContinue"

# Relaunch as Administrator if needed
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Clear-Host
# --------------------------
# Download paths
# --------------------------

$downloadFolder = "$env:TEMP\bewfgdk"

if (!(Test-Path $downloadFolder)) {

    New-Item `
    -Path $downloadFolder `
    -ItemType Directory | Out-Null

}


$dxInstallerPath = "$downloadFolder\UWPdx.appx"
$xboxInstallerPath = "$downloadFolder\XboxInstaller.exe"


$githubRelease = "https://github.com/bewf/GDKInstaller/releases/latest/download/"

# --------------------------
# Functions
# --------------------------


function Test-DirectXRuntime {

    $dx = Get-AppxPackage -Name "Microsoft.DirectX*" 

    return ($null -ne $dx)

}


function Install-DirectXRuntime {

    Write-Host ""
    Write-Host "Missing Microsoft.DirectXRuntime." -ForegroundColor Yellow

    if (!(Test-Path $dxInstallerPath)) {

        Write-Host "Downloading UWP DirectX Runtime..."

        Invoke-WebRequest `
        "$githubRelease/UWPdx.appx" `
        -OutFile $dxInstallerPath

    }


    Write-Host "Installing UWP DirectX Runtime..."

    Add-AppxPackage $dxInstallerPath


    Start-Sleep -Seconds 5


    if (Test-DirectXRuntime) {

        Write-Host "DirectX Runtime installed successfully." -ForegroundColor Green
        return $true

    }
    else {

        Write-Host "DirectX Runtime installation failed." -ForegroundColor Red
        return $false

    }

}


function Test-DefenderExclusion($path) {

    $exclusions = (Get-MpPreference).ExclusionPath


    foreach ($exclusion in $exclusions) {

        if ($path.StartsWith($exclusion)) {

            return $true

        }

    }


    return $false

}



function Add-GameExclusion($path) {

    try {

        Add-MpPreference -ExclusionPath $path

        return $true

    }
    catch {

        return $false

    }

}



function Test-OnlineFix($path) {

    $file = Get-ChildItem `
        -Path $path `
        -Filter "OnlineFix64.dll" `
        -Recurse `
        -ErrorAction SilentlyContinue


    return ($null -ne $file)

}



function Test-GamingServices {

    $service = Get-AppxPackage `
        -Name "Microsoft.GamingServices" `
        -ErrorAction SilentlyContinue


    return ($null -ne $service)

}



function Test-XboxApp {

    $xbox = Get-AppxPackage `
        -Name "Microsoft.GamingApp" `
        -ErrorAction SilentlyContinue


    return ($null -ne $xbox)

}


function Install-XboxApp {

    if (!(Test-Path $xboxInstallerPath)) {

        Write-Host "Downloading Xbox Installer..."

        Invoke-WebRequest `
        "$githubRelease/XboxInstaller.exe" `
        -OutFile $xboxInstallerPath

    }


    Write-Host "Installing Xbox App..."

    Start-Process $xboxInstallerPath -Wait


    return $true

}


function Open-GamingServices {

    Start-Process "ms-windows-store://pdp/?productid=9MWPM2CQNLHN"

}


function Install-Game {

    Write-Host ""
    Write-Host "Running wdapp..."


    $output = & ".\wdapp.exe" register ".\AppxManifest.xml" 2>&1


    foreach ($line in $output) {

        Write-Host $line

    }



    if (($output -join "`n") -match "0x80073CF3") {

        Write-Host ""
        Write-Host "Detected error 0x80073CF3" -ForegroundColor Red


        if (Install-DirectXRuntime) {

            Write-Host ""
            Write-Host "Retrying installation..."


            $retry = & ".\wdapp.exe" register ".\AppxManifest.xml" 2>&1


            foreach ($line in $retry) {

                Write-Host $line

            }


            if (($retry -join "`n") -match "0x800") {

                return $false

            }


            return $true

        }


        return $false

    }



    if (($output -join "`n") -match "Failed") {

        return $false

    }


    return $true

}


# --------------------------
# Header
# --------------------------

Write-Host ""
Write-Host "===================================" -ForegroundColor Green
Write-Host "     bewf GDK Installer"
Write-Host "===================================" -ForegroundColor Green
Write-Host ""


# --------------------------
# Search
# --------------------------

Write-Host "Searching for GDK games..."
Write-Host "This may take a minute depending on drive speed."
Write-Host ""


$drives = Get-PSDrive -PSProvider FileSystem

$games = @()


foreach ($drive in $drives) {

    try {

        Get-ChildItem $drive.Root `
            -Filter "GDK_Helper.bat" `
            -File `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue |

        ForEach-Object {

            $games += [PSCustomObject]@{
                Name = Split-Path $_.DirectoryName -Leaf
                Path = $_.DirectoryName
            }

        }

    }
    catch {}

}


if ($games.Count -eq 0) {

    Write-Host "No GDK games found." -ForegroundColor Red
    Pause
    exit

}



Write-Host "Found $($games.Count) game(s)."
Write-Host ""


for ($i = 0; $i -lt $games.Count; $i++) {

    Write-Host "$($i + 1). $($games[$i].Name)"

}


Write-Host ""


do {

    $choice = Read-Host "Choose a game"

}
until ($choice -match '^\d+$' -and $choice -ge 1 -and $choice -le $games.Count)



$game = $games[$choice - 1]


Set-Location $game.Path



Write-Host ""
Write-Host "Selected:"
Write-Host $game.Path
Write-Host ""



# --------------------------
# Requirement Checks
# --------------------------

Write-Host "Checking requirements..."
Write-Host ""


# OnlineFix check

if (Test-OnlineFix $game.Path) {

    Write-Host "[OK] OnlineFix64.dll detected" -ForegroundColor Green

}
else {

    Write-Host "[INFO] OnlineFix64.dll not found"

}




# Defender exclusion

if (Test-DefenderExclusion $game.Path) {

    Write-Host "[OK] Windows Defender exclusion exists" -ForegroundColor Green

}
else {

    Write-Host ""
    Write-Host "[WARN] No Windows Defender exclusion found." -ForegroundColor Yellow


    $answer = Read-Host `
    "Add an exclusion for this game folder? (Y/N)"


    if ($answer -eq "Y") {

        if (Add-GameExclusion $game.Path) {

            Write-Host ""
            Write-Host "Exclusion added successfully." -ForegroundColor Green

            Write-Host ""
            Write-Host "IMPORTANT:"
            Write-Host "If files were removed by antivirus,"
            Write-Host "delete the game and extract it again."
            Write-Host "Existing missing files cannot be restored."

        }
        else {

            Write-Host "Failed to add exclusion." -ForegroundColor Red

        }

    }

}



# Xbox checks

if (Test-XboxApp) {

    Write-Host "[OK] Xbox App installed" -ForegroundColor Green

}
else {

    Write-Host "[WARN] Xbox App missing" -ForegroundColor Yellow

    $answer = Read-Host "Install Xbox App now? (Y/N)"

    if ($answer -eq "Y") {

        Install-XboxApp

    }

}



if (Test-GamingServices) {

    Write-Host "[OK] Gaming Services installed" -ForegroundColor Green

}
else {

    Write-Host "[WARN] Gaming Services missing" -ForegroundColor Yellow

    $answer = Read-Host "Open Gaming Services installer? (Y/N)"

    if ($answer -eq "Y") {

        Open-GamingServices

    }

}



if (Test-DirectXRuntime) {

    Write-Host "[OK] DirectX Runtime installed" -ForegroundColor Green

}
else {

    Write-Host "[WARN] DirectX Runtime missing" -ForegroundColor Yellow

    $answer = Read-Host "Install UWP DirectX Runtime now? (Y/N)"

    if ($answer -eq "Y") {

        Install-DirectXRuntime

    }

}



Write-Host ""



# --------------------------
# Existing Install Check
# --------------------------

$identity = Select-String `
    -Path ".\AppxManifest.xml" `
    -Pattern 'Identity Name="([^"]+)"' |
    Select-Object -First 1


if ($identity) {

    $packageName = $identity.Matches.Groups[1].Value


    $installed = Get-AppxPackage -Name $packageName -ErrorAction SilentlyContinue


    if ($installed) {

        Write-Host ""
        Write-Host "Existing installation detected." -ForegroundColor Yellow


        $reinstall = Read-Host `
        "Continue and reinstall? (Y/N)"


        if ($reinstall -ne "Y") {

            Write-Host "Cancelled."
            Pause
            exit

        }

    }

}



# --------------------------
# Validate Files
# --------------------------

$installSuccess = $true


if (!(Test-Path ".\wdapp.exe")) {

    Write-Host "ERROR: wdapp.exe missing." -ForegroundColor Red
    $installSuccess = $false

}



if (!(Test-Path ".\AppxManifest.xml")) {

    Write-Host "ERROR: AppxManifest.xml missing." -ForegroundColor Red
    $installSuccess = $false

}



if (!$installSuccess) {

    Pause
    exit

}



# --------------------------
# Enable Developer Mode
# --------------------------

Write-Host ""
Write-Host "[1/4] Enabling Developer Mode..."


reg add `
"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" `
/v AllowDevelopmentWithoutDevLicense `
/t REG_DWORD `
/d 1 `
/f | Out-Null


Write-Host "Done."



# --------------------------
# Rename Signature
# --------------------------

if (Test-Path ".\AppxSignature.p7x") {

    Rename-Item `
    ".\AppxSignature.p7x" `
    "AppxSignature.tmp" `
    -Force

}



# --------------------------
# Install Game
# --------------------------

Write-Host ""
Write-Host "[2/4] Installing Game..."


if (!(Install-Game)) {

    Write-Host ""
    Write-Host "Game installation failed." -ForegroundColor Red
    $installSuccess = $false

}
else {

    Write-Host "Game installed successfully." -ForegroundColor Green

}



# --------------------------
# DLC
# --------------------------

Write-Host ""
Write-Host "[3/4] Installing DLC..."


$dlcFolder = ".\MicrosoftStore_DLC"


if (Test-Path $dlcFolder) {

    Get-ChildItem $dlcFolder -Directory | ForEach-Object {

        & ".\wdapp.exe" register $_.FullName

    }

    Write-Host "DLC installed."

}
else {

    Write-Host "No DLC folder found. Skipping."

}



# --------------------------
# Disable Developer Mode
# --------------------------

Write-Host ""
Write-Host "[4/4] Disabling Developer Mode..."


reg add `
"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" `
/v AllowDevelopmentWithoutDevLicense `
/t REG_DWORD `
/d 0 `
/f | Out-Null


Write-Host "Done."



# --------------------------
# Result
# --------------------------

Write-Host ""
Write-Host "==================================="


if ($installSuccess) {

    Write-Host "Installation Complete!" -ForegroundColor Green
    Write-Host "Launch the game from the Start Menu."

}
else {

    Write-Host "Installation Failed." -ForegroundColor Red
    Write-Host "Review the errors above."

}


Write-Host "==================================="

Pause

