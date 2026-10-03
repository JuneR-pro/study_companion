<#
.SYNOPSIS
  Check the local Flutter and Android development environment.

.DESCRIPTION
  This script only inspects the environment. It never installs Flutter,
  Android Studio, or any SDK component.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

function Write-Section([string]$Title) {
  Write-Host "`n=== $Title ===" -ForegroundColor Cyan
}

function Write-Check([string]$Name, [bool]$Ok, [string]$Detail) {
  $label = if ($Ok) { 'OK' } else { 'MISSING/ISSUE' }
  $color = if ($Ok) { 'Green' } else { 'Yellow' }
  Write-Host ("[{0}] {1}: {2}" -f $label, $Name, $Detail) -ForegroundColor $color
}

function Find-CommandPath([string]$Name) {
  $command = Get-Command $Name -ErrorAction SilentlyContinue
  if ($null -ne $command) { return $command.Source }
  return $null
}

Write-Host 'Study Companion environment check' -ForegroundColor White
Write-Host ("PowerShell: {0}" -f $PSVersionTable.PSVersion)
Write-Host ("Working directory: {0}" -f (Get-Location))

Write-Section 'Flutter and Dart'
$flutterPath = Find-CommandPath 'flutter'
if ($flutterPath) {
  Write-Check 'flutter on PATH' $true $flutterPath
  Write-Host 'flutter --version'
  & flutter --version
  Write-Host 'flutter doctor -v'
  & flutter doctor -v
  Write-Host 'flutter devices'
  & flutter devices
} else {
  Write-Check 'flutter on PATH' $false 'Command not found; install Flutter SDK and add its bin directory to PATH.'
}

$dartPath = Find-CommandPath 'dart'
if ($dartPath) {
  Write-Check 'dart on PATH' $true $dartPath
  & dart --version
} else {
  Write-Check 'dart on PATH' $false 'Usually provided by the Flutter SDK.'
}

Write-Section 'Android SDK and adb'
$sdkCandidates = @(
  $env:ANDROID_SDK_ROOT,
  $env:ANDROID_HOME,
  (Join-Path $env:LOCALAPPDATA 'Android\Sdk')
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

if ($sdkCandidates.Count -gt 0) {
  foreach ($sdk in $sdkCandidates) {
    Write-Check 'Android SDK directory' $true $sdk
    $platformTools = Join-Path $sdk 'platform-tools'
    $adbInSdk = Join-Path $platformTools 'adb.exe'
    if (Test-Path $adbInSdk) {
      Write-Check 'SDK platform-tools/adb.exe' $true $adbInSdk
    } else {
      Write-Check 'SDK platform-tools/adb.exe' $false ("Not found under {0}" -f $sdk)
    }
  }
} else {
  Write-Check 'Android SDK directory' $false 'ANDROID_SDK_ROOT/ANDROID_HOME and the default Windows SDK path were not found.'
}

$adbPath = Find-CommandPath 'adb'
if ($adbPath) {
  Write-Check 'adb on PATH' $true $adbPath
  & adb version
  Write-Host 'adb devices'
  & adb devices
} else {
  Write-Check 'adb on PATH' $false 'Command not found; add Android SDK platform-tools to PATH.'
}

Write-Section 'Java/JDK'
$javaPath = Find-CommandPath 'java'
if ($javaPath) {
  Write-Check 'java on PATH' $true $javaPath
  & java -version 2>&1
} else {
  Write-Check 'java on PATH' $false 'Command not found.'
}
if ($env:JAVA_HOME) {
  Write-Check 'JAVA_HOME' (Test-Path $env:JAVA_HOME) $env:JAVA_HOME
} else {
  Write-Check 'JAVA_HOME' $false 'Environment variable is not set.'
}

Write-Section 'Android Studio and VS Code'
$studioCandidates = @(
  (Join-Path $env:ProgramFiles 'Android\Android Studio\bin\studio64.exe'),
  (Join-Path $env:LOCALAPPDATA 'Programs\Android Studio\bin\studio64.exe')
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique
if ($studioCandidates.Count -gt 0) {
  $studioCandidates | ForEach-Object { Write-Check 'Android Studio' $true $_ }
} else {
  Write-Check 'Android Studio' $false 'Not found in common Windows installation paths.'
}

$codePath = Find-CommandPath 'code'
if ($codePath) {
  Write-Check 'VS Code on PATH' $true $codePath
  & code --version
} else {
  Write-Check 'VS Code on PATH' $false 'Command not found.'
}

Write-Section 'Git'
$gitPath = Find-CommandPath 'git'
if ($gitPath) {
  Write-Check 'Git on PATH' $true $gitPath
  & git --version
} else {
  Write-Check 'Git on PATH' $false 'Command not found.'
}

Write-Host "`nEnvironment check completed. No software was installed or changed." -ForegroundColor White
