@echo off
setlocal
cd /d %~dp0

REM Set MASM paths
SET PATH=C:\Masm615;C:\WINDOWS;C:\WINDOWS\SYSTEM32
SET INCLUDE=C:\Masm615\INCLUDE
SET LIB=C:\Masm615\LIB

echo ==================================================
echo   MORSE CODE TRANSLATOR - Build ^& Run
echo ==================================================
echo.

echo [1/2] Assembling main.asm...
ML -Zi -c -Fl -coff /I"C:\Masm615\INCLUDE" main.asm
if errorlevel 1 goto error

echo.
echo [2/2] Linking...
LINK32 main.obj irvine32.lib kernel32.lib /SUBSYSTEM:CONSOLE /DEBUG
if errorlevel 1 goto error

echo.
echo ==================================================
echo   Build successful! Launching...
echo ==================================================
echo.
main.exe
goto end

:error
echo.
echo ==================================================
echo   BUILD FAILED - check errors above
echo ==================================================

:end
endlocal
pause
