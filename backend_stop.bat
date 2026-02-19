@echo off
echo Port 2223 uzerindeki Waitress sunucusu durduruluyor...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :2223 ^| findstr LISTENING') do (
    taskkill /F /PID %%a
)
echo Backend durduruldu.
pause
