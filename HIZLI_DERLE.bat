@echo off
title Finans - HIZLI DERLE (JS/CanvasKit)
cd /d "%~dp0"

echo ========================================
echo [1/3] Versiyon Guncelleniyor...
echo ========================================
set /a v=%RANDOM%
python -c "import re; content = open('finans_app/web/index.html', 'r', encoding='utf-8-sig').read(); content = re.sub(r'flutter_bootstrap\.js\?v=[\d.]+', 'flutter_bootstrap.js?v=%v%', content); open('finans_app/web/index.html', 'w', encoding='utf-8', newline='').write(content)"
echo Yeni Versiyon ID: %v%

echo.
echo [2/3] Flutter Derleniyor (JavaScript)...
echo ========================================
cd finans_app
call flutter build web --release
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
start http://localhost:8080
pause
