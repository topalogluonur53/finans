@echo off
title Finans - HIZLI DERLE (JS/CanvasKit)
cd /d "%~dp0"

echo ========================================
echo [1/3] Versiyon Guncelleniyor...
echo ========================================
set /a v=%RANDOM%
powershell -Command "(gc finans_app/web/index.html) -replace 'flutter_bootstrap.js\?v=[\d.]+', 'flutter_bootstrap.js?v=%v%' | Out-File -encoding utf8 finans_app/web/index.html"
echo Yeni Versiyon ID: %v%

echo.
echo [2/3] Flutter Derleniyor (JavaScript)...
echo ========================================
cd finans_app
call ..\tools\flutter\bin\flutter.bat build web --release
cd ..

echo.
echo [3/3] Nginx Yeniden Baslatiliyor...
echo ========================================
taskkill /f /im nginx.exe 2>nul
cd nginx
start nginx.exe
cd ..

echo.
echo Islem Tamamlandi! 
echo Tarayicida 'Ctrl + F5' yaparak test edin.
echo.
pause
