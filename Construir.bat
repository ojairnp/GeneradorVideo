@echo off
chcp 65001 >nul
title GeneradorVideo - Agnes AI
echo.
powershell -ExecutionPolicy Bypass -File Construir.ps1
pause
