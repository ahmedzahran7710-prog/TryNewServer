@echo off
REM ============================================================
REM  INSTALL-v15.cmd  --  GM Board v1.5
REM  buffs by player name + permanent blessing
REM  ASCII only / CRLF
REM ============================================================
setlocal enabledelayedexpansion
set "S=C:\RZ\Server\FilesOfficial-Revolution9.1\GameEngine\Game_bin\Resource\Script"
set "B=%S%\_rzgm_backup\before_v15"

echo.
echo ==============================================
echo   GM Board v1.5 installer
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

echo [3/4] copying v1.5 ...
copy /Y "%~dp0lua\NPC_GM_Board_ready.lua" "%S%\NPC_GM_Board.lua" >nul
if errorlevel 1 (
  echo FAIL: could not copy the file.
  pause
  exit /b 1
)

echo [4/4] verifying ...
dir /b "%S%\NPC_GM_Board.lua"
powershell -NoProfile -Command "Get-Content -LiteralPath '%S%\NPC_GM_Board.lua' -Tail 3"

echo.
echo ==============================================
echo   INSTALLED - nothing else to do here.
echo ==============================================
echo   Restart GameServer, log in, talk to the
echo   auction NPC in Gaia. The board must open.
echo.
echo   New in v1.5:
echo     - New: Permanent blessing (all buffs, ~23 days)
echo     - Buffs can target a named player (no console needed)
echo     - version line shows: Board v1.5 loaded
echo.
pause
