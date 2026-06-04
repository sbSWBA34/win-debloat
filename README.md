# win-debloat

Windows debloat script inspired by [Raphire/Win11Debloat](https://github.com/Raphire/Win11Debloat).
Removes OEM/Microsoft bloatware, disables telemetry, Bing, Start ads, and optimizes power settings.

## Usage

**Right-click → Run with PowerShell (Admin)** or:

```powershell
.\debloat.ps1 -RemoveApps -DisableTelemetry -DisableBing -DisableStartAds -HighPerformance
```

### Parameters

| Parameter | What it does |
|-----------|-------------|
| `-RemoveApps` | Removes bloatware (Acer, McAfee, Booking, Xbox, Skype, OneNote, Camera, Zune, etc.) via Appx & WinGet |
| `-DisableTelemetry` | Disables telemetry, advertising ID, activity history |
| `-DisableBing` | Disables Bing web search and Cortana |
| `-DisableStartAds` | Disables recommendations and ads in Start menu |
| `-HighPerformance` | Sets power plan to High Performance |
| `-RestorePoint` | Creates a system restore point before making changes |
| `-Silent` | Non-interactive mode (no prompts) |

### Quick (all-in-one with restore point)

```powershell
.\debloat.ps1 -Silent -RestorePoint -RemoveApps -DisableTelemetry -DisableBing -DisableStartAds -HighPerformance
```

## How it works

- Uses `.reg` files (like Win11Debloat) for registry tweaks — easy to inspect and modify
- Removes Appx packages for all users + provisions them so they don't come back
- Uses WinGet for OEM software (Acer, McAfee, etc.)
- Runs fully non-interactive with `-Silent`

## Adding your own tweaks

Drop `.reg` files into the `regfiles/` subdirectories:
- `regfiles\telemetry\` — runs with `-DisableTelemetry`
- `regfiles\bing\` — runs with `-DisableBing`
- `regfiles\start\` — runs with `-DisableStartAds`
