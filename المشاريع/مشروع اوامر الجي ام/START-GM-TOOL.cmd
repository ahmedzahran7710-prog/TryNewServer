@echo off
REM ============================================================
REM  START-GM-TOOL.cmd  --  launcher for GM-Tool v2.0 GUI
REM  Checks files, ensures SQL Server runs, opens the GUI.
REM  ASCII only / CRLF
REM ============================================================
setlocal
cd /d "%~dp0"
title RZ-GM Tool Launcher

echo.
echo ==============================================
echo   RZ-GM Tool v2.0 launcher
echo ==============================================

REM ---- 1) PowerShell present? --------------------------------
where powershell >nul 2>&1
if errorlevel 1 (
  echo FAIL: PowerShell not found on this PC.
  echo This tool needs Windows PowerShell 5.1 (built into Windows).
  pause
  exit /b 1
)

REM ---- 2) GM-Tool.ps1 present? -------------------------------
if not exist "%~dp0GM-Tool.ps1" (
  echo FAIL: GM-Tool.ps1 not found in:
  echo   %~dp0
  echo.
  echo Download it from GitHub (raw) into this folder, then run
  echo this launcher again.
  pause
  exit /b 1
)

REM ---- 2b) Arabic data files present? --------------------
if not exist "%~dp0GM-UI-ar.txt" (
  echo WARN: GM-UI-ar.txt missing - UI labels fall back to English.
)
if not exist "%~dp0GM-Buffs-ar.csv" (
  echo WARN: GM-Buffs-ar.csv missing - buff list will be empty.
)
echo [OK] GM-Tool.ps1 found

REM ---- 3) SQL Server service running? ------------------------
echo Checking SQL Server service ...
set "SQL_SVC="
sc query MSSQLSERVER >nul 2>&1
if not errorlevel 1 set "SQL_SVC=MSSQLSERVER"
if not defined SQL_SVC (
  sc query "MSSQL$SQLEXPRESS" >nul 2>&1
  if not errorlevel 1 set "SQL_SVC=MSSQL$SQLEXPRESS"
)

if defined SQL_SVC (
  sc query "%SQL_SVC%" | find "RUNNING" >nul 2>&1
  if not errorlevel 1 (
    echo [OK] SQL service already running: %SQL_SVC%
    goto :LAUNCH
  )
  echo Starting SQL service: %SQL_SVC% ...
  sc start "%SQL_SVC%" >nul 2>&1
  timeout /t 3 /nobreak >nul
  sc query "%SQL_SVC%" | find "RUNNING" >nul 2>&1
  if not errorlevel 1 (
    echo [OK] SQL service started: %SQL_SVC%
    goto :LAUNCH
  )
  echo WARN: could not start %SQL_SVC% automatically.
  echo       Open services.msc and start "SQL Server (...)" manually.
  goto :LAUNCH
)

echo WARN: no SQL Server service detected by name.
echo       If SQL is installed under another name, start it first.
echo       (services.msc)

:LAUNCH
REM ---- 4) open the GUI (STA, console visible so errors are not hidden) --
echo Opening GM-Tool GUI ...
start "" powershell -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0GM-Tool.ps1"
if errorlevel 1 (
  echo FAIL: could not start the GUI. See error above.
  pause
  exit /b 1
)
echo [OK] GM-Tool GUI is opening (auto-connects to 127.0.0.1).
echo If a red error box appears, send a photo of it.
echo Log file: GM-Tool-last.log (next to this script).
echo.
exit /b 0
