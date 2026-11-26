@echo off
setlocal
cd /d "%~dp0"
echo ============================================================
echo Building FPGA Digital Lock Project for RealDigital Urbana
echo ============================================================

set VIVADO_BAT=C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat

if not exist "%VIVADO_BAT%" (
    echo Vivado executable not found at %VIVADO_BAT%
    echo Searching in PATH...
    where vivado >nul 2>nul
    if errorlevel 1 (
        echo Vivado not found in PATH either.
        echo Please open Vivado and run in the Tcl Console:
        echo   source scripts/build.tcl
        pause
        exit /b 1
    )
    set VIVADO_BAT=vivado
)

call "%VIVADO_BAT%" -mode batch -source scripts/build.tcl
if errorlevel 1 (
    echo.
    echo ============================================================
    echo BUILD FAILED! Check error messages above.
    echo ============================================================
    pause
    exit /b 1
)

echo.
echo ============================================================
echo BUILD SUCCEEDED!
echo Bitstream generated at:
echo   vivado_proj\digital_lock_proj.runs\impl_1\digital_lock_top.bit
echo ============================================================
pause
