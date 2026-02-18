@echo off
setlocal
cd /d "%~dp0"
title Finans App - TEMIZ KURULUM VE BASLATICI
color 0B
cls

echo.
echo  ========================================================
echo    FINANS APP - TEMIZ KURULUM VE BASLATICI
echo  ========================================================
echo.

:: 1. Mevcut islemleri temizle
echo [1/6] Eski portlar ve servisler temizleniyor...
taskkill /F /IM dart.exe >nul 2>&1
taskkill /F /IM flutter.exe >nul 2>&1
taskkill /F /IM python.exe >nul 2>&1
powershell -Command "Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }" >nul 2>&1
powershell -Command "Get-NetTCPConnection -LocalPort 2223 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }" >nul 2>&1
echo      [OK]

:: 2. Gereksiz dosyalari temizle
echo [2/6] Gereksiz dosyalar temizleniyor (__pycache__, logs, build vb.)...
del /s /q /f finans_app\build_error.txt 2>nul
del /s /q /f finans_app\build_error_full.txt 2>nul
del /s /q /f finans_app\build_log.txt 2>nul
del /s /q /f finans_app\build_out.txt 2>nul
for /d /r . %%d in (__pycache__) do @if exist "%%d" rd /s /q "%%d" 2>nul
del /s /q /f *.pyc 2>nul

echo [3/6] Flutter projesi temizleniyor (flutter clean)...
cd /d "%~dp0finans_app"
call flutter clean
echo [4/6] Bagimliliklar yukleniyor (flutter pub get)...
call flutter pub get
cd /d "%~dp0"
echo      [OK]

:: 3. Flutter Yolu Ayarla (Eger varsa local tools kullan)
set "FL_BIN=%~dp0tools\flutter\bin"
if exist "%FL_BIN%\flutter.bat" (
    set "PATH=%FL_BIN%;%PATH%"
)

:: 4. Backend Baslat
echo [5/6] Backend baslatiliyor (Django - Port: 2223)...
start "Finans Backend" /min cmd /c "cd /d %~dp0finans_backend && python manage.py runserver 0.0.0.0:2223"
timeout /t 5 >nul

:: 5. Frontend Derle ve Baslat
echo [6/6] Frontend derleniyor ve baslatiliyor...
echo.
echo NOT: Bu islem ilk seferde biraz uzun surebilir (Release Build)...
echo.

cd /d "%~dp0finans_app"
call flutter build web --release
cd /d "%~dp0"

:: Web server baslat
start "Finans Web Server" /min cmd /c "python web_server.py 8080 %~dp0finans_app\build\web"
timeout /t 2 >nul

:: Tarayiciyi ac
start http://localhost:8080

echo.
echo  ========================================================
echo    SISTEM BASARIYLA KURULDU VE BASLATILDI!
echo    Backend: http://localhost:2223
echo    Frontend: http://localhost:8080
echo  ========================================================
echo.
pause
