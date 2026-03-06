@echo off
title Finans Projesi - TAM YENIDEN BASLATICI
cd /d "%~dp0"

echo ========================================
echo [1/4] Eski Surecler Temizleniyor...
echo ========================================
taskkill /f /im nginx.exe 2>nul
taskkill /f /fi "windowtitle eq Finans Backend*" 2>nul
taskkill /f /fi "windowtitle eq Django Backend*" 2>nul

echo.
echo [2/4] Nginx Baslatiliyor (Port 8080)...
echo ========================================
cd /d "nginx"
start nginx.exe
cd ..

timeout /t 2 >nul

echo.
echo [3/4] Backend (Waitress - Port 2223) Baslatiliyor...
echo ========================================
start "Finans Backend" cmd /c "backend_start.bat"

timeout /t 3 >nul

echo.
echo [4/4] Tarayici aciliyor...
echo ========================================
start http://localhost:8080

echo.
echo Her sey hazir!
echo Frontend: http://localhost:8080
echo Backend API: http://localhost:2223/api/
echo Cloudflare URL: https://finans.onurtopaloglu.uk
echo.
pause
