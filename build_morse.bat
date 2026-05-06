@echo off
setlocal
cd /d %~dp0
SET PATH=C:\Masm615;C:\WINDOWS;C:\WINDOWS\SYSTEM32
SET INCLUDE=C:\Masm615\INCLUDE
SET LIB=C:\Masm615\LIB

echo ----------------------------------------
echo Assembling...
echo ----------------------------------------
ML -Zi -c -Fl -coff /I"C:\Masm615\INCLUDE" main.asm
if errorlevel 1 goto error

echo ----------------------------------------
echo Linking...
echo ----------------------------------------
LINK32 main.obj irvine32.lib kernel32.lib /SUBSYSTEM:CONSOLE /DEBUG
if errorlevel 1 goto error

echo ----------------------------------------
echo Build successful!
echo ----------------------------------------
goto end

:error
echo ========================================
echo BUILD FAILED - check errors above
echo ========================================

:end
