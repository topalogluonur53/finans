@echo off
setlocal
cd /d "%~dp0"
title Finans App - STANDART BASLATICI
color 0B

:: 1. Temizlik ve Hazirlik
echo [1/4] Servisler temizleniyor...
taskkill /F /IM dart.exe >nul 2>&1
taskkill /F /IM flutter.exe >nul 2>&1
taskkill /F /IM python.exe >nul 2>&1

:: 2. Yollar
set "FL_BIN=%~dp0tools\flutter\bin"
if exist "%FL_BIN%\flutter.bat" (
    set "PATH=%FL_BIN%;%PATH%"
)

:: 3. Backend
echo [2/4] Backend baslatiliyor...
start "Finans Backend" /min cmd /c "cd /d %~dp0finans_backend && python manage.py runserver 0.0.0.0:2223"

:: 4. Frontend (Clean Build)
echo [3/4] Frontend derleniyor (Release)...
cd /d "%~dp0finans_app"
call flutter clean
call flutter pub get
call flutter build web --release

:: 5. Sunucu
echo [4/4] Web sunucusu aciliyor...
cd /d "%~dp0"
start "Finans Web Server" /min cmd /c "python web_server.py 8080 %~dp0finans_app\build\web"
timeout /t 2 >nul
start http://localhost:8080

echo Bitti!
pause
