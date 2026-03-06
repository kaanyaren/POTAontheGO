<#
PowerShell helper: copies the repo icon into project assets, generates launcher icons,
and runs the app with MAPTILER_API_KEY read from secrets/maptiler.key
#>
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
$keyFile = Join-Path $root 'secrets\maptiler.key'
if (-not (Test-Path $keyFile)) {
    Write-Error "MAPTILER key file not found: $keyFile"
    exit 1
}

$key = (Get-Content -Raw -Path $keyFile).Trim()
if ([string]::IsNullOrWhiteSpace($key)) {
    Write-Error "MAPTILER key is empty in $keyFile"
    exit 1
}

Write-Host "Using MAPTILER key from $keyFile"

# Ensure assets icons folder exists and copy the project icon from repo root
$assetsIcons = Join-Path $root 'assets\icons'
if (-not (Test-Path $assetsIcons)) { New-Item -ItemType Directory -Path $assetsIcons -Force | Out-Null }

# repo root contains POTAontheGoLogo.png
$repoIcon = Join-Path (Split-Path -Parent $root) 'POTAontheGoLogo.png'
if (-not (Test-Path $repoIcon)) {
    Write-Error "Repo icon not found at $repoIcon"
    exit 1
}

Copy-Item -Force -Path $repoIcon -Destination (Join-Path $assetsIcons 'POTAontheGoLogo.png')

Write-Host "Running flutter pub get..."
flutter pub get

Write-Host "Generating launcher icons..."
flutter pub run flutter_launcher_icons:main

Write-Host "Querying connected devices..."
$devicesJson = flutter devices --machine
try {
    $devices = $devicesJson | ConvertFrom-Json
}
catch {
    Write-Error "Failed to parse devices: $_"
    exit 1
}

if ($devices.Count -eq 0) {
    Write-Error "No flutter devices found"
    exit 1
}

# Prefer Android emulator/device
$selected = $devices | Where-Object { $_.platform -match 'android' } | Select-Object -First 1
if (-not $selected) { $selected = $devices[0] }

$deviceId = $selected.id
Write-Host "Using device: $deviceId ($($selected.name))"

Write-Host "Launching app on device with MAPTILER key..."
flutter run --dart-define="MAPTILER_API_KEY=$key" -d $deviceId
