@echo off
rem Same as start_app.bat, but reachable from a phone on the same Wi-Fi.
rem Windows may ask to allow Python through the firewall: choose "Private networks".
rem Anyone on your Wi-Fi can then open and control the (simulated) farm. There is no password.
cd /d "%~dp0"
set PYTHONIOENCODING=utf-8
echo.
echo On your phone, open:  http://YOUR-PC-IP:8000   (your PC's IPv4 address is listed below)
echo In the Flutter app, enter the same address. Simulation greenhouse code: 123456
ipconfig | findstr /i "IPv4"
echo.
".venv\Scripts\python.exe" -m uvicorn app.server.main:app --host 0.0.0.0 --port 8000
pause
