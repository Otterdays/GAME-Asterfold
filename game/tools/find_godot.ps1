[CmdletBinding()]
param(
    [string]$ExplicitPath = $env:ASTERFOLD_GODOT
)

$ErrorActionPreference = 'Stop'
$requiredVersionPrefix = '4.7.2.stable.official.'
$candidates = [System.Collections.Generic.List[string]]::new()

if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
    $candidates.Add($ExplicitPath)
}

$desktopCandidate = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Godot_v4.7.2-stable_win64.exe'
$candidates.Add($desktopCandidate)

foreach ($commandName in @('godot.exe', 'godot')) {
    $command = Get-Command $commandName -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        $candidates.Add($command.Source)
    }
}

$checked = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($candidate in $candidates) {
    if ([string]::IsNullOrWhiteSpace($candidate) -or -not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        continue
    }
    $resolved = (Resolve-Path -LiteralPath $candidate).Path
    if (-not $checked.Add($resolved)) {
        continue
    }
    if ([System.IO.Path]::GetFileName($resolved) -match '(?i)mono') {
        continue
    }
    $version = (& $resolved --version 2>$null | Select-Object -First 1)
    if ($version.StartsWith($requiredVersionPrefix, [System.StringComparison]::OrdinalIgnoreCase) -and $version -notmatch '(?i)mono') {
        Write-Output $resolved
        exit 0
    }
}

Write-Error 'Asterfold requires the official Godot 4.7.2 Standard build. Set ASTERFOLD_GODOT or place Godot_v4.7.2-stable_win64.exe on the Desktop.'
exit 1
