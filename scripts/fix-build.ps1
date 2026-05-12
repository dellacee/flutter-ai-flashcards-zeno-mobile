# ─────────────────────────────────────────────────────────
# Zeno — Reset build state when plugin/Gradle cache is corrupt.
# Usage: pwsh scripts/fix-build.ps1
#
# Use when you see:
#   - "Plugin directory does not exist: ...cloud_firestore-X.X.X/android"
#   - PlatformException(channel-error, ... initializeCore)
#   - Only `integration_test` in .flutter-plugins-dependencies (should be 13+)
# ─────────────────────────────────────────────────────────

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root 'app'

function Step([string]$msg, [scriptblock]$action) {
    Write-Host "`n>> $msg" -ForegroundColor Cyan
    & $action
}

Step "Stop Gradle daemon + kill Java" {
    Push-Location (Join-Path $app 'android')
    if (Test-Path .\gradlew.bat) {
        & .\gradlew.bat --stop 2>&1 | Out-Null
    }
    Pop-Location
    Get-Process java, javaw -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep 1
    Write-Host "OK"
}

Step "Remove stale generated state" {
    Push-Location $app
    Remove-Item .flutter-plugins-dependencies, pubspec.lock -Force -ErrorAction SilentlyContinue
    Remove-Item .dart_tool, build, .gradle, .\android\.gradle -Recurse -Force -ErrorAction SilentlyContinue
    Pop-Location
    Write-Host "OK"
}

Step "Check pub cache integrity (cloud_firestore android folder)" {
    $cfs = Get-ChildItem "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\cloud_firestore-*" -Directory -ErrorAction SilentlyContinue
    foreach ($d in $cfs) {
        $gradle = Join-Path $d.FullName 'android\build.gradle'
        if (-not (Test-Path $gradle)) {
            Write-Host "  CORRUPT: $($d.Name) - removing for fresh download" -ForegroundColor Yellow
            Remove-Item $d.FullName -Recurse -Force
        } else {
            Write-Host "  OK: $($d.Name)" -ForegroundColor Green
        }
    }
}

Step "flutter pub get (regenerate plugin list)" {
    Push-Location $app
    flutter pub get 2>&1 | Select-Object -Last 2
    Pop-Location
}

Step "Verify plugins registered" {
    $deps = Get-Content (Join-Path $app '.flutter-plugins-dependencies') -Raw | ConvertFrom-Json
    $count = ($deps.plugins.android | Measure-Object).Count
    Write-Host "  Android plugins: $count"
    if ($count -lt 5) {
        Write-Host "  WARNING: too few plugins, may need a second pub get" -ForegroundColor Yellow
    } else {
        Write-Host "  OK" -ForegroundColor Green
    }
    $deps.plugins.android | Select-Object -ExpandProperty name | ForEach-Object { Write-Host "    - $_" }
}

Step "Uninstall app from emulator (if installed)" {
    & adb uninstall app.zeno.zeno 2>&1 | Out-String | Select-Object -First 1
}

Write-Host "`n=== Done ===" -ForegroundColor Green
Write-Host "Next: cd app && flutter run"
