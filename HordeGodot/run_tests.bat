@echo off
echo ========================================================
echo   Running Godot 4 Verification Test Suite
echo ========================================================

set GODOT_EXE="C:\Users\user\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"

%GODOT_EXE% --headless --path "%~dp0." --script "res://scripts/tests/test_godot_gameplay.gd"
pause
