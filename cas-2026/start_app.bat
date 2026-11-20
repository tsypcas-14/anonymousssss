@echo off
rem Starts the SmartFarm app in SIMULATION mode on this PC and opens it in the browser.
rem For a phone on the same Wi-Fi, use start_app_phone.bat instead.
cd /d "%~dp0"
set PYTHONIOENCODING=utf-8
echo Starting SmartFarm... the browser opens in about 15 seconds. Close this window to stop.
echo Simulation: the greenhouse code to create an account is 123456
start "" /b cmd /c "timeout /t 15 /nobreak >nul & start http://localhost:8000"
".venv\Scripts\python.exe" -m uvicorn app.server.main:app --host 127.0.0.1 --port 8000
pause
