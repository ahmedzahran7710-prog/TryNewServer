@echo off
REM ============================================================
REM  START-GM-TOOL.cmd  --  launcher for GM-Tool v2.0 GUI
REM  Parses GM-Tool.ps1 first (shows exact error line), then GUI.
REM  ASCII only / CRLF
REM ============================================================
setlocal
cd /d "%~dp0"
title RZ-GM Tool v2.0 Launcher

echo.
echo ==============================================
echo   RZ-GM Tool v2.0 launcher
echo ==============================================

REM ---- 0) launcher marker (works even if PS never runs) --------
>> GM-Tool-last.log echo [%date% %time%] launcher started, cd=%CD%

REM ---- 1) PowerShell present? --------------------------------
where powershell >nul 2>&1
if errorlevel 1 (
  echo FAIL: PowerShell not found on this PC.
  pause
  exit /b 1
)

REM ---- 2) GM-Tool.ps1 present? -------------------------------
if not exist "GM-Tool.ps1" (
  echo FAIL: GM-Tool.ps1 not found in:
  echo   %CD%
  echo Download GM-Tool.ps1 into this folder and run again.
  pause
  exit /b 1
)
echo [OK] GM-Tool.ps1 found

if not exist "GM-UI-ar.txt" echo WARN: GM-UI-ar.txt missing - UI will be English.
if not exist "GM-Buffs-ar.csv" echo WARN: GM-Buffs-ar.csv missing - buff list empty.

REM ---- 3) PARSE CHECK (exact line numbers on failure) ---------
echo Checking GM-Tool.ps1 syntax ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$e=$null; $t=$null; [void][System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path '.\GM-Tool.ps1'), [ref]$t, [ref]$e); if($e.Count -gt 0){ $msg = ($e | ForEach-Object { 'PARSE ERROR line ' + $_.Extent.StartLineNumber + ': ' + $_.Message }) -join [Environment]::NewLine; Add-Content -LiteralPath '.\GM-Tool-last.log' -Value $msg; Write-Host $msg -ForegroundColor Red; exit 1 } else { Add-Content -LiteralPath '.\GM-Tool-last.log' -Value 'PARSE OK'; Write-Host '[OK] syntax parse OK' -ForegroundColor Green; exit 0 }"
if errorlevel 1 (
  echo.
  echo ==============================================
  echo   SYNTAX ERRORS FOUND - see message above
  echo   and GM-Tool-last.log
  echo ==============================================
  pause
  exit /b 1
)

REM ---- 4) SQL Server service ---------------------------------
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
  goto :LAUNCH
)

echo WARN: no SQL Server service detected by name.

:LAUNCH
REM ---- 5) open the GUI --------------------------------------
REM   Use -Command + call operator with RELATIVE path so the
REM   Arabic folder name never goes through cmd argument parsing.
REM   Any startup exception is caught, logged, and shown.
echo Opening GM-Tool GUI ...
>> GM-Tool-last.log echo [%date% %time%] launching GUI...
start "" powershell -NoProfile -STA -ExecutionPolicy Bypass -Command "try { & '.\GM-Tool.ps1' } catch { $m = 'LAUNCH ERROR: ' + ($_ | Out-String); try { Add-Content -LiteralPath '.\GM-Tool-last.log' -Value $m } catch {}; try { [System.Windows.Forms.MessageBox]::Show($m, 'RZ-GM Tool failed') } catch { Write-Host $m }; Read-Host 'Press Enter to close' }"
echo [OK] launcher done. If no window opened, check GM-Tool-last.log
echo.
exit /b 0
