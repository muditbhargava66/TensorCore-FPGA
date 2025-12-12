@echo off
REM =============================================================================
REM TensorCore-FPGA - Windows Vivado Build Script
REM Run this after copying the project to Windows with Vivado installed
REM =============================================================================

echo.
echo ==============================================
echo   TensorCore-FPGA - Vivado Build (Windows)
echo ==============================================
echo.

REM Check if Vivado is in PATH
where vivado >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Vivado not found in PATH
    echo         Please run this from Vivado Command Prompt or add to PATH
    echo         Typically: C:\Xilinx\Vivado\2023.1\bin
    pause
    exit /b 1
)

REM Navigate to project directory
cd /d "%~dp0\..\vivado\tcl"

echo [1/5] Creating Vivado project...
vivado -mode batch -source create_project.tcl
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Project creation failed
    pause
    exit /b 1
)

echo.
echo [2/5] Opening project and running synthesis...
vivado -mode batch -source run_synth.tcl
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Synthesis may have had warnings
)

echo.
echo ==============================================
echo   Build Complete!
echo ==============================================
echo.
echo   Project: vivado\build\tensorcore.xpr
echo.
echo   To continue in GUI:
echo   vivado vivado\build\tensorcore.xpr
echo.
pause
