@echo off
rem Motorola MVME147 (68030) with System V/68 R3V7, booting from its SCSI disk.
cd /d "%~dp0."
"%~dp0vme.exe" miniforce -vme:slot1 mvme147 -rompath "%~dp0roms" -inipath "%~dp0ini" ^
    -hard "%~dp0disk\sysv68-r3v7.chd" -diff_directory "%~dp0state\diff" ^
    -nvram_directory "%~dp0state\nvram" -cfg_directory "%~dp0state\cfg" ^
    -snapshot_directory "%~dp0snapshots" -autoboot_script "%~dp0autoboot.lua" ^
    -window -nomaximize -skip_gameinfo -natural %*
if errorlevel 1 pause
