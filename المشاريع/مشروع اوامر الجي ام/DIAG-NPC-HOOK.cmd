@echo off
REM ============================================================
REM  DIAG-NPC-HOOK.cmd  -- read-only diagnostic, nothing is changed
REM  Tells us WHY the GM board did not appear on the auction NPC
REM ============================================================
setlocal
set "S=C:\RZ\Server\FilesOfficial-Revolution9.1\GameEngine\Game_bin\Resource\Script"

echo.
echo ==============================================
echo   1) HOW the target function is declared
echo ==============================================
findstr /n /c:"NPC_Auction_Gaia_contact" "%S%\NPC_Auction.lua"

echo.
echo ==============================================
echo   2) Is the board file present? (.lua / .ela)
echo ==============================================
dir /b "%S%\NPC_GM_Board.lua" 2>nul
dir /b "%S%\npc_gm_board.ela" 2>nul
dir /b "%S%\NPC_GM_Board.ela" 2>nul
echo (blank line above = file missing)

echo.
echo ==============================================
echo   3) Last 6 lines of the board (should show install_hook)
echo ==============================================
powershell -NoProfile -Command "Get-Content -LiteralPath '%S%\NPC_GM_Board.lua' -Tail 6"

echo.
echo ==============================================
echo   4) Existing .ela / .lua pairs count (sanity)
echo ==============================================
dir /b "%S%\*.ela" | find /c /v "" 
dir /b "%S%\*.lua" | find /c /v ""

echo.
echo ==============================================
echo   5) Is ela_count or lua switch set in GameServer.opt?
echo ==============================================
findstr /i /c:"ela_count" "C:\RZ\Server\FilesOfficial-Revolution9.1\GameEngine\GameServer.opt"

echo.
echo ==============================================
echo   6) on_login.lua exists? (used for the next test)
echo ==============================================
dir /b "%S%\on_login.lua" 2>nul

echo.
echo DONE - take a screenshot of this window and send it.
pause
