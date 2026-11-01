$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$androidRoot = Join-Path $root 'android'
$keyPropertiesPath = Join-Path $androidRoot 'key.properties'
$keystorePath = Join-Path $androidRoot 'upload-keystore.jks'
$alias = 'catatuang-upload'

function ConvertTo-JavaPropertiesValue([string]$Value) {
    $escaped = $Value.Replace('\', '\\')
    $escaped = $escaped.Replace("`t", '\t').Replace("`r", '\r').Replace("`n", '\n')
    foreach ($character in @(' ', ':', '=', '#', '!')) {
        $escaped = $escaped.Replace($character, "\$character")
    }
    return $escaped
}

if (-not $env:JAVA_HOME) {
    Write-Error 'JAVA_HOME belum diatur. Pastikan JDK 17+ terinstal dan JAVA_HOME sudah diset.'
    exit 1
}

$keytool = Join-Path $env:JAVA_HOME 'bin\keytool.exe'
if (-not (Test-Path $keytool)) {
    Write-Error "keytool tidak ditemukan di $keytool. Periksa instalasi JDK 17+."
    exit 1
}

if (Test-Path $keyPropertiesPath) {
    Write-Host "File $keyPropertiesPath sudah ada. Tidak membuat keystore baru."
    exit 0
}

if (Test-Path $keystorePath) {
    Write-Error "Keystore $keystorePath sudah ada tetapi key.properties belum ada. Jangan menimpa keystore; pulihkan file konfigurasi dari backup atau gunakan nama keystore baru."
    exit 1
}

$storePasswordSecure = Read-Host 'Masukkan storePassword untuk upload keystore' -AsSecureString
$keyPasswordSecure = Read-Host 'Masukkan keyPassword untuk alias release' -AsSecureString
$storePasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePasswordSecure)
$keyPasswordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPasswordSecure)
$storePassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($storePasswordPointer)
$keyPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($keyPasswordPointer)
$storePasswordEscaped = ConvertTo-JavaPropertiesValue $storePassword
$keyPasswordEscaped = ConvertTo-JavaPropertiesValue $keyPassword
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
$storePasswordFile = Join-Path $tempRoot 'store-password.txt'
$keyPasswordFile = Join-Path $tempRoot 'key-password.txt'

try {
    New-Item -ItemType Directory -Path $tempRoot | Out-Null
    [System.IO.File]::WriteAllText($storePasswordFile, $storePassword)
    [System.IO.File]::WriteAllText($keyPasswordFile, $keyPassword)

    & $keytool -genkeypair -v `
        -keystore $keystorePath `
        -alias $alias `
        -keyalg RSA `
        -keysize 2048 `
        -validity 10000 `
        -storepass:file $storePasswordFile `
        -keypass:file $keyPasswordFile `
        -dname 'CN=CatatUang, OU=Release, O=CatatUang, L=Jakarta, ST=DKI Jakarta, C=ID'
    if ($LASTEXITCODE -ne 0) {
        throw "keytool gagal membuat keystore (exit code $LASTEXITCODE)."
    }

    @"
storePassword=$storePasswordEscaped
keyPassword=$keyPasswordEscaped
keyAlias=$alias
storeFile=upload-keystore.jks
"@ | Set-Content -Path $keyPropertiesPath -Encoding ASCII

    Write-Host "Keystore dibuat di: $keystorePath"
    Write-Host "key.properties dibuat di: $keyPropertiesPath"
    Write-Host 'Jangan pernah menambahkan file ini ke Git.'
}
finally {
    if (Test-Path $tempRoot) {
        Remove-Item -Path $tempRoot -Recurse -Force
    }
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($storePasswordPointer)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($keyPasswordPointer)
    $storePassword = $null
    $keyPassword = $null
}
