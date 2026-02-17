@echo off
cd /d "%~dp0"
title Finans App - Kapatiliyor...
color 0C
cls

echo.
echo  ========================================================
echo    FINANS APP - SERVISLERI DURDURMA
echo  ========================================================
echo.

echo [ISLEM] Flutter surecleri kapatiliyor...
taskkill /F /IM dart.exe >nul 2>&1
taskkill /F /IM flutter.exe >nul 2>&1

echo [ISLEM] Port 8080 kapatiliyor...
powershell -Command "Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }" >nul 2>&1

echo [ISLEM] Port 2223 kapatiliyor...
powershell -Command "Get-NetTCPConnection -LocalPort 2223 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }" >nul 2>&1

echo [ISLEM] Port 3000 kapatiliyor...
powershell -Command "Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }" >nul 2>&1

echo.
echo  ========================================================
echo    TUM SERVISLER KAPATILDI!
echo    Port 8080 (Frontend)  - Kapatildi
echo    Port 2223 (Backend)   - Kapatildi
echo    Port 3000 (Proxy)     - Kapatildi
echo  ========================================================
echo.
pause
