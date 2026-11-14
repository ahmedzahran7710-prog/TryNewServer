<#
  RZ-GM Installer v1.0   (ASCII only)

  What it does
    1. finds  ...\Game_bin\Resource\Script
    2. lists the npc scripts and their contact functions
    3. you pick ONE npc to host the GM board
    4. backs up the original file
    5. installs NPC_GM_Board.lua  +  hook line
    6. compresses it to .ela with RappelzCompress_v2.exe
    7. moves the .lua out of the folder (server reads .ela)

  Usage
    powershell -ExecutionPolicy Bypass -File .\GM-Install.ps1
    powershell -ExecutionPolicy Bypass -File .\GM-Install.ps1 -Uninstall
#>

param(
    [string]$ScriptDir = "",
    [string]$Compressor = "",
    [switch]$Uninstall,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$BoardFile = Join-Path $PSScriptRoot "lua\NPC_GM_Board.lua"

function Say($m) { Write-Host $m }
function Okay($m) { Write-Host "  OK   $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  WARN $m" -ForegroundColor Yellow }
function Bad($m)  { Write-Host "  FAIL $m" -ForegroundColor Red }

Say ""
Say "=============================================="
Say "  RZ-GM Installer v1.0"
Say "=============================================="

# ------------------------------------------------------------------ locate
if ([string]::IsNullOrWhiteSpace($ScriptDir)) {
    Say ""
    Say "Searching for Game_bin\Resource\Script ..."
    $roots = @("C:\RZ", "F:\AhmedZahran", "D:\")
    foreach ($r in $roots) {
        if (-not (Test-Path $r)) { continue }
        $hit = Get-ChildItem -Path $r -Directory -Recurse -Filter "Script" -ErrorAction SilentlyContinue |
               Where-Object { $_.FullName -like "*Game_bin*" } |
               Select-Object -First 1
        if ($hit -ne $null) { $ScriptDir = $hit.FullName; break }
    }
}

if ([string]::IsNullOrWhiteSpace($ScriptDir) -or -not (Test-Path $ScriptDir)) {
    Bad "Script folder not found."
    Say ""
    Say "Run it again and pass the folder, for example:"
    Say '  powershell -ExecutionPolicy Bypass -File .\GM-Install.ps1 -ScriptDir "C:\RZ\Server\FilesOfficial-Revolution9.1\Server\GameEngine\Game_bin\Resource\Script"'
    exit 1
}
Okay "Script folder: $ScriptDir"

# ------------------------------------------------------------------ uninstall
$backupDir = Join-Path $ScriptDir "_rzgm_backup"

if ($Uninstall) {
    Say ""
    Say "UNINSTALL mode"
    $ela = Join-Path $ScriptDir "NPC_GM_Board.ela"
    if (Test-Path $ela) { Remove-Item $ela -Force; Okay "removed NPC_GM_Board.ela" }
    $lua = Join-Path $ScriptDir "NPC_GM_Board.lua"
    if (Test-Path $lua) { Remove-Item $lua -Force; Okay "removed NPC_GM_Board.lua" }
    if (Test-Path $backupDir) {
        Get-ChildItem $backupDir -File | ForEach-Object {
            Copy-Item $_.FullName (Join-Path $ScriptDir $_.Name) -Force
            Okay "restored $($_.Name)"
        }
    }
    Say ""
    Say "Done. Restart the game server."
    exit 0
}

# ------------------------------------------------------------------ board file
if (-not (Test-Path $BoardFile)) {
    Bad "Missing board file: $BoardFile"
    exit 1
}
Okay "Board file found"

# ------------------------------------------------------------------ list npc scripts
Say ""
Say "Scanning npc scripts ..."
$scripts = Get-ChildItem $ScriptDir -File -Filter "*.lua" | Sort-Object Name
if ($scripts.Count -eq 0) {
    Bad "No .lua files in the Script folder."
    Say "If only .ela files exist, extract them first, or install by editing the hook name manually."
    exit 1
}

$rows = @()
foreach ($s in $scripts) {
    $txt = Get-Content $s.FullName -Raw -ErrorAction SilentlyContinue
    if ($txt -eq $null) { continue }
    $m = [regex]::Matches($txt, "function\s+(NPC_[A-Za-z0-9_]+)_contact")
    foreach ($mm in $m) {
        $rows += [pscustomobject]@{
            File = $s.Name
            Npc  = $mm.Groups[1].Value
            Fn   = $mm.Groups[1].Value + "_contact"
        }
    }
}

if ($rows.Count -eq 0) {
    Bad "No NPC_*_contact function found in any .lua file."
    Say "Open one script and look for the function that runs when a player talks to the npc."
    exit 1
}

Say ""
Say "Choose the NPC that will host the GM board."
Say "(normal players keep seeing the ORIGINAL dialog - only your GM name sees the board)"
Say ""
$i = 0
foreach ($r in $rows) {
    $i++
    Say ("  [{0,2}] {1,-38}  {2}" -f $i, $r.Fn, $r.File)
}
Say ""

$pick = Read-Host "Number of the NPC"
$idx = 0
if (-not [int]::TryParse($pick, [ref]$idx) -or $idx -lt 1 -or $idx -gt $rows.Count) {
    Bad "Invalid choice."
    exit 1
}
$chosen = $rows[$idx - 1]
Okay ("Chosen: " + $chosen.Fn)

# ------------------------------------------------------------------ backup
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
$srcPath = Join-Path $ScriptDir $chosen.File
$bakPath = Join-Path $backupDir $chosen.File
if (-not (Test-Path $bakPath)) {
    Copy-Item $srcPath $bakPath -Force
    Okay "backup: $bakPath"
} else {
    Warn "backup already exists (kept): $bakPath"
}

# ------------------------------------------------------------------ build board
Say ""
Say "Building NPC_GM_Board.lua ..."
$board = Get-Content $BoardFile -Raw
$hook = "`r`n-- installed by GM-Install.ps1`r`nGM.install_hook(`"$($chosen.Fn)`")`r`n"
$outLua = Join-Path $ScriptDir "NPC_GM_Board.lua"
$final = $board + $hook

if ($DryRun) {
    Say "DRY RUN - nothing written."
    Say $final.Substring($final.Length - 200)
    exit 0
}

Set-Content -Path $outLua -Value $final -Encoding ASCII -NoNewline
Okay "written: $outLua"

# ------------------------------------------------------------------ compress
Say ""
Say "Compressing to .ela ..."
if ([string]::IsNullOrWhiteSpace($Compressor)) {
    $cands = Get-ChildItem -Path (Split-Path $ScriptDir -Parent) -Filter "RappelzCompress*.exe" -Recurse -ErrorAction SilentlyContinue
    if ($cands.Count -eq 0) {
        $cands = Get-ChildItem -Path "C:\RZ" -Filter "RappelzCompress*.exe" -Recurse -ErrorAction SilentlyContinue |
                 Select-Object -First 1
    }
    if ($cands -ne $null -and $cands.Count -gt 0) { $Compressor = $cands[0].FullName }
}

if ([string]::IsNullOrWhiteSpace($Compressor) -or -not (Test-Path $Compressor)) {
    Warn "RappelzCompress not found."
    Say ""
    Say "Do it manually:"
    Say "  1) drag  $outLua  onto RappelzCompress_v2.exe"
    Say "  2) delete NPC_GM_Board.lua from the Script folder (keep only the .ela)"
    exit 2
}

Okay "compressor: $Compressor"
& $Compressor $outLua | Out-Null
Start-Sleep -Seconds 2

$ela = Join-Path $ScriptDir "NPC_GM_Board.ela"
if (Test-Path $ela) {
    Okay "created NPC_GM_Board.ela"
    Remove-Item $outLua -Force
    Okay "removed the source .lua (server reads .ela)"
} else {
    Bad "compression did not produce NPC_GM_Board.ela"
    Say "Compress manually, then delete the .lua file."
    exit 3
}

Say ""
Say "=============================================="
Say "  INSTALLED"
Say "=============================================="
Say "1. Start the server as usual."
Say "2. In the game server console look for:"
Say "     [RZ-GM] Board v1.0 loaded."
Say "     [RZ-GM] hook installed on $($chosen.Fn)"
Say "3. Log in with your GM character and talk to that NPC."
Say "4. Open [Capability report] and send me the console output."
Say ""
Say "To undo everything:  .\GM-Install.ps1 -Uninstall"
