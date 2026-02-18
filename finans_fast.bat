@echo off
setlocal
cd /d "%~dp0"
title Finans App - HIZLI CALISTIR (Hot Reload)
color 0A

:: Flutter Yolu
set "FL_BIN=%~dp0tools\flutter\bin"
if exist "%FL_BIN%\flutter.bat" (
    set "PATH=%FL_BIN%;%PATH%"
)

:: Backend
start "Finans Backend" /min cmd /c "cd /d %~dp0finans_backend && python manage.py runserver 0.0.0.0:2223"

:: Frontend
cd /d "%~dp0finans_app"
echo.
echo [!] Hot Reload icin terminale 'r' yazin.
echo.
call flutter run -d chrome --web-port 8080
