# ─────────────────────────────────────────────────────────
# Zeno — Reset build state when plugin/Gradle cache is corrupt.
# Usage: pwsh scripts/fix-build.ps1
#
# Use when you see:
#   - "Plugin directory does not exist: ...cloud_firestore-X.X.X/android"
#   - PlatformException(channel-error, ... initializeCore)
#   - Only `integration_test` in .flutter-plugins-dependencies (should be 13+)
#   - Gradle only sees `:app` and `:integration_test` subprojects
#
# ⚠️ IMPORTANT: Never run `flutter clean` in this codebase. It corrupts
# `.flutter-plugins-dependencies` (drops production plugins, keeps only
# the integration_test dev plugin). Use this script instead to wipe just
# the Gradle/Flutter build caches while preserving plugin registration.
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

Step "Remove generated state (preserve .flutter-plugins-dependencies if 13+ plugins)" {
    Push-Location $app
    $depsPath = '.flutter-plugins-dependencies'
    $preserve = $false
    if (Test-Path $depsPath) {
        try {
            $deps = Get-Content $depsPath -Raw | ConvertFrom-Json
            $count = ($deps.plugins.android | Measure-Object).Count
            if ($count -ge 5) {
                $preserve = $true
                Write-Host "  Plugin file healthy ($count plugins), preserving" -ForegroundColor Green
            } else {
                Write-Host "  Plugin file corrupt ($count plugin), forcing regen" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  Plugin file unreadable, forcing regen" -ForegroundColor Yellow
        }
    }
    if (-not $preserve) {
        Remove-Item $depsPath, pubspec.lock -Force -ErrorAction SilentlyContinue
        Remove-Item .dart_tool -Recurse -Force -ErrorAction SilentlyContinue
    }
    # Always wipe Gradle/build caches (these don't affect plugin registration)
    Remove-Item build, .gradle, .\android\.gradle, .\android\app\build -Recurse -Force -ErrorAction SilentlyContinue
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

Step "flutter pub get (regenerate plugin list if needed)" {
    Push-Location $app
    flutter pub get 2>&1 | Select-Object -Last 2
    Pop-Location
}

Step "Verify plugins registered" {
    $deps = Get-Content (Join-Path $app '.flutter-plugins-dependencies') -Raw | ConvertFrom-Json
    $count = ($deps.plugins.android | Measure-Object).Count
    Write-Host "  Android plugins: $count"
    if ($count -lt 5) {
        Write-Host "  WARNING: too few plugins. Delete .dart_tool + .flutter-plugins-dependencies + pubspec.lock then re-run" -ForegroundColor Yellow
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
Write-Host "DO NOT run 'flutter clean' — it corrupts the plugin file. Use this script instead."
