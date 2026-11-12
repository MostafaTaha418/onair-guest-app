[CmdletBinding()]
param(
    [string]$OutputDirectory = (Join-Path $env:LOCALAPPDATA "OnAir\signing"),
    [string]$Alias = "onair-staging-upload",
    [string]$DistinguishedName = "CN=OnAir Staging Upload, OU=Mobile, O=OnAir, L=Cairo, C=EG"
)

$ErrorActionPreference = "Stop"

function New-RandomSecret {
    $bytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32)
    return [Convert]::ToBase64String($bytes).TrimEnd("=").Replace("+", "-").Replace("/", "_")
}

$keytool = Get-Command keytool -ErrorAction Stop
$keystorePath = Join-Path $OutputDirectory "onair-staging-upload.jks"
$credentialsPath = Join-Path $OutputDirectory "github-actions-secrets.txt"
$localPropertiesPath = Join-Path $PSScriptRoot "..\android\key.properties"

foreach ($path in @($keystorePath, $credentialsPath, $localPropertiesPath)) {
    if (Test-Path -LiteralPath $path) {
        throw "Refusing to replace existing signing material: $path"
    }
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$storePassword = New-RandomSecret
$keyPassword = New-RandomSecret

& $keytool.Source -genkeypair -v `
    -keystore $keystorePath `
    -storetype JKS `
    -storepass $storePassword `
    -alias $Alias `
    -keypass $keyPassword `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -dname $DistinguishedName 2>&1 | Out-Null

$pem = & $keytool.Source -exportcert -rfc `
    -keystore $keystorePath `
    -storepass $storePassword `
    -alias $Alias
$certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromPem(
    ($pem -join "`n")
)
$rawFingerprint = $certificate.GetCertHashString(
    [System.Security.Cryptography.HashAlgorithmName]::SHA256
)
$fingerprint = (($rawFingerprint -split "(?<=\G..)") | Where-Object { $_ }) -join ":"
$keystoreBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($keystorePath))
$gradleStorePath = $keystorePath.Replace("\", "/")

$credentials = @(
    "ONAIR_UPLOAD_KEYSTORE_BASE64=$keystoreBase64"
    "ONAIR_UPLOAD_KEYSTORE_PASSWORD=$storePassword"
    "ONAIR_UPLOAD_KEY_ALIAS=$Alias"
    "ONAIR_UPLOAD_KEY_PASSWORD=$keyPassword"
    "ANDROID_CERT_SHA256_STAGING=$fingerprint"
) -join [Environment]::NewLine
[IO.File]::WriteAllText($credentialsPath, $credentials + [Environment]::NewLine)

$localProperties = @(
    "storeFile=$gradleStorePath"
    "storePassword=$storePassword"
    "keyAlias=$Alias"
    "keyPassword=$keyPassword"
) -join [Environment]::NewLine
[IO.File]::WriteAllText(
    [IO.Path]::GetFullPath($localPropertiesPath),
    $localProperties + [Environment]::NewLine
)

$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
& icacls $OutputDirectory /inheritance:r /grant:r "${identity}:(OI)(CI)F" 2>$null | Out-Null
foreach ($path in @($keystorePath, $credentialsPath, $localPropertiesPath)) {
    & icacls $path /inheritance:r /grant:r "${identity}:(F)" 2>$null | Out-Null
}

Write-Output "Created a stable Staging upload key without replacing existing material."
Write-Output "SHA-256: $fingerprint"
Write-Output "GitHub secret values: $credentialsPath"
Write-Output "Local Gradle properties: $([IO.Path]::GetFullPath($localPropertiesPath))"
