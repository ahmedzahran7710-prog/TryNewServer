<#
  RZ-GM Tool v2.0  --  Tabbed Windows GUI for Rappelz 9.1
  ASCII ONLY in this file. Arabic labels live in:
    GM-UI-ar.txt    (UTF-8)  - UI strings
    GM-Buffs-ar.csv (UTF-8)  - buff catalog (name / power / code / minutes)

  Tabs: Player | Buffs (Arabic) | Server-wide | Tools
  Connection: 127.0.0.1 / Telecaster1 / rappelz / (empty pass)

  Run:  START-GM-TOOL.cmd   or
        powershell -NoProfile -STA -ExecutionPolicy Bypass -File .\GM-Tool.ps1
#>

param([switch]$SelfTest)

if ($SelfTest) {
    Write-Host "GM-Tool.ps1 v2.0 self-test: file loads and parses OK."
    exit 0
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ---- master guard: never die silently ----
try {
    try {
        $bootLog = Join-Path $PSScriptRoot "GM-Tool-last.log"
        if ([string]::IsNullOrEmpty($PSScriptRoot)) { $bootLog = Join-Path (Get-Location).Path "GM-Tool-last.log" }
        [System.IO.File]::AppendAllText($bootLog, "=== GM-Tool v2.0 starting " + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") + " ===`r`n", [System.Text.Encoding]::UTF8)
    } catch { }

# ---------------------------------------------------------------- global state
$script:Conn = $null
$script:SelectedSid = $null
$script:SelectedName = $null



if ($SelfTest) {
    Write-Host "GM-Tool.ps1 self-test: file loads and parses OK."
    Write-Host "GUI needs Windows + .NET WinForms (PowerShell 5.1)."
    exit 0
}


# ---------------------------------------------------------------- helpers


function Log([string]$msg) {
    $ts = (Get-Date).ToString('HH:mm:ss')
    $line = "[$ts] $msg"
    try {
        if ($null -ne $txtLog) {
            $txtLog.AppendText($line + "`r`n")
            $txtLog.SelectionStart = $txtLog.Text.Length
            $txtLog.ScrollToCaret()
            [System.Windows.Forms.Application]::DoEvents()
        }
    } catch { }
    try {
        $logPath = Join-Path $script:Root "GM-Tool-last.log"
        [System.IO.File]::AppendAllText($logPath, $line + "`r`n", [System.Text.Encoding]::UTF8)
    } catch { }
}

function Connect-Db {
    $base = "Server=$($txtServer.Text);Database=$($txtDb.Text);TrustServerCertificate=True;Connect Timeout=5;"
    $sqlAuth = $base + "User Id=$($txtUser.Text);Password=$($txtPass.Text);"
    $winAuth = $base + "Integrated Security=True;"

    $attempts = @()
    $attempts += ,@("SQL login '$($txtUser.Text)'", $sqlAuth)
    $attempts += ,@("Windows login", $winAuth)

    $lastErr = ""
    foreach ($a in $attempts) {
        try {
            if ($script:Conn -ne $null) { $script:Conn.Close(); $script:Conn = $null }
            $c = New-Object System.Data.SqlClient.SqlConnection $a[1]
            $c.Open()
            $script:Conn = $c
            $lblStatus.Text = "Connected"
            $lblStatus.ForeColor = [System.Drawing.Color]::Green
            Log ("Connected with " + $a[0] + " -> " + $txtServer.Text + " / " + $txtDb.Text)
            Load-Characters
            return
        }
        catch {
            $lastErr = $_.Exception.Message
            Log ("try " + $a[0] + " failed: " + $lastErr)
        }
    }

    $lblStatus.Text = "Not connected"
    $lblStatus.ForeColor = [System.Drawing.Color]::Red
    Log "CONNECT FAILED."
    Log "Working combo on THIS server:"
    Log "  Server = 127.0.0.1   DB = Telecaster1"
    Log "  User   = rappelz     Pass = (leave empty)"
    Log "Then press Connect again. Windows login is tried as fallback."
    Log "If SQL Server service is stopped, start it first (services.msc)."
}

function Load-Characters {
    if ($script:Conn -eq $null) { Log "Not connected."; return }
    try {
        $q = "SELECT TOP 300 sid, name, lv, gold, permission FROM dbo.Character WHERE name LIKE @f ORDER BY lv DESC"
        $cmd = $script:Conn.CreateCommand()
        $cmd.CommandText = $q
        [void]$cmd.Parameters.AddWithValue("@f", "%" + $txtFilter.Text + "%")
        $dt = New-Object System.Data.DataTable
        $da = New-Object System.Data.SqlClient.SqlDataAdapter $cmd
        [void]$da.Fill($dt)
        $grid.DataSource = $dt
        if ($grid.Columns.Count -gt 0) {
            $grid.Columns['sid'].Width = 60
            $grid.Columns['name'].Width = 150
            $grid.Columns['lv'].Width = 60
            $grid.Columns['gold'].Width = 110
            $grid.Columns['permission'].Width = 70
        }
        Log "Loaded $($dt.Rows.Count) character(s)."
        # fill buff-tab target dropdown
        try {
            if ($null -ne $script:cmbTarget) {
                $script:cmbTarget.Items.Clear()
                foreach ($r in $dt.Rows) {
                    [void]$script:cmbTarget.Items.Add([string]$r["name"] + " (sid " + [string]$r["sid"] + ")")
                }
                if ($script:cmbTarget.Items.Count -gt 0) { $script:cmbTarget.SelectedIndex = 0 }
            }
        } catch { }
    }
    catch { Log ("LOAD FAILED: " + $_.Exception.Message) }
}

function Get-Sid {
    if ($script:SelectedSid -eq $null) { Log "Select a character first."; return $null }
    return $script:SelectedSid
}

function Require-Backup {
    if (-not $chkBackup.Checked) {
        Log "BLOCKED: tick [I have a backup] first."
        return $false
    }
    if ($script:Conn -eq $null) { Log "BLOCKED: not connected."; return $false }
    return $true
}

function Exec([string]$sql, $pars) {
    $cmd = $script:Conn.CreateCommand()
    $cmd.CommandText = $sql
    foreach ($k in $pars.Keys) { [void]$cmd.Parameters.AddWithValue($k, $pars[$k]) }
    try {
        $n = $cmd.ExecuteNonQuery()
        Log "OK ($n row)."
        return $true
    }
    catch { Log ("SQL FAILED: " + $_.Exception.Message); return $false }
}


function Do-Schema {
    if ($script:Conn -eq $null) { Log "Not connected."; return }
    try {
        $q1 = "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS " +
              "WHERE TABLE_NAME = 'Character' ORDER BY ORDINAL_POSITION"
        $cmd = $script:Conn.CreateCommand(); $cmd.CommandText = $q1
        $r = $cmd.ExecuteReader()
        $cols = @()
        while ($r.Read()) { $cols += ($r.GetString(0) + ":" + $r.GetString(1)) }
        $r.Close()
        Log ("---- Character columns (" + $cols.Count + ") ----")
        foreach ($c in $cols) { Log $c }
        Log "---- end columns ----"

        $q2 = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES " +
              "WHERE TABLE_NAME LIKE '%Item%' OR TABLE_NAME LIKE '%Inven%' ORDER BY TABLE_NAME"
        $cmd2 = $script:Conn.CreateCommand(); $cmd2.CommandText = $q2
        $r2 = $cmd2.ExecuteReader()
        $t = @()
        while ($r2.Read()) { $t += $r2.GetString(0) }
        $r2.Close()
        Log ("---- item/inventory tables (" + $t.Count + ") ----")
        foreach ($x in $t) { Log $x }
        Log "---- end tables ----"
        Log "Send this log to Ahmed: it decides how gifts are inserted."
    }
    catch { Log ("SCHEMA FAILED: " + $_.Exception.Message) }
}


function Log-Rows([string]$sql, [string]$title, [int]$max = 40) {
    try {
        $cmd = $script:Conn.CreateCommand()
        $cmd.CommandText = $sql
        $r = $cmd.ExecuteReader()
        Log ("---- " + $title + " ----")
        $n = 0
        while ($r.Read()) {
            $n++
            if ($n -le $max) {
                $parts = @()
                for ($i = 0; $i -lt $r.FieldCount; $i++) { $parts += ([string]$r.GetValue($i)) }
                Log ($parts -join " | ")
            }
        }
        $r.Close()
        if ($n -eq 0) { Log "(no rows)" }
        Log ("---- end " + $title + " (" + $n + ") ----")
    }
    catch { Log ("QUERY FAILED [" + $title + "]: " + $_.Exception.Message) }
}

function Do-ItemInfo {
    if ($script:Conn -eq $null) { Log "Not connected."; return }
    Log-Rows "SELECT name FROM sys.objects WHERE type='P' AND (name LIKE '%item%' OR name LIKE '%insert%') ORDER BY name" "item procedures" 60
    Log-Rows "SELECT p.parameter_id AS pos, p.name AS param, t.name AS type FROM sys.parameters p JOIN sys.types t ON t.user_type_id = p.user_type_id WHERE p.object_id = OBJECT_ID('dbo.smp_insert_item') ORDER BY p.parameter_id" "smp_insert_item parameters" 60
    Log-Rows "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='Item' ORDER BY ORDINAL_POSITION" "Item columns" 80
    Log-Rows "SELECT TOP 15 i.id, i.type, i.item_use_flag, s.value FROM Arcadia.dbo.ItemResource i LEFT JOIN Arcadia.dbo.StringResource s ON s.code = i.name_id WHERE s.value LIKE '%Box%' OR s.value LIKE '%Bag%' OR s.value LIKE '%Package%' ORDER BY i.id" "sample bag/box items (Arcadia)" 20
    Log "Send this block to Ahmed: it is enough to build the gift button."
}

function Show-Points {
    if ($script:Conn -eq $null) { Log "Not connected."; return }
    $sid = Get-Sid; if ($sid -eq $null) { return }
    Log-Rows ("SELECT name, lv, talent_point, jp, total_jp, exp FROM dbo.[Character] WHERE sid=" + $sid) ("points of " + $script:SelectedName) 5
}

function Do-AddTalent {
    if (-not (Require-Backup)) { return }
    $sid = Get-Sid; if ($sid -eq $null) { return }
    $v = 0; if (-not [int]::TryParse($txtTalent.Text, [ref]$v)) { Log "Talent amount must be a number."; return }
    $ok = Exec "UPDATE dbo.[Character] SET talent_point = talent_point + @v WHERE sid=@sid" @{ '@v' = $v; '@sid' = $sid }
    if ($ok) { Log "+$v talent_point for $($script:SelectedName)"; Show-Points }
}

function Do-AddJp {
    if (-not (Require-Backup)) { return }
    $sid = Get-Sid; if ($sid -eq $null) { return }
    $v = [int64]0; if (-not [int64]::TryParse($txtJpAdd.Text, [ref]$v)) { Log "JP amount must be a number."; return }
    $ok = Exec "UPDATE dbo.[Character] SET jp = jp + @v, total_jp = total_jp + @v WHERE sid=@sid" @{ '@v' = $v; '@sid' = $sid }
    if ($ok) { Log "+$v jp for $($script:SelectedName)"; Show-Points }
}


function Do-GiftPrep {
    if ($script:Conn -eq $null) { Log "Not connected."; return }
    Log-Rows "SELECT p.parameter_id AS pos, p.name AS param, t.name AS type FROM sys.parameters p JOIN sys.types t ON t.user_type_id = p.user_type_id WHERE p.object_id = OBJECT_ID('dbo.gmtool_v2_cheat_insert_item') ORDER BY p.parameter_id" "gmtool_v2_cheat_insert_item parameters" 40
    Log-Rows "SELECT p.parameter_id AS pos, p.name AS param, t.name AS type FROM sys.parameters p JOIN sys.types t ON t.user_type_id = p.user_type_id WHERE p.object_id = OBJECT_ID('dbo.gmtool_cheat_give_item_useSid') ORDER BY p.parameter_id" "gmtool_cheat_give_item_useSid parameters" 40
    Log-Rows "SELECT TOP 2 * FROM dbo.[Item]" "live Item rows (sample)" 3
    Log-Rows "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='EventItemSupplyInfo' ORDER BY ORDINAL_POSITION" "EventItemSupplyInfo columns" 40
    Log-Rows "SELECT LEFT(OBJECT_DEFINITION(OBJECT_ID('dbo.smp_insert_item')), 3500) AS proc_text" "smp_insert_item source (start)" 1
    Log "Send this block to Ahmed: the gift button is built from it."
}

function Do-SafeQuery {
    if ($script:Conn -eq $null) { Log "Not connected."; return }
    $q = ($txtQuery.Text).Trim()
    if ($q -eq "") { Log "Type a SELECT query first."; return }
    $u = $q.ToUpper()
    if (-not $u.StartsWith("SELECT")) { Log "BLOCKED: this box accepts SELECT only."; return }
    if ($q.Contains(";") -and $q.IndexOf(";") -lt ($q.Length - 1)) {
        Log "BLOCKED: one SELECT statement only (remove the semicolon)."
        return
    }
    Log-Rows $q "your query" 200
}


function Show-ItemCount($sid) {
    Log-Rows ("SELECT COUNT(*) AS items FROM dbo.[Item] WHERE owner_id=" + $sid) ("items now owned by sid " + $sid) 3
}

function Do-SendItem {
    if (-not (Require-Backup)) { return }
    $sid = Get-Sid; if ($sid -eq $null) { return }
    $code = 0; if (-not [int]::TryParse($txtItemCode.Text, [ref]$code)) { Log "Item code must be a number."; return }
    $cnt = [int64]1; if (-not [int64]::TryParse($txtItemCnt.Text, [ref]$cnt)) { Log "Count must be a number."; return }
    if ($code -le 0) { Log "Item code must be greater than 0."; return }
    $sql = "EXEC dbo.gmtool_v2_cheat_insert_item @character_id=@cid, @item_code=@code, " +
           "@enhance=0, @level=1, @cnt=@cnt, @endurance=0, @ethereal_durability=0, " +
           "@remain_time=0, @flag=0"
    Log ("sending item " + $code + " x" + $cnt + " to " + $script:SelectedName + " ...")
    $ok = Exec $sql @{ '@cid' = $sid; '@code' = $code; '@cnt' = $cnt }
    if ($ok) {
        Log "DONE. The player must relog (log out and in) to see the item."
        Show-ItemCount $sid
    }
}

function Do-SendItemAll {
    if (-not (Require-Backup)) { return }
    if ($grid.Rows.Count -lt 1) { Log "Search first so the list is filled."; return }
    $code = 0; if (-not [int]::TryParse($txtItemCode.Text, [ref]$code)) { Log "Item code must be a number."; return }
    $cnt = [int64]1; if (-not [int64]::TryParse($txtItemCnt.Text, [ref]$cnt)) { Log "Count must be a number."; return }
    $ans = [System.Windows.Forms.MessageBox]::Show(
        ("Send item " + $code + " x" + $cnt + " to EVERY character in the list (" + $grid.Rows.Count + ")?"),
        "Confirm event gift", [System.Windows.Forms.MessageBoxButtons]::YesNo)
    if ($ans -ne 'Yes') { Log "cancelled"; return }

    $sql = "EXEC dbo.gmtool_v2_cheat_insert_item @character_id=@cid, @item_code=@code, " +
           "@enhance=0, @level=1, @cnt=@cnt, @endurance=0, @ethereal_durability=0, " +
           "@remain_time=0, @flag=0"
    $sent = 0
    foreach ($row in $grid.Rows) {
        $cid = $row.Cells['sid'].Value
        $nm  = $row.Cells['name'].Value
        if ($cid -eq $null) { continue }
        if (Exec $sql @{ '@cid' = $cid; '@code' = $code; '@cnt' = $cnt }) {
            $sent++
            Log ("  -> " + $nm)
        }
    }
    Log ("EVENT DONE: item " + $code + " sent to " + $sent + " character(s). They must relog.")
}


function Do-BuffPrep {
    if ($script:Conn -eq $null) { Log "Not connected."; return }
    Log-Rows "SELECT name FROM sys.objects WHERE type='U' AND (name LIKE '%state%' OR name LIKE '%abnormal%' OR name LIKE '%buff%') ORDER BY name" "tables about states/buffs" 40
    Log-Rows "SELECT p.parameter_id AS pos, p.name AS param, t.name AS type FROM sys.parameters p JOIN sys.types t ON t.user_type_id = p.user_type_id WHERE p.object_id = OBJECT_ID('dbo.smp_insert_state') ORDER BY p.parameter_id" "smp_insert_state parameters" 40
    Log-Rows "SELECT c.TABLE_NAME, c.COLUMN_NAME, c.DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME='State' ORDER BY c.ORDINAL_POSITION" "State columns" 40
    Log-Rows "SELECT TOP 5 * FROM dbo.[State]" "live State rows (sample)" 6
    Log-Rows "SELECT name FROM sys.objects WHERE type='P' AND (name LIKE '%state%' OR name LIKE '%skill%') ORDER BY name" "state/skill procedures" 40
    Log "Send this block to Ahmed: the buff button is built from it."
}


function Show-StateList {
    if ($script:Conn -eq $null) { Log "Not connected."; return }
    $sid = Get-Sid; if ($sid -eq $null) { return }
    Log-Rows ("SELECT sid, code, level, duration, remain_time, enable FROM dbo.[State] WHERE owner_id=" + $sid + " ORDER BY code") ("buffs of " + $script:SelectedName) 40
}


function Do-ClearBuffs {
    if (-not (Require-Backup)) { return }
    $sid = Get-Sid; if ($sid -eq $null) { return }
    $ans = [System.Windows.Forms.MessageBox]::Show(
        ("Remove ALL buffs of " + $script:SelectedName + "?"), "Confirm",
        [System.Windows.Forms.MessageBoxButtons]::YesNo)
    if ($ans -ne 'Yes') { Log "cancelled"; return }
    $ok = Exec "DELETE FROM dbo.[State] WHERE owner_id=@cid" @{ '@cid' = $sid }
    if ($ok) { Log "buffs cleared for $($script:SelectedName)"; Show-StateList }
}

function Do-BlessAll {
    if (-not (Require-Backup)) { return }
    $sid = Get-Sid; if ($sid -eq $null) { return }
    $codes = @(
        @(1007,150), @(1008,150), @(1009,250), @(1010,450),
        @(1011,90),  @(1012,50),  @(1013,150), @(1014,100),
        @(1015,150), @(4102,50),  @(1513,60),  @(1507,50)
    )
    $min = 720
    if ($script:Root -and (Get-Command Get-DurMinutes -ErrorAction SilentlyContinue)) {
        $min = Get-DurMinutes
    }
    if ($min -lt 1 -or $min -gt 720) { $min = 720 }
    $dur = [int]($min * 60000)
    $ans = [System.Windows.Forms.MessageBox]::Show(
        ("Apply ALL 12 bless buffs (" + $min + " min) to " + $script:SelectedName + "?"),
        "Confirm bless", [System.Windows.Forms.MessageBoxButtons]::YesNo)
    if ($ans -ne 'Yes') { Log "cancelled"; return }
    $okAll = $true
    foreach ($pair in $codes) {
        $c = $pair[0]; $p = $pair[1]
        $sql = "DELETE FROM dbo.[State] WHERE owner_id=@cid AND code=@c; " +
               "DECLARE @nsid INT; SELECT @nsid = ISNULL(MAX(sid),0) + 1 FROM dbo.[State]; " +
               "EXEC dbo.smp_insert_state @IN_SID=@nsid, @IN_OWNER_ID=@cid, @IN_SUMMON_ID=0, " +
               "@IN_CODE=@c, @IN_LEVEL=@p, @IN_DURATION=@dur, @IN_REMAIN_TIME=@dur, " +
               "@IN_BASE_DAMAGE=0, @IN_REMAIN_FIRE_TIME=0, @IN_STATE_VALUE=0, " +
               "@IN_STATE_STRING_VALUE=N'', @IN_ENABLE=1"
        if (-not (Exec $sql @{ '@cid' = $sid; '@c' = $c; '@p' = $p; '@dur' = $dur })) {
            $okAll = $false
        }
    }
    if ($okAll) {
        Log ("BLESSED: 12 buffs, " + $min + " min -> " + $script:SelectedName)
        Log "Player must relog (log out and in) to see them."
        Show-StateList
    } else {
        Log "Bless finished WITH ERRORS - check log lines above."
    }
}

function Do-FindStates {
    if ($script:Conn -eq $null) { Log "Not connected."; return }
    Log-Rows "SELECT t.name AS tbl, c.name AS col, ty.name AS typ FROM Arcadia.sys.tables t JOIN Arcadia.sys.columns c ON c.object_id = t.object_id JOIN Arcadia.sys.types ty ON ty.user_type_id = c.user_type_id WHERE t.name LIKE '%State%' ORDER BY t.name, c.column_id" "Arcadia state tables + columns" 120
    Log-Rows "SELECT DISTINCT code FROM dbo.[State] ORDER BY code" "codes in use on this server" 60
    Log "Send this block to Ahmed: it names the buffs."
}

# ---------------------------------------------------------------- actions
function Do-SetGold {
    if (-not (Require-Backup)) { return }
    $sid = Get-Sid; if ($sid -eq $null) { return }
    $v = [int64]0; if (-not [int64]::TryParse($txtGold.Text, [ref]$v)) { Log "Gold must be a number."; return }
    $ok = Exec "UPDATE dbo.Character SET gold=@g WHERE sid=@sid" @{ '@g' = $v; '@sid' = $sid }
    if ($ok) { Log "gold = $v for $($script:SelectedName) (applies on next login)"; Load-Characters }
}

function Do-AddGold {
    if (-not (Require-Backup)) { return }
    $sid = Get-Sid; if ($sid -eq $null) { return }
    $v = [int64]0; if (-not [int64]::TryParse($txtAddGold.Text, [ref]$v)) { Log "Amount must be a number."; return }
    $ok = Exec "UPDATE dbo.Character SET gold=gold+@g WHERE sid=@sid" @{ '@g' = $v; '@sid' = $sid }
    if ($ok) { Log "+$v gold for $($script:SelectedName)"; Load-Characters }
}

function Do-SetLevel {
    if (-not (Require-Backup)) { return }
    $sid = Get-Sid; if ($sid -eq $null) { return }
    $v = 0; if (-not [int]::TryParse($txtLevel.Text, [ref]$v)) { Log "Level must be a number."; return }
    if ($v -lt 1 -or $v -gt 400) { Log "Level must be 1..400."; return }
    $ok = Exec "UPDATE dbo.Character SET lv=@l, max_reached_level=CASE WHEN max_reached_level<@l THEN @l ELSE max_reached_level END WHERE sid=@sid" @{ '@l' = $v; '@sid' = $sid }
    if ($ok) { Log "level = $v for $($script:SelectedName). Note: exp is not adjusted."; Load-Characters }
}

function Do-AddExp {
    if (-not (Require-Backup)) { return }
    $sid = Get-Sid; if ($sid -eq $null) { return }
    $e = [int64]0; if (-not [int64]::TryParse($txtExp.Text, [ref]$e)) { Log "Exp must be a number."; return }
    $j = [int64]0; if (-not [int64]::TryParse($txtJp.Text, [ref]$j)) { Log "Jp must be a number."; return }
    $ok = Exec "UPDATE dbo.Character SET exp=exp+@e, jp=jp+@j, total_jp=total_jp+@j WHERE sid=@sid" @{ '@e' = $e; '@j' = $j; '@sid' = $sid }
    if ($ok) { Log "exp +$e, jp +$j for $($script:SelectedName)" }
}

function Do-SetPermission {
    if (-not (Require-Backup)) { return }
    $sid = Get-Sid; if ($sid -eq $null) { return }
    $v = 0; if (-not [int]::TryParse($txtPerm.Text, [ref]$v)) { Log "Permission must be a number."; return }
    $ok = Exec "UPDATE dbo.Character SET permission=@p WHERE sid=@sid" @{ '@p' = $v; '@sid' = $sid }
    if ($ok) { Log "permission = $v for $($script:SelectedName)" ; Load-Characters }
}

function Do-Teleport {
    if (-not (Require-Backup)) { return }
    $sid = Get-Sid; if ($sid -eq $null) { return }
    $x = 0; $y = 0; $z = 0; $layer = 1
    if (-not [int]::TryParse($txtX.Text, [ref]$x)) { Log "x must be a number."; return }
    if (-not [int]::TryParse($txtY.Text, [ref]$y)) { Log "y must be a number."; return }
    if (-not [int]::TryParse($txtZ.Text, [ref]$z)) { Log "z must be a number."; return }
    if (-not [int]::TryParse($txtLayer.Text, [ref]$layer)) { Log "layer must be a number."; return }
    $ok = Exec "UPDATE dbo.Character SET x=@x, y=@y, z=@z, layer=@l WHERE sid=@sid" @{ '@x' = $x; '@y' = $y; '@z' = $z; '@l' = $layer; '@sid' = $sid }
    if ($ok) { Log "teleport $($script:SelectedName) -> layer $layer ($x,$y,$z)" }
}

function Do-SetGoldAll {
    if (-not (Require-Backup)) { return }
    $v = [int64]0; if (-not [int64]::TryParse($txtGold.Text, [ref]$v)) { Log "Gold must be a number."; return }
    $ans = [System.Windows.Forms.MessageBox]::Show(
        "Set gold = $v for EVERY character in the database?", "Confirm",
        [System.Windows.Forms.MessageBoxButtons]::YesNo)
    if ($ans -ne 'Yes') { Log "cancelled"; return }
    $ok = Exec "UPDATE dbo.Character SET gold=@g WHERE delete_time IS NULL" @{ '@g' = $v }
    if ($ok) { Log "gold = $v for ALL characters"; Load-Characters }
}

function Do-BlockAccount {
    if (-not (Require-Backup)) { return }
    $sid = Get-Sid; if ($sid -eq $null) { return }
    try {
        $cmd = $script:Conn.CreateCommand()
        $cmd.CommandText = "SELECT account_id FROM dbo.Character WHERE sid=@sid"
        [void]$cmd.Parameters.AddWithValue("@sid", $script:SelectedSid)
        $acc = $cmd.ExecuteScalar()
        if ($acc -eq $null) { Log "account_id not found."; return }
        $val = 1; if (-not $chkBlock.Checked) { $val = 0 }
        $ok = Exec "UPDATE [Auth].[dbo].[Accounts] SET block=@b WHERE account_id=@a" @{ '@b' = $val; '@a' = $acc }
        if ($ok) { Log "account $acc block = $val" }
    }
    catch { Log ("BLOCK FAILED: " + $_.Exception.Message) }
}


# ============================================================
#  DATA FILES (UTF-8) - Arabic labels live here, not in this file
# ============================================================
$script:Root = $null
try { if (-not [string]::IsNullOrEmpty($PSScriptRoot)) { $script:Root = $PSScriptRoot } } catch { }
if ([string]::IsNullOrEmpty($script:Root)) {
    try { $script:Root = (Get-Location).Path } catch { }
}
if ([string]::IsNullOrEmpty($script:Root)) { $script:Root = [System.IO.Path]::GetTempPath() }
$script:UI = @{}
$script:BuffCat = @()

function Load-Utf8Lines([string]$path) {
    if (-not (Test-Path $path)) { return @() }
    return [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)
}

function Load-UiStrings {
    try {
        $p = Join-Path $script:Root "GM-UI-ar.txt"
        foreach ($line in (Load-Utf8Lines $p)) {
            try {
                $t = $line.Trim()
                if ($t -eq "" -or $t.StartsWith("#")) { continue }
                $i = $t.IndexOf("=")
                if ($i -gt 0) {
                    $k = $t.Substring(0, $i)
                    $v = $t.Substring($i + 1)
                    $script:UI[$k] = $v
                }
            } catch { }
        }
    } catch { }
}
function U([string]$k, [string]$fb) {
    if ($script:UI.ContainsKey($k)) { return $script:UI[$k] }
    return $fb
}

function Load-BuffCatalog {
    $script:BuffCat = @()
    try {
        $p = Join-Path $script:Root "GM-Buffs-ar.csv"
        foreach ($line in (Load-Utf8Lines $p)) {
            try {
                $t = $line.Trim()
                if ($t -eq "" -or $t.StartsWith("#")) { continue }
                $p2 = $t.Split(",")
                if ($p2.Count -ge 4) {
                    $code = 0; $pow = 0; $mn = 0
                    if (-not [int]::TryParse($p2[0].Trim(), [ref]$code)) { continue }
                    if (-not [int]::TryParse($p2[1].Trim(), [ref]$pow)) { continue }
                    if (-not [int]::TryParse($p2[2].Trim(), [ref]$mn)) { continue }
                    $script:BuffCat += ,@{
                        Code  = $code
                        Power = $pow
                        Min   = $mn
                        Name  = $p2[3].Trim()
                    }
                }
            } catch { }
        }
    } catch { }
}

try { Load-UiStrings } catch { }
try { Load-BuffCatalog } catch { }

# ============================================================
#  FORM + CONNECTION ROW
# ============================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "RZ-GM Tool v2.0  -  Rappelz 9.1"
$form.Size = New-Object System.Drawing.Size(1000, 780)
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$lbl1 = New-Object System.Windows.Forms.Label
$lbl1.Text = "Server"; $lbl1.Location = New-Object System.Drawing.Point(10, 14); $lbl1.Size = New-Object System.Drawing.Size(50, 20)
$form.Controls.Add($lbl1)

$txtServer = New-Object System.Windows.Forms.TextBox
$txtServer.Text = "127.0.0.1"
$txtServer.Location = New-Object System.Drawing.Point(62, 11); $txtServer.Size = New-Object System.Drawing.Size(200, 24)
$form.Controls.Add($txtServer)

$lbl2 = New-Object System.Windows.Forms.Label
$lbl2.Text = "DB"; $lbl2.Location = New-Object System.Drawing.Point(270, 14); $lbl2.Size = New-Object System.Drawing.Size(30, 20)
$form.Controls.Add($lbl2)

$txtDb = New-Object System.Windows.Forms.TextBox
$txtDb.Text = "Telecaster1"
$txtDb.Location = New-Object System.Drawing.Point(302, 11); $txtDb.Size = New-Object System.Drawing.Size(110, 24)
$form.Controls.Add($txtDb)

$lbl3 = New-Object System.Windows.Forms.Label
$lbl3.Text = "User"; $lbl3.Location = New-Object System.Drawing.Point(420, 14); $lbl3.Size = New-Object System.Drawing.Size(36, 20)
$form.Controls.Add($lbl3)

$txtUser = New-Object System.Windows.Forms.TextBox
$txtUser.Text = "rappelz"
$txtUser.Location = New-Object System.Drawing.Point(458, 11); $txtUser.Size = New-Object System.Drawing.Size(90, 24)
$form.Controls.Add($txtUser)

$lbl4 = New-Object System.Windows.Forms.Label
$lbl4.Text = "Pass"; $lbl4.Location = New-Object System.Drawing.Point(556, 14); $lbl4.Size = New-Object System.Drawing.Size(36, 20)
$form.Controls.Add($lbl4)

$txtPass = New-Object System.Windows.Forms.TextBox
$txtPass.UseSystemPasswordChar = $true
$txtPass.Location = New-Object System.Drawing.Point(594, 11); $txtPass.Size = New-Object System.Drawing.Size(90, 24)
$form.Controls.Add($txtPass)

$btnConnect = New-Object System.Windows.Forms.Button
$btnConnect.Text = "Connect"
$btnConnect.Location = New-Object System.Drawing.Point(692, 9); $btnConnect.Size = New-Object System.Drawing.Size(90, 26)
$btnConnect.Add_Click({ Connect-Db })
$form.Controls.Add($btnConnect)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Not connected"
$lblStatus.ForeColor = [System.Drawing.Color]::Red
$lblStatus.Location = New-Object System.Drawing.Point(790, 14); $lblStatus.Size = New-Object System.Drawing.Size(110, 20)
$form.Controls.Add($lblStatus)

$lblSel = New-Object System.Windows.Forms.Label
$lblSel.Text = (U "lbl.selected" "Selected") + ": none"
$lblSel.Location = New-Object System.Drawing.Point(10, 44); $lblSel.Size = New-Object System.Drawing.Size(960, 20)
$form.Controls.Add($lblSel)

# ============================================================
#  TAB CONTROL
# ============================================================
$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Location = New-Object System.Drawing.Point(10, 68)
$tabs.Size = New-Object System.Drawing.Size(964, 520)
$form.Controls.Add($tabs)

$tabPlayer = New-Object System.Windows.Forms.TabPage
$tabPlayer.Text = U "tab.player" "Player"
$tabs.TabPages.Add($tabPlayer)

$tabBuffs = New-Object System.Windows.Forms.TabPage
$tabBuffs.Text = U "tab.buffs" "Buffs"
$tabs.TabPages.Add($tabBuffs)

$tabGroup = New-Object System.Windows.Forms.TabPage
$tabGroup.Text = U "tab.group" "Server-wide"
$tabs.TabPages.Add($tabGroup)

$tabTools = New-Object System.Windows.Forms.TabPage
$tabTools.Text = U "tab.tools" "Tools"
$tabs.TabPages.Add($tabTools)

# ------------------------------------------------------------
# TAB 1: PLAYER
# ------------------------------------------------------------
$lblF = New-Object System.Windows.Forms.Label
$lblF.Text = (U "btn.search" "Search")
$lblF.Location = New-Object System.Drawing.Point(10, 14); $lblF.Size = New-Object System.Drawing.Size(50, 20)
$tabPlayer.Controls.Add($lblF)

$txtFilter = New-Object System.Windows.Forms.TextBox
$txtFilter.Location = New-Object System.Drawing.Point(62, 11); $txtFilter.Size = New-Object System.Drawing.Size(180, 24)
$tabPlayer.Controls.Add($txtFilter)

$btnLoad = New-Object System.Windows.Forms.Button
$btnLoad.Text = "Search"
$btnLoad.Location = New-Object System.Drawing.Point(250, 9); $btnLoad.Size = New-Object System.Drawing.Size(80, 26)
$btnLoad.Add_Click({ Load-Characters })
$tabPlayer.Controls.Add($btnLoad)

$chkBackup = New-Object System.Windows.Forms.CheckBox
$chkBackup.Text = U "chk.backup" "I have a backup (required before edits)"
$chkBackup.Location = New-Object System.Drawing.Point(350, 13); $chkBackup.Size = New-Object System.Drawing.Size(400, 22)
$tabPlayer.Controls.Add($chkBackup)

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(10, 46)
$grid.Size = New-Object System.Drawing.Size(540, 420)
$grid.ReadOnly = $true
$grid.AllowUserToAddRows = $false
$grid.SelectionMode = 'FullRowSelect'
$grid.MultiSelect = $false
$grid.AutoSizeColumnsMode = 'None'
$grid.Add_SelectionChanged({
  try {
    if ($grid.CurrentRow -ne $null) {
        $script:SelectedSid = $grid.CurrentRow.Cells['sid'].Value
        $script:SelectedName = $grid.CurrentRow.Cells['name'].Value
        $lblSel.Text = (U "lbl.selected" "Selected") + ": $($script:SelectedName) (sid $($script:SelectedSid))"
        if ($script:lblBuffTarget) { $script:lblBuffTarget.Text = (U "lbl.target" "Target player") + ": $($script:SelectedName)" }
        if ($script:cmbTarget) {
            $want = "$($script:SelectedName) (sid $($script:SelectedSid))"
            $idx = $script:cmbTarget.Items.IndexOf($want)
            if ($idx -ge 0 -and $script:cmbTarget.SelectedIndex -ne $idx) {
                $script:cmbTarget.SelectedIndex = $idx
            }
        }
    }
  } catch { }
})
$tabPlayer.Controls.Add($grid)

$rx = 566
function New-RLabel($tab, $text, $y) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text
    $l.Location = New-Object System.Drawing.Point($rx, $y)
    $l.Size = New-Object System.Drawing.Size(70, 20)
    $tab.Controls.Add($l)
}
function New-RText($tab, $text, $y, $w) {
    $t = New-Object System.Windows.Forms.TextBox
    $t.Text = $text
    $t.Location = New-Object System.Drawing.Point(($rx + 74), $y)
    $t.Size = New-Object System.Drawing.Size($w, 24)
    $tab.Controls.Add($t)
    return $t
}
function New-RButton($tab, $text, $y, $handler) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object System.Drawing.Point($rx, $y)
    $b.Size = New-Object System.Drawing.Size(370, 26)
    $b.Add_Click($handler)
    $tab.Controls.Add($b)
}

New-RLabel $tabPlayer "Gold =" 10
$txtGold = New-RText $tabPlayer "1000000" 10 140
New-RLabel $tabPlayer "Add" 40
$txtAddGold = New-RText $tabPlayer "100000" 40 140
New-RButton $tabPlayer "Set gold (exact)" 70 { Do-SetGold }
New-RButton $tabPlayer "Add gold" 100 { Do-AddGold }

New-RLabel $tabPlayer "Level =" 136
$txtLevel = New-RText $tabPlayer "200" 136 140
New-RButton $tabPlayer "Set level" 166 { Do-SetLevel }

New-RLabel $tabPlayer "Exp" 200
$txtExp = New-RText $tabPlayer "1000000" 200 100
$lblJp = New-Object System.Windows.Forms.Label
$lblJp.Text = "JP"
$lblJp.Location = New-Object System.Drawing.Point(($rx + 184), 203)
$lblJp.Size = New-Object System.Drawing.Size(24, 20)
$tabPlayer.Controls.Add($lblJp)
$txtJp = New-Object System.Windows.Forms.TextBox
$txtJp.Text = "0"
$txtJp.Location = New-Object System.Drawing.Point(($rx + 210), 200)
$txtJp.Size = New-Object System.Drawing.Size(134, 24)
$tabPlayer.Controls.Add($txtJp)
New-RButton $tabPlayer "Add exp / jp" 230 { Do-AddExp }

New-RLabel $tabPlayer "Perm =" 264
$txtPerm = New-RText $tabPlayer "100" 264 140
New-RButton $tabPlayer "Set permission" 294 { Do-SetPermission }

$lblTp = New-Object System.Windows.Forms.Label
$lblTp.Text = "Teleport  x / y / z / layer"
$lblTp.Location = New-Object System.Drawing.Point($rx, 330)
$lblTp.Size = New-Object System.Drawing.Size(220, 20)
$tabPlayer.Controls.Add($lblTp)

$txtX = New-Object System.Windows.Forms.TextBox
$txtX.Text = "0"; $txtX.Location = New-Object System.Drawing.Point($rx, 354); $txtX.Size = New-Object System.Drawing.Size(64, 24)
$tabPlayer.Controls.Add($txtX)
$txtY = New-Object System.Windows.Forms.TextBox
$txtY.Text = "0"; $txtY.Location = New-Object System.Drawing.Point(($rx + 70), 354); $txtY.Size = New-Object System.Drawing.Size(64, 24)
$tabPlayer.Controls.Add($txtY)
$txtZ = New-Object System.Windows.Forms.TextBox
$txtZ.Text = "0"; $txtZ.Location = New-Object System.Drawing.Point(($rx + 140), 354); $txtZ.Size = New-Object System.Drawing.Size(64, 24)
$tabPlayer.Controls.Add($txtZ)
$txtLayer = New-Object System.Windows.Forms.TextBox
$txtLayer.Text = "1"; $txtLayer.Location = New-Object System.Drawing.Point(($rx + 210), 354); $txtLayer.Size = New-Object System.Drawing.Size(44, 24)
$tabPlayer.Controls.Add($txtLayer)
$btnTp = New-Object System.Windows.Forms.Button
$btnTp.Text = "Teleport"
$btnTp.Location = New-Object System.Drawing.Point(($rx + 262), 352); $btnTp.Size = New-Object System.Drawing.Size(108, 26)
$btnTp.Add_Click({ Do-Teleport })
$tabPlayer.Controls.Add($btnTp)

New-RButton $tabPlayer "Show points" 392 { Show-Points }
New-RButton $tabPlayer "Add talent_point +10" 422 { Do-AddTalent }

# ------------------------------------------------------------
# TAB 2: BUFFS
# ------------------------------------------------------------
$script:lblBuffTarget = New-Object System.Windows.Forms.Label
$script:lblBuffTarget.Text = (U "lbl.target" "Target player") + ": none"
$script:lblBuffTarget.Location = New-Object System.Drawing.Point(10, 10)
$script:lblBuffTarget.Size = New-Object System.Drawing.Size(400, 20)
$tabBuffs.Controls.Add($script:lblBuffTarget)

$lblT2 = New-Object System.Windows.Forms.Label
$lblT2.Text = (U "lbl.target" "Target player")
$lblT2.Location = New-Object System.Drawing.Point(10, 38)
$lblT2.Size = New-Object System.Drawing.Size(110, 20)
$tabBuffs.Controls.Add($lblT2)

$script:cmbTarget = New-Object System.Windows.Forms.ComboBox
$script:cmbTarget.Location = New-Object System.Drawing.Point(120, 35)
$script:cmbTarget.Size = New-Object System.Drawing.Size(260, 24)
$script:cmbTarget.DropDownStyle = 'DropDownList'
$script:cmbTarget.Add_SelectedIndexChanged({
    $s = [string]$script:cmbTarget.SelectedItem
    if ($s -match "\(sid (\d+)\)") {
        $script:SelectedSid = [int]$Matches[1]
        $script:SelectedName = ($s -replace " \(sid \d+\)", "")
        $lblSel.Text = (U "lbl.selected" "Selected") + ": $($script:SelectedName) (sid $($script:SelectedSid))"
        $script:lblBuffTarget.Text = (U "lbl.target" "Target player") + ": $($script:SelectedName)"
    }
})
$tabBuffs.Controls.Add($script:cmbTarget)

$lblD = New-Object System.Windows.Forms.Label
$lblD.Text = (U "lbl.duration" "Duration")
$lblD.Location = New-Object System.Drawing.Point(400, 38)
$lblD.Size = New-Object System.Drawing.Size(60, 20)
$tabBuffs.Controls.Add($lblD)

$cmbDur = New-Object System.Windows.Forms.ComboBox
$cmbDur.Location = New-Object System.Drawing.Point(462, 35)
$cmbDur.Size = New-Object System.Drawing.Size(180, 24)
$cmbDur.DropDownStyle = 'DropDownList'
[void]$cmbDur.Items.Add((U "dur.1" "10 min"))
[void]$cmbDur.Items.Add((U "dur.2" "1 hour"))
[void]$cmbDur.Items.Add((U "dur.3" "2.5 hours"))
[void]$cmbDur.Items.Add((U "dur.4" "720 min (12 h)"))
$cmbDur.SelectedIndex = 1
$tabBuffs.Controls.Add($cmbDur)

$lblBL = New-Object System.Windows.Forms.Label
$lblBL.Text = U "lbl.buffs_list" "Pick a buff (name / power / code)"
$lblBL.Location = New-Object System.Drawing.Point(10, 68)
$lblBL.Size = New-Object System.Drawing.Size(500, 20)
$tabBuffs.Controls.Add($lblBL)

$lvBuffs = New-Object System.Windows.Forms.ListView
$lvBuffs.Location = New-Object System.Drawing.Point(10, 92)
$lvBuffs.Size = New-Object System.Drawing.Size(630, 370)
$lvBuffs.View = 'Details'
$lvBuffs.FullRowSelect = $true
$lvBuffs.GridLines = $true
$lvBuffs.MultiSelect = $false
[void]$lvBuffs.Columns.Add((U "col.name" "Buff"), 300)
[void]$lvBuffs.Columns.Add((U "col.power" "Power"), 80)
[void]$lvBuffs.Columns.Add((U "col.code" "Code"), 90)
[void]$lvBuffs.Columns.Add((U "lbl.duration" "Duration"), 120)
foreach ($b in $script:BuffCat) {
    $it = New-Object System.Windows.Forms.ListViewItem($b.Name)
    [void]$it.SubItems.Add("+" + $b.Power)
    [void]$it.SubItems.Add([string]$b.Code)
    [void]$it.SubItems.Add($b.Min.ToString() + " min")
    $it.Tag = $b
    [void]$lvBuffs.Items.Add($it)
}
$tabBuffs.Controls.Add($lvBuffs)

$bx = 660
function New-BButton($text, $y, $handler) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object System.Drawing.Point($bx, $y)
    $b.Size = New-Object System.Drawing.Size(280, 32)
    $b.Add_Click($handler)
    $tabBuffs.Controls.Add($b)
}

function Get-DurMinutes {
    switch ($cmbDur.SelectedIndex) {
        0 { return 10 }
        1 { return 60 }
        2 { return 150 }
        3 { return 720 }
        default { return 60 }
    }
}

function Do-SendBuffTab {
    if (-not (Require-Backup)) { return }
    $sid = Get-Sid; if ($sid -eq $null) { return }
    if ($lvBuffs.SelectedItems.Count -lt 1) { Log "Pick a buff from the list first."; return }
    $b = $lvBuffs.SelectedItems[0].Tag
    $min = Get-DurMinutes
    $dur = [int]($min * 60000)
    $sql = "DELETE FROM dbo.[State] WHERE owner_id=@cid AND code=@code; " +
           "DECLARE @nsid INT; SELECT @nsid = ISNULL(MAX(sid),0) + 1 FROM dbo.[State]; " +
           "EXEC dbo.smp_insert_state @IN_SID=@nsid, @IN_OWNER_ID=@cid, @IN_SUMMON_ID=0, " +
           "@IN_CODE=@code, @IN_LEVEL=@lvl, @IN_DURATION=@dur, @IN_REMAIN_TIME=@dur, " +
           "@IN_BASE_DAMAGE=0, @IN_REMAIN_FIRE_TIME=0, @IN_STATE_VALUE=0, " +
           "@IN_STATE_STRING_VALUE=N'', @IN_ENABLE=1"
    Log ("buff [" + $b.Code + "] " + $b.Name + " +" + $b.Power + " / " + $min + " min -> " + $script:SelectedName + " ...")
    $ok = Exec $sql @{ '@cid' = $sid; '@code' = $b.Code; '@lvl' = $b.Power; '@dur' = $dur }
    if ($ok) {
        Log "DONE. Target must relog to see the buff."
        Show-StateList
    }
}

New-BButton (U "btn.send_buff" "Send to selected") 92 { Do-SendBuffTab }
New-BButton (U "btn.clear_buffs" "Clear selected buffs") 132 { Do-ClearBuffs }
New-BButton (U "btn.bless" "Bless ALL (12 buffs)") 172 { Do-BlessAll }

$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Text = "Note: chat commands also work in game:`r`n/run add_state(CODE,POWER,MS,`"NAME`")"
$lblHint.Location = New-Object System.Drawing.Point($bx, 220)
$lblHint.Size = New-Object System.Drawing.Size(280, 60)
$tabBuffs.Controls.Add($lblHint)

# ------------------------------------------------------------
# TAB 3: SERVER-WIDE
# ------------------------------------------------------------
$grpRates = New-Object System.Windows.Forms.GroupBox
$grpRates.Text = U "btn.rates" "Server rates (copy & paste in chat)"
$grpRates.Location = New-Object System.Drawing.Point(10, 10)
$grpRates.Size = New-Object System.Drawing.Size(460, 200)
$tabGroup.Controls.Add($grpRates)

$lblRH = New-Object System.Windows.Forms.Label
$lblRH.Text = U "lbl.rates_help" "Pick a rate, command is copied, paste in game chat"
$lblRH.Location = New-Object System.Drawing.Point(12, 22)
$lblRH.Size = New-Object System.Drawing.Size(430, 36)
$grpRates.Controls.Add($lblRH)

function New-GButton($parent, $text, $y, $handler) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object System.Drawing.Point(12, $y)
    $b.Size = New-Object System.Drawing.Size(430, 34)
    $b.Add_Click($handler)
    $parent.Controls.Add($b)
}

function Copy-Chat([string]$cmd) {
    try {
        [System.Windows.Forms.Clipboard]::SetText($cmd)
        Log ("COPIED: " + $cmd)
        Log "Paste the command in game chat (needs permission = 100)."
    }
    catch {
        Log ("Clipboard failed. Type manually: " + $cmd)
    }
}

New-GButton $grpRates (U "btn.rate_exp" "EXP x300") 64 {
    Copy-Chat '/run set_env("game.exp_rate","300")'
}
New-GButton $grpRates (U "btn.rate_drop" "DROP x200") 104 {
    Copy-Chat '/run set_env("game.item_drop_rate","200")'
}
New-GButton $grpRates (U "btn.rate_gold" "GOLD x200") 144 {
    Copy-Chat '/run set_env("game.gold_drop_rate","200")'
}

$grpState = New-Object System.Windows.Forms.GroupBox
$grpState.Text = U "btn.group_state" "State buff for ALL players (SQL)"
$grpState.Location = New-Object System.Drawing.Point(490, 10)
$grpState.Size = New-Object System.Drawing.Size(454, 300)
$tabGroup.Controls.Add($grpState)

$lblGS = New-Object System.Windows.Forms.Label
$lblGS.Text = "Applies to every non-deleted character:`r`n(takes effect after each player relogs)"
$lblGS.Location = New-Object System.Drawing.Point(12, 22)
$lblGS.Size = New-Object System.Drawing.Size(430, 40)
$grpState.Controls.Add($lblGS)

$cmbGroupBuff = New-Object System.Windows.Forms.ComboBox
$cmbGroupBuff.Location = New-Object System.Drawing.Point(12, 70)
$cmbGroupBuff.Size = New-Object System.Drawing.Size(430, 24)
$cmbGroupBuff.DropDownStyle = 'DropDownList'
foreach ($b in $script:BuffCat) {
    [void]$cmbGroupBuff.Items.Add($b.Name + "  +" + $b.Power + "  [" + $b.Code + "]")
}
if ($cmbGroupBuff.Items.Count -gt 0) { $cmbGroupBuff.SelectedIndex = 0 }
$grpState.Controls.Add($cmbGroupBuff)

$cmbGroupDur = New-Object System.Windows.Forms.ComboBox
$cmbGroupDur.Location = New-Object System.Drawing.Point(12, 104)
$cmbGroupDur.Size = New-Object System.Drawing.Size(430, 24)
$cmbGroupDur.DropDownStyle = 'DropDownList'
[void]$cmbGroupDur.Items.Add((U "dur.1" "10 min"))
[void]$cmbGroupDur.Items.Add((U "dur.2" "1 hour"))
[void]$cmbGroupDur.Items.Add((U "dur.3" "2.5 hours"))
[void]$cmbGroupDur.Items.Add((U "dur.4" "720 min (12 h)"))
$cmbGroupDur.SelectedIndex = 1
$grpState.Controls.Add($cmbGroupDur)

function Do-GroupState {
    if (-not (Require-Backup)) { return }
    if ($script:Conn -eq $null) { Log "Not connected."; return }
    if ($cmbGroupBuff.SelectedIndex -lt 0) { Log "Pick a buff first."; return }
    $b = $script:BuffCat[$cmbGroupBuff.SelectedIndex]
    $min = 60
    switch ($cmbGroupDur.SelectedIndex) { 0 { $min = 10 } 1 { $min = 60 } 2 { $min = 150 } 3 { $min = 720 } }
    $dur = [int]($min * 60000)
    $ans = [System.Windows.Forms.MessageBox]::Show(
        ("Apply " + $b.Name + " (+" + $b.Power + ", " + $min + " min) to ALL players?"),
        "Confirm group buff", [System.Windows.Forms.MessageBoxButtons]::YesNo)
    if ($ans -ne 'Yes') { Log "cancelled"; return }
    $sql = "DECLARE @nsid INT; SELECT @nsid = ISNULL(MAX(sid), 0) FROM dbo.[State]; " +
           "INSERT INTO dbo.[State] (sid, owner_id, summon_id, code, level, duration, remain_time, " +
           "base_damage, remain_fire_time, state_value, state_string_value, enable) " +
           "SELECT @nsid + ROW_NUMBER() OVER (ORDER BY c.sid), c.sid, 0, @code, @lvl, @dur, @dur, " +
           "0, 0, 0, N'', 1 FROM dbo.[Character] c WHERE c.delete_time IS NULL;"
    $cmd = $script:Conn.CreateCommand()
    $cmd.CommandText = $sql
    [void]$cmd.Parameters.AddWithValue("@code", $b.Code)
    [void]$cmd.Parameters.AddWithValue("@lvl", $b.Power)
    [void]$cmd.Parameters.AddWithValue("@dur", $dur)
    try {
        $n = $cmd.ExecuteNonQuery()
        Log ("GROUP BUFF DONE: " + $b.Name + " -> " + $n + " row(s).")
        Log "Every player sees the buff after relog."
    }
    catch { Log ("GROUP SQL FAILED: " + $_.Exception.Message) }
}

New-GButton $grpState (U "btn.apply_all" "Apply to everyone") 144 { Do-GroupState }

$lblG2 = New-Object System.Windows.Forms.Label
$lblG2.Text = "Or in chat (live world-wide):`r`n/run cast_world_state(CODE,POWER,MS)`r`nIf that function is missing, use the SQL button above."
$lblG2.Location = New-Object System.Drawing.Point(12, 190)
$lblG2.Size = New-Object System.Drawing.Size(430, 80)
$grpState.Controls.Add($lblG2)

# ------------------------------------------------------------
# TAB 4: TOOLS
# ------------------------------------------------------------
$lblG = New-Object System.Windows.Forms.Label
$lblG.Text = U "lbl.gift" "Gift code"
$lblG.Location = New-Object System.Drawing.Point(10, 14)
$lblG.Size = New-Object System.Drawing.Size(80, 20)
$tabTools.Controls.Add($lblG)

$txtItemCode = New-Object System.Windows.Forms.TextBox
$txtItemCode.Text = "609040"
$txtItemCode.Location = New-Object System.Drawing.Point(92, 11)
$txtItemCode.Size = New-Object System.Drawing.Size(100, 24)
$tabTools.Controls.Add($txtItemCode)

$lblC = New-Object System.Windows.Forms.Label
$lblC.Text = U "lbl.count" "Count"
$lblC.Location = New-Object System.Drawing.Point(202, 14)
$lblC.Size = New-Object System.Drawing.Size(50, 20)
$tabTools.Controls.Add($lblC)

$txtItemCnt = New-Object System.Windows.Forms.TextBox
$txtItemCnt.Text = "1"
$txtItemCnt.Location = New-Object System.Drawing.Point(254, 11)
$txtItemCnt.Size = New-Object System.Drawing.Size(60, 24)
$tabTools.Controls.Add($txtItemCnt)

$btnSendItem = New-Object System.Windows.Forms.Button
$btnSendItem.Text = U "btn.send_item" "Send gift to selected"
$btnSendItem.Location = New-Object System.Drawing.Point(330, 9)
$btnSendItem.Size = New-Object System.Drawing.Size(220, 28)
$btnSendItem.Add_Click({ Do-SendItem })
$tabTools.Controls.Add($btnSendItem)

$btnSendAll = New-Object System.Windows.Forms.Button
$btnSendAll.Text = U "btn.send_all" "Send to ALL (event)"
$btnSendAll.Location = New-Object System.Drawing.Point(560, 9)
$btnSendAll.Size = New-Object System.Drawing.Size(200, 28)
$btnSendAll.Add_Click({ Do-SendItemAll })
$tabTools.Controls.Add($btnSendAll)

$txtQuery = New-Object System.Windows.Forms.TextBox
$txtQuery.Location = New-Object System.Drawing.Point(10, 50)
$txtQuery.Size = New-Object System.Drawing.Size(740, 24)
$txtQuery.Font = New-Object System.Drawing.Font("Consolas", 9)
$tabTools.Controls.Add($txtQuery)

$btnQuery = New-Object System.Windows.Forms.Button
$btnQuery.Text = U "btn.run_select" "Run SELECT"
$btnQuery.Location = New-Object System.Drawing.Point(760, 48)
$btnQuery.Size = New-Object System.Drawing.Size(160, 26)
$btnQuery.Add_Click({ Do-SafeQuery })
$tabTools.Controls.Add($btnQuery)

function New-TButton($text, $x, $y, $w, $handler) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object System.Drawing.Point($x, $y)
    $b.Size = New-Object System.Drawing.Size($w, 28)
    $b.Add_Click($handler)
    $tabTools.Controls.Add($b)
}

New-TButton "Schema (read-only)" 10 90 220 { Do-Schema }
New-TButton "Item delivery info" 240 90 220 { Do-ItemInfo }
New-TButton "Gift prep" 470 90 180 { Do-GiftPrep }
New-TButton "Buff prep" 660 90 160 { Do-BuffPrep }
New-TButton "Find buff names" 10 126 220 { Do-FindStates }
New-TButton "Show points" 240 126 180 { Show-Points }
New-TButton "Block / unblock account" 430 126 220 { Do-BlockAccount }
New-TButton "Set gold for ALL chars" 660 126 260 { Do-SetGoldAll }

$chkBlock = New-Object System.Windows.Forms.CheckBox
$chkBlock.Text = "block = ON (uncheck to unblock)"
$chkBlock.Location = New-Object System.Drawing.Point(10, 166)
$chkBlock.Size = New-Object System.Drawing.Size(260, 22)
$tabTools.Controls.Add($chkBlock)

$txtTalent = New-Object System.Windows.Forms.TextBox
$txtTalent.Text = "10"
$txtTalent.Location = New-Object System.Drawing.Point(280, 164)
$txtTalent.Size = New-Object System.Drawing.Size(70, 24)
$tabTools.Controls.Add($txtTalent)
New-TButton "Add talent" 360 162 140 { Do-AddTalent }

$txtJpAdd = New-Object System.Windows.Forms.TextBox
$txtJpAdd.Text = "1000"
$txtJpAdd.Location = New-Object System.Drawing.Point(520, 164)
$txtJpAdd.Size = New-Object System.Drawing.Size(80, 24)
$tabTools.Controls.Add($txtJpAdd)
New-TButton "Add jp" 610 162 120 { Do-AddJp }

# ============================================================
#  LOG
# ============================================================
$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true
$txtLog.ScrollBars = 'Vertical'
$txtLog.ReadOnly = $true
$txtLog.Location = New-Object System.Drawing.Point(10, 594)
$txtLog.Size = New-Object System.Drawing.Size(964, 140)
$form.Controls.Add($txtLog)

# ============================================================
#  BOOT
# ============================================================
$uiPath = Join-Path $script:Root "GM-UI-ar.txt"
$bfPath = Join-Path $script:Root "GM-Buffs-ar.csv"
if (-not (Test-Path $uiPath)) { Log ("WARNING: missing " + $uiPath + " - UI falls back to English.") }
if (-not (Test-Path $bfPath)) { Log ("WARNING: missing " + $bfPath + " - buff list will be empty.") }
Log ("RZ-GM Tool v2.0 ready - buff catalog: " + $script:BuffCat.Count + " entries (Arabic).")
Log "Tabs: Player | Buffs | Server-wide | Tools"
Log "1) Connect  2) Search  3) Tick backup  4) Pick a tab"

if ($txtServer.Text -eq "") { $txtServer.Text = "127.0.0.1" }
if ($txtDb.Text -eq "")     { $txtDb.Text = "Telecaster1" }
if ($txtUser.Text -eq "")   { $txtUser.Text = "rappelz" }
try { Connect-Db } catch { Log "auto-connect skipped: $($_.Exception.Message)" }

try {
    [void]$form.ShowDialog()
}
catch {
    $err = "FATAL: " + $_.Exception.Message + "`n" + $_.ScriptStackTrace
    try { Log $err } catch { }
    try {
        [System.Windows.Forms.MessageBox]::Show($err, "RZ-GM Tool failed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    } catch { }
    exit 1
}
}
catch {
    $emsg = "STARTUP ERROR: " + $_.Exception.Message + "`n`n" + $_.ScriptStackTrace
    try {
        $lp = Join-Path $script:Root "GM-Tool-last.log"
        [System.IO.File]::AppendAllText($lp, $emsg + "`r`n", [System.Text.Encoding]::UTF8)
    } catch { }
    try {
        [System.Windows.Forms.MessageBox]::Show($emsg, "RZ-GM Tool failed to start", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    } catch { }
    exit 1
}

