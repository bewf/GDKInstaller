# =====================================================
# bewf GDK Installer
# =====================================================

param(
    [switch]$UseCurrentDirectory,
    [string]$ContextFile
)

$ErrorActionPreference = "SilentlyContinue"

function Get-LaunchContext($file) {

    if (Test-Path $file) {

        $json = Get-Content $file -Raw | ConvertFrom-Json

        return $json.GamePath

    }

    return $null
}
function Save-LaunchContext($path) {

    $context = @{
        GamePath = $path
    }

    $contextFile = "$env:TEMP\bewfgdk_context.json"

    $context | ConvertTo-Json | Out-File $contextFile -Encoding UTF8

    return $contextFile
}

# Relaunch as Administrator if needed
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

$currentPath = (Get-Location).Path

$launchArgs = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""

if ($UseCurrentDirectory) {

    $contextFile = Save-LaunchContext $currentPath

    $launchArgs += " -UseCurrentDirectory"
    $launchArgs += " -ContextFile `"$contextFile`""

}

Start-Process powershell `
-ArgumentList $launchArgs `
-Verb RunAs

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


$githubRelease = "https://github.com/bewf/GDKInstaller/releases/download/v1.0"

# --------------------------
# Functions
# --------------------------


function Test-GDKFolder($path) {

    $gdkIndicators = @(
        "wdapp.exe",
        "GDK_Helper.bat",
        "gdk_helper.exe",
        "MicrosoftGame.config",
        "AppxManifest.xml",
        "appxmanifest.xml"
    )

    foreach ($file in $gdkIndicators) {

        if (Test-Path (Join-Path $path $file)) {
            return $true
        }

    }

    return $false

}
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
        "https://github.com/bewf/GDKInstaller/releases/download/v1.0/UWPdx.appx" `
        -OutFile $dxInstallerPath

    }


    if (!(Test-Path $dxInstallerPath) -or (Get-Item $dxInstallerPath).Length -lt 50000000) {

        Write-Host ""
        Write-Host "Download failed. Invalid DirectX Runtime file." -ForegroundColor Red
        Write-Host ""
        Write-Host "You can manually download it here:"
        Write-Host "https://github.com/bewf/GDKInstaller/releases/download/v1.0/UWPdx.appx"
        Write-Host ""

        Remove-Item $dxInstallerPath -Force -ErrorAction SilentlyContinue

        return $false

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

        if (
        $path.TrimEnd('\').StartsWith($exclusion.TrimEnd('\') + '\') -or
        $path.TrimEnd('\') -eq $exclusion.TrimEnd('\')
    ) {

            return $true

        }

    }


    return $false

}



function Add-GameExclusion($path) {

    try {

        $exclusionPath = $path

        $parent = Split-Path $path -Parent

        # Never exclude drive roots
        $parentRoot = [System.IO.Path]::GetPathRoot($parent)

        # Common Windows/user folders that should never be excluded
        $blockedFolders = @(
            "Desktop",
            "Downloads",
            "Documents",
            "Pictures",
            "Videos",
            "Music",
            "OneDrive",
            "Windows",
            "Program Files",
            "Program Files (x86)",
            "Users",
            "Public",
            "AppData"
        )

        $parentName = Split-Path $parent -Leaf

        if (
            $parent -ne $parentRoot -and
            !($blockedFolders -contains $parentName) -and
            $null -ne (Split-Path $parent -Parent)
        ) {

            $exclusionPath = $parent

        }


        Add-MpPreference -ExclusionPath $exclusionPath

        Write-Host "Defender exclusion added:"
        Write-Host $exclusionPath

        return $true

    }
    catch {

        return $false

    }

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

function Test-XboxGameBar {

    $gameBar = Get-AppxPackage `
        -Name "Microsoft.XboxGamingOverlay" `
        -ErrorAction SilentlyContinue

    return ($null -ne $gameBar)

}

function Install-XboxGameBar {

    Start-Process "ms-windows-store://pdp/?productid=9NZKPSTSNW4P"

}


function Install-XboxApp {

    if (!(Test-Path $xboxInstallerPath)) {

        Write-Host "Downloading Xbox Installer..."

Invoke-WebRequest `
https://github.com/bewf/GDKInstaller/releases/download/v1.0/XboxInstaller.exe `
-OutFile $xboxInstallerPath

if (!(Test-Path $xboxInstallerPath) -or (Get-Item $xboxInstallerPath).Length -lt 10000000) {

    Write-Host ""
    Write-Host "Download failed. Invalid Xbox Installer file." -ForegroundColor Red
    Write-Host ""
    Write-Host "You can manually download it here:"
    Write-Host "https://github.com/bewf/GDKInstaller/releases/download/v1.0/XboxInstaller.exe"
    Write-Host ""

    Remove-Item $xboxInstallerPath -Force

    return $false

}

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

if ($UseCurrentDirectory) {

    $gamePath = Get-LaunchContext $ContextFile

    if (!$gamePath) {
        $gamePath = (Get-Location).Path
    }

    $game = @{
        Name = Split-Path $gamePath -Leaf
        Path = $gamePath
    }

    if (!(Test-GDKFolder $game.Path)) {

        Write-Host ""
        Write-Host "The current folder is not a valid GDK game." -ForegroundColor Red
        Pause
        exit

    }

}

else {

    Write-Host "Searching for GDK games..."
Write-Host "This may take a minute depending on drive speed."
Write-Host ""

$games = @()

$searchPaths = @()

# Priority folders
$searchPaths += "$env:USERPROFILE\Downloads"
$searchPaths += "$env:USERPROFILE\Desktop"

# Check common game folders directly on each drive
foreach ($drive in (Get-PSDrive -PSProvider FileSystem)) {

    foreach ($folder in @("Games", "Game")) {

        $possiblePath = Join-Path $drive.Root $folder

        if (Test-Path $possiblePath) {

            $searchPaths += $possiblePath

        }

    }

}

# Search all drives
foreach ($drive in (Get-PSDrive -PSProvider FileSystem)) {

    $searchPaths += $drive.Root

}


$searchPaths = $searchPaths | Select-Object -Unique


$foundPaths = @{}
$stopSearch = $false
$rejectedGames = $false

foreach ($path in $searchPaths) {

    if ($stopSearch) {
        break
    }

    if (!(Test-Path $path)) {
        continue
    }

    try {

$searchJob = Start-Job -ArgumentList $path {

    param($scanPath)

    Get-ChildItem $scanPath `
    -Filter "AppxManifest.xml" `
    -File `
    -Recurse `
    -Force |
    ForEach-Object {

        $dir = $_.DirectoryName

        $gdkIndicators = @(
            "wdapp.exe",
            "GDK_Helper.bat",
            "gdk_helper.exe",
            "MicrosoftGame.config",
            "AppxManifest.xml",
            "appxmanifest.xml"
        )

        foreach ($file in $gdkIndicators) {

            if (Test-Path (Join-Path $dir $file)) {
                $dir
                break
            }

        }

    }

}

        $time = 0

        while ($searchJob.State -eq "Running") {

            Start-Sleep -Milliseconds 500
            $time += 500

            if ($time -ge 69420) {

                Stop-Job $searchJob -ErrorAction SilentlyContinue
                Remove-Job $searchJob -Force -ErrorAction SilentlyContinue
                $searchJob = $null
                break

            }

        }


        if ($searchJob -and $searchJob.State -eq "Completed") {

            $results = Receive-Job $searchJob

            $foundAny = $false

            foreach ($gamePath in $results) {

                if (!$foundPaths.ContainsKey($gamePath)) {

                    $foundPaths[$gamePath] = $true

                    Write-Host ""
                    Write-Host "Found: $gamePath" -ForegroundColor Green

                    $games += [PSCustomObject]@{
                        Name = Split-Path $gamePath -Leaf
                        Path = $gamePath
                    }

                    $foundAny = $true
                }
            }


            if ($foundAny) {

                Start-Sleep -Seconds 2

                $answer = Read-Host "Is this the game you want to install? (Y/n)"

                if ($answer -eq "" -or $answer -match "^[Yy]$") {

                    $game = [PSCustomObject]@{
                        Name = Split-Path $gamePath -Leaf
                        Path = $gamePath
                    }

                    $stopSearch = $true
                    break

                }

                else {

                    $rejectedGames = $true

                    Write-Host "Continuing search..."

                }


            }


            Remove-Job $searchJob -Force -ErrorAction SilentlyContinue

        }

    }
    catch {

        Remove-Job $searchJob -Force -ErrorAction SilentlyContinue

    }

}

if ($null -eq $game -and ($games.Count -eq 0 -or $rejectedGames)) {

    if ($games.Count -eq 0) {
        Write-Host "No GDK games found." -ForegroundColor Red
    }
    else {
        Write-Host "No selected games. You can choose manually." -ForegroundColor Yellow
    }

    Write-Host ""

    $manual = Read-Host "Would you like to select the game folder manually? (Y/n)"

    if ($manual -eq "" -or $manual -match '^[Yy]$') {

        Add-Type -AssemblyName System.Windows.Forms

        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Select your GDK game folder"

        if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            exit
        }

        $game = @{
            Name = Split-Path $dialog.SelectedPath -Leaf
            Path = $dialog.SelectedPath
        }
    if (
        !(Test-Path (Join-Path $game.Path "wdapp.exe")) -or
        !(Test-Path (Join-Path $game.Path "AppxManifest.xml"))
    ) {

    Write-Host ""
    Write-Host "The selected folder is not a valid GDK game." -ForegroundColor Red
    Pause
    exit

}

    }
    else {

        exit

    }

}

elseif ($null -eq $game) {

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

}

}
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





# Defender exclusion

if (Test-DefenderExclusion $game.Path) {

    Write-Host "[OK] Windows Defender exclusion exists" -ForegroundColor Green

}
else {

    Write-Host ""
    Write-Host "[WARN] No Windows Defender exclusion found." -ForegroundColor Yellow


    $answer = Read-Host `
    "Add an exclusion for this game folder? (Y/n)"


    if ($answer -eq "" -or $answer -match "^[Yy]$") {

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

    $answer = Read-Host "Install Xbox App now? (Y/n)"

    if ($answer -eq "" -or $answer -match "^[Yy]$") {

    if (!(Install-XboxApp)) {

        Write-Host ""
        Write-Host "Xbox App installation skipped due to download failure." -ForegroundColor Yellow

    }

}

}



if (Test-GamingServices) {

    Write-Host "[OK] Gaming Services installed" -ForegroundColor Green

}
else {

    Write-Host "[WARN] Gaming Services missing" -ForegroundColor Yellow

    $answer = Read-Host "Open Gaming Services installer? (Y/n)"

    if ($answer -eq "" -or $answer -match "^[Yy]$") {

        Open-GamingServices

        Write-Host ""
        Read-Host "Install Gaming Services, then press Enter to continue"

        if (Test-GamingServices) {

            Write-Host "[OK] Gaming Services installed" -ForegroundColor Green

        }
        else {

            Write-Host "[WARN] Gaming Services is still not installed." -ForegroundColor Yellow

        }

    }

}

if (Test-XboxGameBar) {

    Write-Host "[OK] Xbox Game Bar installed" -ForegroundColor Green

}
else {

    Write-Host "[WARN] Xbox Game Bar missing" -ForegroundColor Yellow

    $answer = Read-Host "Open Xbox Game Bar installer? (Y/n)"

    if ($answer -eq "" -or $answer -match "^[Yy]$") {

        Install-XboxGameBar

    }

}

if (Test-DirectXRuntime) {

    Write-Host "[OK] DirectX Runtime installed" -ForegroundColor Green

}
else {

    Write-Host "[WARN] DirectX Runtime missing" -ForegroundColor Yellow

    $answer = Read-Host "Install UWP DirectX Runtime now? (Y/n)"

    if ($answer -eq "" -or $answer -match "^[Yy]$") {

        Install-DirectXRuntime

    }

}

Write-Host "CACHE TEST START"

Write-Host ""

Write-Host "Clearing Microsoft Store cache..."

$storePackage = Get-AppxPackage -Name Microsoft.WindowsStore

if ($storePackage) {

    $storeName = $storePackage.PackageFamilyName

    $storeCache = "$env:LOCALAPPDATA\Packages\$storeName\LocalCache"

    if (Test-Path $storeCache) {

        Remove-Item "$storeCache\*" -Recurse -Force -ErrorAction SilentlyContinue

    }

}

Write-Host "CACHE TEST END"

Write-Host "Done."

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
        "Continue and reinstall? (Y/n)"


        if (!($reinstall -eq "" -or $reinstall -match "^[Yy]$")) {

            $again = Read-Host "Would you like to install another game? (Y/n)"

            if ($again -eq "" -or $again -match "^[Yy]$") {

                $launchArgs = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""

                if ($UseCurrentDirectory) {
                    $launchArgs += " -UseCurrentDirectory"
                }

                Start-Process powershell `
                -ArgumentList $launchArgs `
                -Verb RunAs `
                -WorkingDirectory (Get-Location).Path
            }

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

$again = Read-Host "Would you like to install another game? (Y/n)"

if ($again -eq "" -or $again -match "^[Yy]$") {

    $launchArgs = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""

    if ($UseCurrentDirectory) {

        $contextFile = Save-LaunchContext $game.Path

        $launchArgs += " -UseCurrentDirectory"
        $launchArgs += " -ContextFile `"$contextFile`""

    }

    Start-Process powershell `
    -ArgumentList $launchArgs `
    -Verb RunAs

}

exit

