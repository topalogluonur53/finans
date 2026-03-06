@echo off
title Finans - GELISTIRICI MODU (Hot Restart Destekli)
cd /d "%~dp0"

echo ========================================
echo [1/2] Bagimliliklar Kontrol Ediliyor...
echo ========================================
cd finans_app
call flutter pub get

echo.
echo [2/2] Flutter Uygulamasi Baslatiliyor...
echo ----------------------------------------
echo NOT: Chrome acildiginda degisiklikleri aninda 
echo gormek icin terminale 'r' basabilirsiniz.
echo ----------------------------------------
call flutter run -d chrome
cd ..

pause
