[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [switch]$SkipExports
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}
$repositoryRoot = (Resolve-Path (Join-Path $ProjectRoot '..')).Path
$findGodot = Join-Path $ProjectRoot 'tools\find_godot.ps1'
$godot = (& $findGodot | Select-Object -Last 1)
if ([string]::IsNullOrWhiteSpace($godot)) {
    throw 'Godot discovery did not return an executable.'
}

$logRoot = Join-Path $ProjectRoot 'logs\validation'
$buildRoot = Join-Path $ProjectRoot 'builds'
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null

function Invoke-GodotStep {
    param(
        [string]$Name,
        [string[]]$Arguments,
        [string]$LogName
    )
    $logPath = Join-Path $logRoot $LogName
    Write-Output "[VALIDATE] $Name"
    $allArguments = @($Arguments + @('--log-file', $logPath))
    $processArguments = @($allArguments | ForEach-Object {
        if ($_ -match '[\s"]') {
            '"' + $_.Replace('"', '\"') + '"'
        } else {
            $_
        }
    })
    $process = Start-Process -FilePath $godot -ArgumentList $processArguments -Wait -PassThru -WindowStyle Hidden
    if ($process.ExitCode -ne 0) {
        Get-Content -LiteralPath $logPath -Tail 200
        throw "$Name failed with exit code $($process.ExitCode)."
    }
    $errors = Select-String -LiteralPath $logPath -Pattern 'SCRIPT ERROR:|Parse Error:|ERROR:'
    if ($null -ne $errors) {
        Get-Content -LiteralPath $logPath -Tail 200
        throw "$Name logged engine or script errors."
    }
}

Push-Location $repositoryRoot
try {
    Invoke-GodotStep -Name 'Import and typed-script parse' -LogName '01_import.log' -Arguments @(
        '--headless', '--editor', '--quit', '--path', $ProjectRoot
    )
    Invoke-GodotStep -Name 'Unit and integration tests' -LogName '02_tests.log' -Arguments @(
        '--headless', '--path', $ProjectRoot, '--script', 'res://tests/run_tests.gd'
    )
    Invoke-GodotStep -Name 'Content and provenance validation' -LogName '03_content.log' -Arguments @(
        '--headless', '--path', $ProjectRoot, '--script', 'res://tools/validate_content.gd'
    )
    Invoke-GodotStep -Name 'Runtime title smoke' -LogName '04_runtime.log' -Arguments @(
        '--headless', '--path', $ProjectRoot, '--quit-after', '120'
    )

    if (-not $SkipExports) {
        $templateRoot = Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'Godot\export_templates\4.7.2.stable'
        foreach ($requiredTemplate in @('windows_debug_x86_64.exe', 'linux_debug.x86_64')) {
            if (-not (Test-Path -LiteralPath (Join-Path $templateRoot $requiredTemplate) -PathType Leaf)) {
                throw "Godot export template '$requiredTemplate' is not installed. Run game/tools/install_export_templates.ps1."
            }
        }

        $windowsOutput = Join-Path $buildRoot 'windows\Asterfold.exe'
        $linuxOutput = Join-Path $buildRoot 'linux\Asterfold.x86_64'
        New-Item -ItemType Directory -Path (Split-Path -Parent $windowsOutput) -Force | Out-Null
        New-Item -ItemType Directory -Path (Split-Path -Parent $linuxOutput) -Force | Out-Null
        Invoke-GodotStep -Name 'Windows debug export' -LogName '05_export_windows.log' -Arguments @(
            '--headless', '--path', $ProjectRoot, '--export-debug', 'Windows Debug', $windowsOutput
        )
        Invoke-GodotStep -Name 'Linux debug export' -LogName '06_export_linux.log' -Arguments @(
            '--headless', '--path', $ProjectRoot, '--export-debug', 'Linux Debug', $linuxOutput
        )
        foreach ($output in @($windowsOutput, $linuxOutput)) {
            $artifact = Get-Item -LiteralPath $output -ErrorAction Stop
            if ($artifact.Length -lt 1MB) {
                throw "Export artifact is unexpectedly small: $output"
            }
        }
        Write-Output '[VALIDATE] Windows exported-runtime smoke'
        $exportSmokeLog = Join-Path $logRoot '07_export_runtime.log'
        $smokeArguments = @('--headless', '--quit-after', '120', '--log-file', ('"' + $exportSmokeLog + '"'))
        $smokeProcess = Start-Process -FilePath $windowsOutput -ArgumentList $smokeArguments -Wait -PassThru -WindowStyle Hidden
        if ($smokeProcess.ExitCode -ne 0) {
            Get-Content -LiteralPath $exportSmokeLog -Tail 200
            throw "Windows exported-runtime smoke failed with exit code $($smokeProcess.ExitCode)."
        }
        $smokeErrors = Select-String -LiteralPath $exportSmokeLog -Pattern 'SCRIPT ERROR:|Parse Error:|ERROR:'
        if ($null -ne $smokeErrors) {
            Get-Content -LiteralPath $exportSmokeLog -Tail 200
            throw 'Windows exported-runtime smoke logged engine or script errors.'
        }
    }
} finally {
    Pop-Location
}

Write-Output '[VALIDATE] PASS: import, tests, content, runtime, and requested exports completed.'
