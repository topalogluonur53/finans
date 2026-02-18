@echo off
setlocal
cd /d "%~dp0"
title Finans App - GELISTIRME MODU (HOT RELOAD)
color 0A

:: 1. Mevcut islemleri temizle (Opsiyonel ama cakismalari onler)
echo [1/3] Eski servisler kontrol ediliyor...
taskkill /F /IM dart.exe >nul 2>&1
taskkill /F /IM flutter.exe >nul 2>&1
taskkill /F /IM python.exe >nul 2>&1
powershell -Command "Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }" >nul 2>&1

:: 2. Flutter Yolu Ayarla
set "FL_BIN=%~dp0tools\flutter\bin"
if exist "%FL_BIN%\flutter.bat" (
    set "PATH=%FL_BIN%;%PATH%"
)

:: 3. Backend'i arka planda baslat
echo [2/3] Backend baslatiliyor (Port: 2223)...
start "Finans Backend" /min cmd /c "cd /d %~dp0finans_backend && python manage.py runserver 0.0.0.0:2223"
timeout /t 3 >nul

:: 4. Frontend'i Debug modunda baslat
echo [3/3] Frontend baslatiliyor (Debug Mode)...
echo.
echo ========================================================
echo   ANLIK DEGISIKLIKLERI GORMEK ICIN:
echo   1. Kodda degisiklik yapip kaydedin.
echo   2. Bu pencereye gelip 'r' tusuna basin (Hot Reload).
echo   3. Sayfayi tamamen yenilemek isterseniz 'R' (Hot Restart).
echo ========================================================
echo.

cd /d "%~dp0finans_app"
:: -d chrome: Tarayicida acar
:: --web-renderer html: Gelistirme asamasinda cok daha hizlidir
call flutter run -d chrome --web-port 8080

pause
