@echo off
setlocal
cd /d "%~dp0"
title Finans App - Baslatiliyor...
color 0A
cls

echo.
echo  ========================================================
echo    FINANS APP - OTOMATIK BASLATMA
echo    Frontend: http://localhost:8080
echo    Backend:  http://localhost:2223
echo  ========================================================
echo.

:: 1. Eski portlari temizle
echo [1/6] Eski portlar temizleniyor...
powershell -Command "Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }" >nul 2>&1
powershell -Command "Get-NetTCPConnection -LocalPort 2223 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }" >nul 2>&1
echo      [OK]

:: 2. Flutter yolunu ayarla
echo [2/6] Flutter ayarlaniyor...
set "FL_BIN=%~dp0tools\flutter\bin"
if exist "%FL_BIN%\flutter.bat" (
    set "PATH=%FL_BIN%;%PATH%"
    echo      [OK]
) else (
    echo      [HATA] Flutter bulunamadi: %FL_BIN%
    pause
    exit /b
)

:: 3. Backend baslat
echo [3/6] Backend baslatiliyor (Port: 2223)...
if not exist "finans_backend\manage.py" (
    echo      [HATA] finans_backend\manage.py bulunamadi!
    pause
    exit /b
)
start "" /min cmd /c "cd /d %~dp0finans_backend && python manage.py runserver 0.0.0.0:2223"
echo      [OK]

:: 4. Flutter Web Build
echo [4/6] Frontend derleniyor (30-90 saniye surebilir)...
cd /d "%~dp0finans_app"
call flutter build web --release

if errorlevel 1 (
    echo      [HATA] Frontend derlemesi basarisiz!
    pause
    exit /b
)
echo      [OK] Build tamamlandi.

:: 5. Web sunucusu baslat (dogru MIME tipleriyle)
echo [5/6] Web sunucusu baslatiliyor (Port: 8080)...
start "" /min cmd /c "python %~dp0web_server.py 8080 %~dp0finans_app\build\web"
echo      [OK]

:: 6. Tarayiciyi ac
echo [6/6] Tarayici aciliyor...
timeout /t 2 >nul
start http://localhost:8080

echo.
echo  ========================================================
echo    FINANS APP BASARIYLA BASLATILDI!
echo    Frontend: http://localhost:8080
echo    Backend:  http://localhost:2223
echo.
echo    Servisleri durdurmak icin finans_kapat.bat kullanin.
echo  ========================================================
echo.
pause
