# PowerShell runner for eSim UART Protocol Project
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   eSim Task 2: UART Mixed-Signal Simulation & Verification           " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$scriptPath = Join-Path $PSScriptRoot "eSim_UART_Protocol_Project\verification\verify_simulation.py"
if (-not (Test-Path $scriptPath)) {
    $scriptPath = Join-Path $PSScriptRoot "verification\verify_simulation.py"
}

$pyBin = "C:\Users\kt06\AppData\Local\Programs\Python\Python313\python.exe"
if (-not (Test-Path $pyBin)) {
    $pyCmd = Get-Command python, py -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pyCmd) { $pyBin = $pyCmd.Source }
}

if (Test-Path $pyBin) {
    & $pyBin $scriptPath
} else {
    Write-Host "[ERROR] Could not find python executable!" -ForegroundColor Red
}
