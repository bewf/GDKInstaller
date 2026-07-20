@echo off
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\bewf_GDK_Installer.ps1"

pause