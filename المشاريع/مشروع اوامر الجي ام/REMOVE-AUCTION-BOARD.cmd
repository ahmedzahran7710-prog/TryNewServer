@echo off
REM ============================================================
REM  REMOVE-AUCTION-BOARD.cmd
REM  Completely removes the RZ-GM in-game board (auction NPC
REM  hook) from the Rappelz server. The auction NPC goes back
REM  to its normal dialog. ASCII only / CRLF.
REM ============================================================
setlocal enabledelayedexpansion
set "S=C:\RZ\Server\FilesOfficial-Revolution9.1\GameEngine\Game_bin\Resource\Script"

echo.
echo ==============================================
echo   REMOVE auction GM board - COMPLETE
echo ==============================================

if not exist "%S%" (
  echo FAIL: Script folder not found:
  echo   %S%
  echo Edit this file and change the S= line to your Script folder.
  pause
  exit /b 1
)
echo Script folder: %S%
echo.

echo [1/4] removing board files (all name variants) ...
set "FOUND=0"
for %%F in (NPC_GM_Board.lua NPC_GM_Board.ela npc_gm_board.lua npc_gm_board.ela) do (
  if exist "%S%\%%F" (
    del /Q "%S%\%%F"
    echo       deleted %%F
    set "FOUND=1"
  )
)
if "!FOUND!"=="0" echo       no board files found (already clean)

echo [2/4] restoring original npc files from backup ...
set "BAK=%S%\_rzgm_backup"
if exist "%BAK%" (
  set "RESTORED=0"
  for %%F in ("%BAK%\*.*") do (
    copy /Y "%%F" "%S%\" >nul
    echo       restored %%~nxF
    set "RESTORED=1"
  )
  if "!RESTORED!"=="0" echo       backup folder is empty
) else (
  echo       no backup folder (board never edited npc files - OK)
)

echo [3/4] scanning .lua files for leftover hook lines ...
set "HOOKED=0"
for %%F in ("%S%\*.lua") do (
  findstr /I /C:"GM.install_hook" "%%F" >nul 2>&1
  if not errorlevel 1 (
    echo       HOOK FOUND in %%~nxF - restoring from backup if possible
    set "HOOKED=1"
    if exist "%BAK%\%%F" (
      copy /Y "%BAK%\%%F" "%S%\" >nul
      echo       restored %%F from backup
    ) else (
      echo       WARNING: no backup for %%F - delete this file manually
    )
  )
)
if "!HOOKED!"=="0" echo       clean - no hook lines in any .lua

echo [4/4] final check ...
set "LEFT=0"
for %%F in (NPC_GM_Board.lua NPC_GM_Board.ela npc_gm_board.lua npc_gm_board.ela) do (
  if exist "%S%\%%F" (
    echo       STILL PRESENT: %%F
    set "LEFT=1"
  )
)
if "!LEFT!"=="1" (
  echo.
  echo RESULT: INCOMPLETE - delete the files above manually.
  pause
  exit /b 1
)

echo.
echo ==============================================
echo   DONE - auction board is GONE
echo ==============================================
echo   The auction NPC now shows its normal dialog
echo   for everyone (no GM hook left).
echo.
echo   Next: RESTART GameServer, then log in and
echo   talk to the auction NPC to confirm.
echo.
echo   Your GM tool is GM-Tool.ps1 (unchanged).
echo.
pause
