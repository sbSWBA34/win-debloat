#Requires -RunAsAdministrator

Write-Host "=== Windows Debloat Script ===" -ForegroundColor Cyan
Write-Host "Target: Acer Spin 3 + generic Windows crapware`n" -ForegroundColor Cyan

# --- Remove Windows Store bloat ---
Write-Host "[1/4] Removing bloatware apps..." -ForegroundColor Yellow
$bloat = @(
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
    "*Acer*", "*McAfee*", "*Booking*"
)
$count = 0
foreach ($pkg in (Get-AppxPackage -AllUsers $bloat)) {
    Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
    $count++
}
Write-Host "  Removed $count package(s)"

# --- Disable telemetry & background services ---
Write-Host "[2/4] Disabling telemetry & background services..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue

# --- Disable startup junk ---
Write-Host "[3/4] Disabling startup programs..." -ForegroundColor Yellow
Get-CimInstance -ClassName Win32_StartupCommand | Where-Object {
    $_.Name -match "OneDrive|Acer|McAfee|Booking"
} | ForEach-Object {
    Disable-CimInstance $_ -ErrorAction SilentlyContinue
    Write-Host "  Disabled: $($_.Name)"
}

# --- Power plan ---
Write-Host "[4/4] Setting power plan to High Performance..." -ForegroundColor Yellow
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null

Write-Host "`n=== Done! Restart your laptop. ===" -ForegroundColor Green
