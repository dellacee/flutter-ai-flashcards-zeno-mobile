# ─────────────────────────────────────────────────────────
# Zeno — Dev environment verification
# Usage: pwsh scripts/check-env.ps1
# ─────────────────────────────────────────────────────────

$ErrorActionPreference = 'SilentlyContinue'
$failures = @()

function Test-Tool {
    param(
        [string]$Name,
        [string]$Command,
        [string]$VersionArg = '--version',
        [string]$MinVersion = $null,
        [string]$Hint
    )

    $exe = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $exe) {
        Write-Host "[X] $Name" -ForegroundColor Red -NoNewline
        Write-Host "  -> $Hint" -ForegroundColor DarkGray
        $script:failures += $Name
        return
    }

    $output = & $Command $VersionArg 2>&1 | Select-Object -First 1
    Write-Host "[OK] $Name" -ForegroundColor Green -NoNewline
    Write-Host "  ($output)" -ForegroundColor DarkGray
}

function Test-Env {
    param([string]$Name, [string]$Hint)

    $val = [Environment]::GetEnvironmentVariable($Name, 'User')
    if (-not $val) { $val = [Environment]::GetEnvironmentVariable($Name, 'Machine') }

    if (-not $val) {
        Write-Host "[X] env $Name" -ForegroundColor Red -NoNewline
        Write-Host "  -> $Hint" -ForegroundColor DarkGray
        $script:failures += "env:$Name"
    } else {
        Write-Host "[OK] env $Name" -ForegroundColor Green -NoNewline
        Write-Host "  ($val)" -ForegroundColor DarkGray
    }
}

Write-Host "`n=== Zeno dev env check ===`n" -ForegroundColor Cyan

Test-Tool -Name 'Git'             -Command 'git'      -Hint 'https://git-scm.com/download/win'
Test-Tool -Name 'Node.js (>=20)'  -Command 'node'     -Hint 'https://nodejs.org/'
Test-Tool -Name 'Java (JDK)'      -Command 'java'     -VersionArg '-version' -Hint 'Comes with Android Studio'
Test-Tool -Name 'Flutter'         -Command 'flutter'  -Hint 'https://docs.flutter.dev/get-started/install/windows'
Test-Tool -Name 'Dart'            -Command 'dart'     -Hint 'Comes with Flutter'
Test-Tool -Name 'Firebase CLI'    -Command 'firebase' -Hint 'npm install -g firebase-tools'
Test-Tool -Name 'FlutterFire CLI' -Command 'flutterfire' -Hint 'dart pub global activate flutterfire_cli'
Test-Tool -Name 'adb'             -Command 'adb'      -Hint 'Android SDK platform-tools'

Write-Host "`n--- Environment variables ---`n" -ForegroundColor Cyan
Test-Env -Name 'ANDROID_HOME' -Hint 'Set to C:\Users\<user>\AppData\Local\Android\Sdk'
Test-Env -Name 'JAVA_HOME'    -Hint 'Set to JDK install path (Android Studio bundled JDK OK)'

Write-Host "`n--- Flutter doctor ---`n" -ForegroundColor Cyan
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    flutter doctor 2>&1 | Out-String | Write-Host
} else {
    Write-Host "(skipped - flutter not found)" -ForegroundColor DarkGray
}

Write-Host "`n--- Result ---`n" -ForegroundColor Cyan
if ($failures.Count -eq 0) {
    Write-Host "All checks passed. Ready to run subagent-driven plan execution." -ForegroundColor Green
    exit 0
} else {
    Write-Host "$($failures.Count) issue(s):" -ForegroundColor Yellow
    $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host "`nFix the issues above, then re-run this script.`n" -ForegroundColor Yellow
    exit 1
}
