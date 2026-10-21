param([string]$FlutterPath = 'D:\soft\flutter\bin\flutter.bat')

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
    $versionLine = Get-Content -LiteralPath 'pubspec.yaml' | Where-Object { $_ -match '^version:\s*(\S+)' } | Select-Object -First 1
    if ($versionLine -notmatch '^version:\s*(\S+)') { throw 'Cannot read application version.' }
    $appVersion = $Matches[1]
    & $FlutterPath build apk --release
    if ($LASTEXITCODE -ne 0) { throw 'APK build failed.' }
    $outputDir = Join-Path $projectRoot 'build\app\outputs\flutter-apk'
    $target = Join-Path $outputDir "study_companion-v$appVersion-release.apk"
    Move-Item -LiteralPath (Join-Path $outputDir 'app-release.apk') -Destination $target -Force
    Write-Output "APK: $target"
} finally {
    Pop-Location
}
