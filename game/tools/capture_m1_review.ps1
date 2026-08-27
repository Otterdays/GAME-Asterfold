[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$godot = (& (Join-Path $PSScriptRoot 'find_godot.ps1') | Select-Object -Last 1)
$logRoot = Join-Path $projectRoot 'logs\validation'
$captureRoot = Join-Path $projectRoot 'builds\captures\m1'
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
New-Item -ItemType Directory -Path $captureRoot -Force | Out-Null
$logPath = Join-Path $logRoot 'm1_capture.log'

$arguments = @(
    '--path', $projectRoot,
    '--scene', 'res://tests/fixtures/m1_capture_runner.tscn',
    '--log-file', $logPath
)
$process = Start-Process -FilePath $godot -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
if ($process.ExitCode -ne 0) {
    Get-Content -LiteralPath $logPath -Tail 200
    throw "M1 review capture failed with exit code $($process.ExitCode)."
}
$errors = Select-String -LiteralPath $logPath -Pattern 'SCRIPT ERROR:|Parse Error:|ERROR:'
if ($null -ne $errors) {
    Get-Content -LiteralPath $logPath -Tail 200
    throw 'M1 review capture logged engine or script errors.'
}

Add-Type -AssemblyName System.Drawing
$sourcePath = Join-Path $captureRoot 'brindlewick_center.png'
$grayscalePath = Join-Path $captureRoot 'brindlewick_center_grayscale.png'
$source = [System.Drawing.Bitmap]::new($sourcePath)
$grayscale = [System.Drawing.Bitmap]::new($source.Width, $source.Height)
$graphics = [System.Drawing.Graphics]::FromImage($grayscale)
$matrix = [System.Drawing.Imaging.ColorMatrix]::new(@(
    [single[]]@(0.299, 0.299, 0.299, 0, 0),
    [single[]]@(0.587, 0.587, 0.587, 0, 0),
    [single[]]@(0.114, 0.114, 0.114, 0, 0),
    [single[]]@(0, 0, 0, 1, 0),
    [single[]]@(0, 0, 0, 0, 1)
))
$attributes = [System.Drawing.Imaging.ImageAttributes]::new()
$attributes.SetColorMatrix($matrix)
$graphics.DrawImage($source, [System.Drawing.Rectangle]::new(0, 0, $source.Width, $source.Height), 0, 0, $source.Width, $source.Height, [System.Drawing.GraphicsUnit]::Pixel, $attributes)
$grayscale.Save($grayscalePath, [System.Drawing.Imaging.ImageFormat]::Png)
$attributes.Dispose()
$graphics.Dispose()
$grayscale.Dispose()
$source.Dispose()

Write-Output "[CAPTURE] PASS: M1 review images written to $captureRoot"
