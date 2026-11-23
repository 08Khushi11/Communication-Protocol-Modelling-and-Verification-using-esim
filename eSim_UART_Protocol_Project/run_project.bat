@echo off
setlocal
echo ======================================================================
echo    eSim Task 2: UART Mixed-Signal Simulation & Verification Runner
echo ======================================================================
echo.

cd /d "%~dp0"
if exist "eSim_UART_Protocol_Project\verification\verify_simulation.py" (
    set "TARGET_SCRIPT=eSim_UART_Protocol_Project\verification\verify_simulation.py"
    set "TARGET_DIR=eSim_UART_Protocol_Project"
) else (
    set "TARGET_SCRIPT=verification\verify_simulation.py"
    set "TARGET_DIR=."
)

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

echo [INFO] Running: "%PY_BIN%" "%TARGET_SCRIPT%"
"%PY_BIN%" "%TARGET_SCRIPT%"

echo.
echo ======================================================================
echo [INFO] Simulation Finished! Waveforms are in:
echo        %TARGET_DIR%\plots\
echo.
echo Summary report is in:
echo        %TARGET_DIR%\verification\simulation_summary.txt
echo ======================================================================
pause
