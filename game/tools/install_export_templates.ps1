[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$templateVersion = '4.7.2.stable'
$archiveName = 'Godot_v4.7.2-stable_export_templates.tpz'
$archiveUrl = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'
$expectedSha256 = 'f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011'
$cacheRoot = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Asterfold\GodotTemplates\4.7.2'
$archivePath = Join-Path $cacheRoot $archiveName
$partialPath = "$archivePath.partial"
$templateRoot = Join-Path ([Environment]::GetFolderPath('ApplicationData')) "Godot\export_templates\$templateVersion"
$requiredFiles = @('windows_debug_x86_64.exe', 'linux_debug.x86_64')

New-Item -ItemType Directory -Path $cacheRoot -Force | Out-Null

function Test-ArchiveHash {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    return $actual -eq $expectedSha256
}

if (-not (Test-ArchiveHash -Path $archivePath)) {
    if (Test-Path -LiteralPath $partialPath) {
        Remove-Item -LiteralPath $partialPath -Force
    }
    Write-Output "Downloading official Godot $templateVersion export templates (about 1.28 GB)..."
    & curl.exe --location --fail --retry 3 --output $partialPath $archiveUrl
    if ($LASTEXITCODE -ne 0) {
        throw "Template download failed with curl exit code $LASTEXITCODE."
    }
    if (-not (Test-ArchiveHash -Path $partialPath)) {
        throw "Template SHA-256 verification failed. Expected $expectedSha256."
    }
    Move-Item -LiteralPath $partialPath -Destination $archivePath -Force
}

$verifiedHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Output "Verified template archive SHA-256: $verifiedHash"

$extractRoot = Join-Path $cacheRoot ("extract-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $extractRoot | Out-Null

try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($archivePath, $extractRoot)
    $payloadRoot = Join-Path $extractRoot 'templates'
    if (-not (Test-Path -LiteralPath $payloadRoot -PathType Container)) {
        $payloadRoot = $extractRoot
    }
    foreach ($fileName in $requiredFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $payloadRoot $fileName) -PathType Leaf)) {
            throw "Verified archive is missing required template '$fileName'."
        }
    }
    New-Item -ItemType Directory -Path $templateRoot -Force | Out-Null
    Copy-Item -Path (Join-Path $payloadRoot '*') -Destination $templateRoot -Recurse -Force
} finally {
    $resolvedCache = (Resolve-Path -LiteralPath $cacheRoot).Path.TrimEnd('\') + '\'
    $resolvedExtract = (Resolve-Path -LiteralPath $extractRoot).Path
    if ($resolvedExtract.StartsWith($resolvedCache, [System.StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $resolvedExtract -Recurse -Force
    }
}

foreach ($fileName in $requiredFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $templateRoot $fileName) -PathType Leaf)) {
        throw "Template installation did not produce '$fileName'."
    }
}

Write-Output "Installed Godot $templateVersion export templates to $templateRoot"
