@echo off
REM ============================================================
REM  INSTALL-v16.cmd  --  GM Board v2.0 (Arabic tabs)
REM  converts UTF-8 source to Windows-1256 for the game client
REM  ASCII only / CRLF
REM ============================================================
setlocal enabledelayedexpansion
set "S=C:\RZ\Server\FilesOfficial-Revolution9.1\GameEngine\Game_bin\Resource\Script"
set "B=%S%\_rzgm_backup\before_v16"

echo.
echo ==============================================
echo   GM Board v2.0 installer (Arabic)
echo ==============================================

if not exist "%S%" (
  echo FAIL: script folder not found:
  echo   %S%
  pause
  exit /b 1
)

if not exist "%B%" mkdir "%B%"

echo.
echo [1/4] backing up current files ...
if exist "%S%\NPC_GM_Board.lua" copy /Y "%S%\NPC_GM_Board.lua" "%B%\" >nul
if exist "%S%\npc_gm_board.ela" copy /Y "%S%\npc_gm_board.ela" "%B%\" >nul
echo       backup -^> %B%

echo [2/4] removing old board files ...
if exist "%S%\NPC_GM_Board.lua" del /Q "%S%\NPC_GM_Board.lua"
if exist "%S%\npc_gm_board.ela" del /Q "%S%\npc_gm_board.ela"
if exist "%S%\NPC_GM_Board.ela" del /Q "%S%\NPC_GM_Board.ela"

echo [3/4] copying v2.0 (UTF-8 -> Windows-1256) ...
powershell -NoProfile -Command ^
  "$src = Join-Path '%~dp0' 'lua\NPC_GM_Board_ready.lua';" ^
  "$txt = [IO.File]::ReadAllText($src, [Text.Encoding]::UTF8);" ^
  "[IO.File]::WriteAllText('%S%\NPC_GM_Board.lua', $txt, [Text.Encoding]::GetEncoding(1256))"
if errorlevel 1 (
  echo FAIL: could not convert/copy the file.
  pause
  exit /b 1
)

echo [4/4] verifying ...
dir /b "%S%\NPC_GM_Board.lua"
powershell -NoProfile -Command "Get-Content -LiteralPath '%S%\NPC_GM_Board.lua' -Tail 3 -Encoding Default"

echo.
echo ==============================================
echo   INSTALLED - restart GameServer, log in,
echo   talk to the auction NPC in Gaia.
echo   Version line: Board v2.0 loaded
echo ==============================================
echo   New in v2.0:
echo     - Arabic tabbed menus
echo     - Buff tab: name + code + power + duration
echo     - Target player picker (by name)
echo     - Server-wide buff tab (rates + world)
echo.
pause
