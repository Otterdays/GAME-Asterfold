[CmdletBinding()]
param(
    [ValidateRange(1, 3600)]
    [int]$DurationSeconds = 600
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$godot = (& (Join-Path $PSScriptRoot 'find_godot.ps1') | Select-Object -Last 1)
$logRoot = Join-Path $projectRoot 'logs\validation'
$reportPath = Join-Path $projectRoot 'builds\performance\m1_soak.json'
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
$logPath = Join-Path $logRoot 'm1_soak.log'

$arguments = @(
    '--path', $projectRoot,
    '--scene', 'res://tests/fixtures/m1_performance_runner.tscn',
    '--log-file', $logPath,
    '--', "--soak-seconds=$DurationSeconds"
)
Write-Output "[SOAK] Starting a $DurationSeconds-second rendered traversal."
$process = Start-Process -FilePath $godot -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
if ($process.ExitCode -ne 0) {
    Get-Content -LiteralPath $logPath -Tail 200
    throw "Performance soak failed with exit code $($process.ExitCode)."
}
$errors = Select-String -LiteralPath $logPath -Pattern 'SCRIPT ERROR:|Parse Error:|ERROR:'
if ($null -ne $errors) {
    Get-Content -LiteralPath $logPath -Tail 200
    throw 'Performance soak logged engine or script errors.'
}
if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
    throw 'Performance soak did not write its report.'
}
$report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
if (-not $report.passed) {
    Get-Content -LiteralPath $reportPath
    throw 'Performance soak exceeded one or more M1 budgets.'
}
Write-Output "[SOAK] PASS: report written to $reportPath"
