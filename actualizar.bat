@echo off
rem Trae los ultimos cambios del repo y refresca Rainmeter
cd /d "%~dp0"
git pull
if exist "%ProgramFiles%\Rainmeter\Rainmeter.exe" (
  "%ProgramFiles%\Rainmeter\Rainmeter.exe" !RefreshApp
)
