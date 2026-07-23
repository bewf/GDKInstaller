@echo off
cd /d "C:\Games\Palworld"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\bewf_GDK_Installer.ps1" -UseCurrentDirectory

pause