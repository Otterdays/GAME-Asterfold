@echo off
setlocal

set "PROJECT_DIR=%~dp0game"
set "GODOT_EXE="

if defined ASTERFOLD_GODOT if exist "%ASTERFOLD_GODOT%" set "GODOT_EXE=%ASTERFOLD_GODOT%"
if not defined GODOT_EXE if exist "%USERPROFILE%\Desktop\Godot_v4.7.2-stable_win64.exe" set "GODOT_EXE=%USERPROFILE%\Desktop\Godot_v4.7.2-stable_win64.exe"

if not defined GODOT_EXE (
	for /f "delims=" %%G in ('where godot.exe 2^>nul') do if not defined GODOT_EXE set "GODOT_EXE=%%G"
)

if not defined GODOT_EXE (
	echo Asterfold could not find Godot 4.7.2 Standard.
	echo.
	echo Put Godot_v4.7.2-stable_win64.exe on your Desktop, add Godot to PATH,
	echo or set ASTERFOLD_GODOT to the full executable path.
	pause
	exit /b 1
)

set "GODOT_VERSION="
for /f "delims=" %%V in ('"%GODOT_EXE%" --version 2^>nul') do if not defined GODOT_VERSION set "GODOT_VERSION=%%V"

if /i not "%GODOT_VERSION:~0,5%"=="4.7.2" (
	echo Asterfold requires Godot 4.7.2 Standard.
	echo Found: %GODOT_VERSION%
	echo At:    %GODOT_EXE%
	pause
	exit /b 2
)

start "Asterfold" "%GODOT_EXE%" --path "%PROJECT_DIR%" %*

