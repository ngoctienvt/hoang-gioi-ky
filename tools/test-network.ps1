param(
    [string]$Godot = 'D:/Downloads/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64_console.exe'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$runtimeRoot = Join-Path $projectRoot '.runtime'
New-Item -ItemType Directory -Force -Path $runtimeRoot | Out-Null
$env:APPDATA = Join-Path $runtimeRoot 'roaming'
$env:LOCALAPPDATA = Join-Path $runtimeRoot 'local'
$ownedProcesses = @()
try {
    $portOwners = netstat -ano -p UDP | Select-String ':24565\s'
    if ($portOwners) { throw 'Port 24565 is occupied. Stop the existing project host before running this test.' }
    foreach ($role in @('host', 'join')) {
        $arguments = @('--headless', '--path', $projectRoot, '--log-file', (Join-Path $runtimeRoot "$role-engine.log"), '--', "--$role", '--probe')
        $process = Start-Process -FilePath $Godot -ArgumentList $arguments -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runtimeRoot "$role-output.log") -RedirectStandardError (Join-Path $runtimeRoot "$role-error.log")
        $ownedProcesses += $process
        Write-Output "Started $role PID=$($process.Id), port=24565, project=$projectRoot"
        if ($role -eq 'host') { Start-Sleep -Milliseconds 1500 }
    }
    $failed = $false
    foreach ($process in $ownedProcesses) {
        if (!$process.WaitForExit(30000)) { throw "Network probe timed out: PID $($process.Id)" }
        if ($process.ExitCode -ne 0) { $failed = $true }
    }
    foreach ($role in @('host', 'join')) {
        Get-Content (Join-Path $runtimeRoot "$role-output.log") | Select-String '\[network\]|\[probe\]'
        $errors = Get-Content (Join-Path $runtimeRoot "$role-error.log") | Select-String 'SCRIPT ERROR|^ERROR:'
        if ($errors) { $errors; $failed = $true }
    }
    if ($failed) { exit 1 }
} finally {
    foreach ($process in $ownedProcesses) {
        if (!$process.HasExited) { Stop-Process -Id $process.Id }
    }
}
