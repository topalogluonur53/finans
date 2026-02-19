@echo off
title Finans Celery Worker & Beat
cd /d "%~dp0\finans_backend"

echo ========================================
echo Celery (Worker + Beat) Baslatiliyor...
echo Redis'in calistigindan emin olun!
echo ========================================

call venv\Scripts\activate
start "Celery Worker" cmd /c "celery -A config worker --loglevel=info -P eventlet"
start "Celery Beat" cmd /c "celery -A config beat --loglevel=info"

echo Celery baslatildi.
timeout /t 5
