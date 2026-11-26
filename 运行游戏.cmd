@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\run_game.ps1"
if errorlevel 1 (
  echo.
  echo 启动失败，请用 Godot 打开本目录 project.godot 后按 F5，或查看 README.md。
  pause
)
