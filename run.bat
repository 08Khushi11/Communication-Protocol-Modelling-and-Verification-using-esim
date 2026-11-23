@echo off
setlocal
echo ======================================================================
echo    eSim Task 2: UART Mixed-Signal Simulation & Verification Runner
echo ======================================================================
echo.

cd /d "%~dp0"

:: Detect best Python binary
set "PY_BIN="
if exist "C:\Users\kt06\AppData\Local\Programs\Python\Python313\python.exe" (
    set "PY_BIN=C:\Users\kt06\AppData\Local\Programs\Python\Python313\python.exe"
) else (
    where py.exe >nul 2>&1 && set "PY_BIN=py"
    if not defined PY_BIN (
        where python.exe >nul 2>&1 && set "PY_BIN=python"
    )
)

if not defined PY_BIN (
    echo [ERROR] Python was not found on your system!
    pause
    exit /b 1
)

echo [INFO] Using Python: %PY_BIN%
"%PY_BIN%" "eSim_UART_Protocol_Project\verification\verify_simulation.py"

echo.
echo ======================================================================
echo [INFO] Simulation Finished! Waveforms are in:
echo        %CD%\eSim_UART_Protocol_Project\plots\
echo.
echo Summary report is in:
echo        %CD%\eSim_UART_Protocol_Project\verification\simulation_summary.txt
echo ======================================================================
pause
