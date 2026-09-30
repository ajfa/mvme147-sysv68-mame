@echo off
rem Throw away every change made to the disk, so the next boot starts from the freshly installed system.
cd /d "%~dp0."
choice /m "This deletes ALL the changes made to the System V/68 disk. Go on"
if errorlevel 2 exit /b
if exist "%~dp0state\diff" rmdir /s /q "%~dp0state\diff"
echo Done: the next boot starts from the freshly installed system.
pause
