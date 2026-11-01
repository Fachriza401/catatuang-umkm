$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$keyPropertiesPath = Join-Path $root 'android\key.properties'
$supabaseUrl = $env:SUPABASE_URL
$supabaseKey = $env:SUPABASE_PUBLISHABLE_KEY

if (-not (Test-Path $keyPropertiesPath)) {
    Write-Error 'android/key.properties belum dibuat. Jalankan scripts/generate_android_keystore.ps1 terlebih dahulu.'
    exit 1
}

if ([string]::IsNullOrWhiteSpace($supabaseUrl) -or [string]::IsNullOrWhiteSpace($supabaseKey)) {
    Write-Error 'Set environment SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY sebelum build release.'
    exit 1
}

Push-Location $root
try {
    flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'flutter analyze gagal.' }

    flutter test
    if ($LASTEXITCODE -ne 0) { throw 'flutter test gagal.' }

    flutter build appbundle --release `
        "--dart-define=SUPABASE_URL=$supabaseUrl" `
        "--dart-define=SUPABASE_PUBLISHABLE_KEY=$supabaseKey"
    if ($LASTEXITCODE -ne 0) { throw 'Build Android App Bundle gagal.' }
}
finally {
    Pop-Location
}
