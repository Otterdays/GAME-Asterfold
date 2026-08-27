@echo off
setlocal

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0game\tools\validate_project.ps1" %*
exit /b %ERRORLEVEL%
