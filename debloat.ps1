#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows debloat script - removes bloatware, disables telemetry, tweaks privacy & performance.
.DESCRIPTION
    Inspired by Raphire/Win11Debloat. Removes OEM/Microsoft bloatware via Appx & WinGet,
    applies registry tweaks, and optimizes power settings.
.PARAMETER RemoveApps
    Remove the default list of bloatware apps.
.PARAMETER DisableTelemetry
    Disable telemetry, tracking, and data collection.
.PARAMETER DisableBing
    Disable Bing web search and Cortana integration.
.PARAMETER DisableStartAds
    Disable recommendations/ads in Start menu.
.PARAMETER HighPerformance
    Set power plan to High Performance.
.PARAMETER Silent
    Suppress prompts and run non-interactively.
.PARAMETER RestorePoint
    Create a system restore point before making changes.
.EXAMPLE
    .\debloat.ps1 -RemoveApps -DisableTelemetry -HighPerformance
.EXAMPLE
    .\debloat.ps1 -Silent -RemoveApps -DisableTelemetry -DisableBing -DisableStartAds -HighPerformance -RestorePoint
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$RemoveApps,
    [switch]$DisableTelemetry,
    [switch]$DisableBing,
    [switch]$DisableStartAds,
    [switch]$HighPerformance,
    [switch]$Silent,
    [switch]$RestorePoint
)

$scriptDir = $PSScriptRoot
$regDir = Join-Path $scriptDir "regfiles"
$configDir = Join-Path $scriptDir "config"

function Write-Step {
    param([string]$Text)
    Write-Host "[*] $Text" -ForegroundColor Yellow
}

function Write-Ok {
    param([string]$Text)
    Write-Host "  [+] $Text" -ForegroundColor Green
}

function Write-Skip {
    param([string]$Text)
    Write-Host "  [-] $Text" -ForegroundColor DarkGray
}

function Write-ErrorMsg {
    param([string]$Text)
    Write-Host "  [!] $Text" -ForegroundColor Red
}

function Import-RegFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        Write-Skip "Registry file not found: $Path"
        return
    }
    try {
        $result = reg.exe import "`"$Path`"" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Ok (Split-Path $Path -Leaf)
        } else {
            Write-ErrorMsg "Failed to import $(Split-Path $Path -Leaf): $result"
        }
    } catch {
        Write-ErrorMsg "Error importing $(Split-Path $Path -Leaf): $_"
    }
}

function New-RestorePoint {
    if (-not $RestorePoint) { return }
    Write-Step "Creating system restore point..."
    try {
        Checkpoint-Computer -Description "Win-Debloat $(Get-Date -Format yyyy-MM-dd)" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Ok "Restore point created"
    } catch {
        Write-ErrorMsg "Could not create restore point (may need to enable System Protection first): $_"
    }
}

function Remove-BloatwareApps {
    Write-Step "Removing bloatware apps..."

    $bloatAppx = @(
        "Microsoft.BingNews", "Microsoft.BingWeather", "Microsoft.GamingApp",
        "Microsoft.GetHelp", "Microsoft.Getstarted", "Microsoft.Messaging",
        "Microsoft.Microsoft3DViewer", "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection", "Microsoft.MixedReality.Portal",
        "Microsoft.Office.OneNote", "Microsoft.OneConnect", "Microsoft.People",
        "Microsoft.PowerAutomateDesktop", "Microsoft.SkypeApp",
        "Microsoft.Todos", "Microsoft.WindowsAlarms", "Microsoft.WindowsCamera",
        "Microsoft.WindowsFeedbackHub", "Microsoft.WindowsMaps",
        "Microsoft.WindowsSoundRecorder", "Microsoft.Xbox.TCUI",
        "Microsoft.XboxGameCallableUI", "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider", "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.YourPhone", "Microsoft.ZuneMusic", "Microsoft.ZuneVideo",
        "Clipchamp.Clipchamp", "Microsoft.Copilot", "Microsoft.BingSearch"
    )

    $bloatWinget = @(
        "*Acer*", "*McAfee*", "*Booking*", "*Adobe*"
    )

    $count = 0
    foreach ($pkg in (Get-AppxPackage -AllUsers $bloatAppx -ErrorAction SilentlyContinue)) {
        try {
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop -Confirm:$false
            $count++
        } catch {
            Write-Skip "Could not remove $($pkg.Name): $_"
        }
    }
    foreach ($pkg in (Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match ($bloatAppx -join "|") })) {
        try {
            Remove-AppxProvisionedPackage -PackageName $pkg.PackageName -Online -ErrorAction Stop -Confirm:$false
        } catch {}
    }
    Write-Ok "Removed $count Appx packages"

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        foreach ($pattern in $bloatWinget) {
            $apps = winget list --name $pattern --accept-source-agreements 2>$null
            if ($apps -match $pattern) {
                try {
                    winget uninstall --name $pattern --silent --accept-source-agreements 2>$null | Out-Null
                    Write-Ok "Uninstalled: $pattern"
                } catch {}
            }
        }
    }
}

function Invoke-TelemetryDisable {
    Write-Step "Disabling telemetry..."
    Get-ChildItem "$regDir\telemetry\*.reg" -ErrorAction SilentlyContinue | ForEach-Object { Import-RegFile $_.FullName }
}

function Invoke-BingDisable {
    Write-Step "Disabling Bing web search..."
    Get-ChildItem "$regDir\bing\*.reg" -ErrorAction SilentlyContinue | ForEach-Object { Import-RegFile $_.FullName }
}

function Invoke-StartAdsDisable {
    Write-Step "Disabling Start menu ads..."
    Get-ChildItem "$regDir\start\*.reg" -ErrorAction SilentlyContinue | ForEach-Object { Import-RegFile $_.FullName }
}

function Set-HighPerformancePlan {
    Write-Step "Setting power plan to High Performance..."
    $guid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    try {
        powercfg -setactive $guid 2>$null
        Write-Ok "High Performance plan activated"
    } catch {
        Write-ErrorMsg "Could not set power plan (try: powercfg -duplicatescheme $guid first)"
    }
}

# --- MAIN ---
Clear-Host
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "     Windows Debloat Script    " -ForegroundColor Cyan
Write-Host "     Inspired by Win11Debloat  " -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
""

if (-not $Silent) {
    Write-Host "This script will modify system settings and remove apps."
    Write-Host "A system restart is recommended after completion."
    ""
    $answer = Read-Host "Continue? (y/n)"
    if ($answer -notmatch '^[Yy]') { Write-Host "Aborted."; exit }
}

New-RestorePoint

if ($RemoveApps) { Remove-BloatwareApps } else { Write-Skip "App removal skipped (use -RemoveApps)" }
if ($DisableTelemetry) { Invoke-TelemetryDisable } else { Write-Skip "Telemetry disable skipped (use -DisableTelemetry)" }
if ($DisableBing) { Invoke-BingDisable } else { Write-Skip "Bing disable skipped (use -DisableBing)" }
if ($DisableStartAds) { Invoke-StartAdsDisable } else { Write-Skip "Start ads disable skipped (use -DisableStartAds)" }
if ($HighPerformance) { Set-HighPerformancePlan } else { Write-Skip "Power plan skipped (use -HighPerformance)" }

""
Write-Host "=== Done! Restart your laptop. ===" -ForegroundColor Green
