# win-debloat

Debloat script for Acer Spin 3 and other Windows laptops. Removes bloatware, disables telemetry, and tweaks power settings.

## Usage

**Right-click → Run with PowerShell (Admin)** or:

```powershell
powershell -ExecutionPolicy Bypass -File debloat.ps1
```

## What it does

- Removes Acer, McAfee, Booking, Xbox, Office hubs, Skype, OneNote, Weather, News, Mail, Camera, Maps, Zune, and other crapware
- Disables telemetry
- Disables common startup junk (OneDrive, Acer, McAfee, Booking)
- Sets power plan to High Performance

## Restore

If you need a removed app back, run from an admin prompt:

```powershell
Get-AppxPackage -AllUsers Microsoft.WindowsCamera | Add-AppxPackage -AllUsers
```

Replace `Microsoft.WindowsCamera` with the package name you want back.
