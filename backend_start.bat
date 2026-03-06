@echo off
title Django Backend (Waitress - Port 2223)
cd /d "%~dp0\finans_backend"

echo [1/2] Sanal Ortam Aktif Ediliyor...
call venv\Scripts\activate

echo [2/2] Waitress sunucusu 0.0.0.0:2223 uzerinde baslatiliyor...
waitress-serve --listen=0.0.0.0:2223 config.wsgi:application
