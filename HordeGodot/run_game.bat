@echo off
echo ========================================================
echo   Starting Horde: Steppe and Steel (Godot 4 3D Edition)
echo ========================================================

set GODOT_EXE="C:\Users\user\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"

if exist %GODOT_EXE% (
    %GODOT_EXE% --path "%~dp0."
) else (
    echo Error: Godot 4 executable not found at %GODOT_EXE%
    pause
)
