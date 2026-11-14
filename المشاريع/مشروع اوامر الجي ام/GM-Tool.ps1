<#
  RZ-GM Tool v1.0  --  Windows GUI for Rappelz 9.1
  ASCII ONLY. Do not add non-ASCII characters to this file.

  Talks to SQL Server directly (no console password needed).
  Changes are stored in the database and take effect when the
  character logs in (or relogs).

  Run:  powershell -ExecutionPolicy Bypass -File .\GM-Tool.ps1
#>

param([switch]$SelfTest)

if ($SelfTest) {
    Write-Host "GM-Tool.ps1 self-test: file loads and parses OK."
    Write-Host "GUI needs Windows + .NET WinForms (PowerShell 5.1)."
    exit 0
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ---------------------------------------------------------------- helpers
$script:Conn = $null
$script:SelectedSid = $null
$script:SelectedName = $null

function Log([string]$msg) {
    $ts = (Get-Date).ToString('HH:mm:ss')
    $txtLog.AppendText("[$ts] $msg`r`n")
    $txtLog.SelectionStart = $txtLog.Text.Length
    $txtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
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
    Log "The server name comes from your own config: GameServer.opt says db.c.server:127.0.0.1"
    Log "and authserver.opt says db.auth.server:127.0.0.1 with account 'sa'."
    Log "1) Server = 127.0.0.1   2) User = sa   3) Pass = your sa password"
    Log "4) If you never set an sa password, tick nothing and press Connect again (Windows login is tried too)."
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

function Do-SendBuff {
    if (-not (Require-Backup)) { return }
    $sid = Get-Sid; if ($sid -eq $null) { return }
    $code = 0; if (-not [int]::TryParse($txtBuffCode.Text, [ref]$code)) { Log "Buff code must be a number."; return }
    $lvl = 1;  if (-not [int]::TryParse($txtBuffLevel.Text, [ref]$lvl)) { Log "Buff level must be a number."; return }
    $min = 10; if (-not [int]::TryParse($txtBuffMin.Text, [ref]$min)) { Log "Minutes must be a number."; return }
    if ($code -le 0) { Log "Buff code must be greater than 0."; return }
    if ($min -lt 1 -or $min -gt 720) { Log "Minutes must be 1..720."; return }
    $dur = [int]($min * 60000)
    $sql = "DELETE FROM dbo.[State] WHERE owner_id=@cid AND code=@code; " +
           "DECLARE @nsid INT; SELECT @nsid = ISNULL(MAX(sid),0) + 1 FROM dbo.[State]; " +
           "EXEC dbo.smp_insert_state @IN_SID=@nsid, @IN_OWNER_ID=@cid, @IN_SUMMON_ID=0, " +
           "@IN_CODE=@code, @IN_LEVEL=@lvl, @IN_DURATION=@dur, @IN_REMAIN_TIME=@dur, " +
           "@IN_BASE_DAMAGE=0, @IN_REMAIN_FIRE_TIME=0, @IN_STATE_VALUE=0, " +
           "@IN_STATE_STRING_VALUE=N'', @IN_ENABLE=1"
    Log ("buff " + $code + " lv" + $lvl + " for " + $min + " min -> " + $script:SelectedName + " ...")
    $ok = Exec $sql @{ '@cid' = $sid; '@code' = $code; '@lvl' = $lvl; '@dur' = $dur }
    if ($ok) {
        Log "DONE. The player must relog to see the buff."
        Show-StateList
    }
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
    if ($v -lt 1 -or $v -gt 200) { Log "Level must be 1..200."; return }
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

# ---------------------------------------------------------------- form
$form = New-Object System.Windows.Forms.Form
$form.Text = "RZ-GM Tool v1.6  -  Rappelz 9.1"
$form.Size = New-Object System.Drawing.Size(980, 700)
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# --- connection row
$lbl1 = New-Object System.Windows.Forms.Label
$lbl1.Text = "Server"; $lbl1.Location = New-Object System.Drawing.Point(10, 14); $lbl1.Size = New-Object System.Drawing.Size(50, 20)
$form.Controls.Add($lbl1)

$txtServer = New-Object System.Windows.Forms.TextBox
$txtServer.Text = "127.0.0.1"
$txtServer.Location = New-Object System.Drawing.Point(62, 11); $txtServer.Size = New-Object System.Drawing.Size(230, 24)
$form.Controls.Add($txtServer)

$lbl2 = New-Object System.Windows.Forms.Label
$lbl2.Text = "DB"; $lbl2.Location = New-Object System.Drawing.Point(300, 14); $lbl2.Size = New-Object System.Drawing.Size(30, 20)
$form.Controls.Add($lbl2)

$txtDb = New-Object System.Windows.Forms.TextBox
$txtDb.Text = "Telecaster1"
$txtDb.Location = New-Object System.Drawing.Point(332, 11); $txtDb.Size = New-Object System.Drawing.Size(110, 24)
$form.Controls.Add($txtDb)

$lbl3 = New-Object System.Windows.Forms.Label
$lbl3.Text = "User"; $lbl3.Location = New-Object System.Drawing.Point(450, 14); $lbl3.Size = New-Object System.Drawing.Size(36, 20)
$form.Controls.Add($lbl3)

$txtUser = New-Object System.Windows.Forms.TextBox
$txtUser.Text = "rappelz"
$txtUser.Location = New-Object System.Drawing.Point(488, 11); $txtUser.Size = New-Object System.Drawing.Size(90, 24)
$form.Controls.Add($txtUser)

$lbl4 = New-Object System.Windows.Forms.Label
$lbl4.Text = "Pass"; $lbl4.Location = New-Object System.Drawing.Point(586, 14); $lbl4.Size = New-Object System.Drawing.Size(36, 20)
$form.Controls.Add($lbl4)

$txtPass = New-Object System.Windows.Forms.TextBox
$txtPass.UseSystemPasswordChar = $true
$txtPass.Location = New-Object System.Drawing.Point(624, 11); $txtPass.Size = New-Object System.Drawing.Size(90, 24)
$form.Controls.Add($txtPass)

$btnConnect = New-Object System.Windows.Forms.Button
$btnConnect.Text = "Connect"
$btnConnect.Location = New-Object System.Drawing.Point(722, 9); $btnConnect.Size = New-Object System.Drawing.Size(90, 26)
$btnConnect.Add_Click({ Connect-Db })
$form.Controls.Add($btnConnect)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Not connected"
$lblStatus.ForeColor = [System.Drawing.Color]::Red
$lblStatus.Location = New-Object System.Drawing.Point(818, 14); $lblStatus.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($lblStatus)

# --- filter
$txtFilter = New-Object System.Windows.Forms.TextBox
$txtFilter.Location = New-Object System.Drawing.Point(62, 44); $txtFilter.Size = New-Object System.Drawing.Size(200, 24)
$form.Controls.Add($txtFilter)

$lblF = New-Object System.Windows.Forms.Label
$lblF.Text = "Name"
$lblF.Location = New-Object System.Drawing.Point(10, 47); $lblF.Size = New-Object System.Drawing.Size(50, 20)
$form.Controls.Add($lblF)

$btnLoad = New-Object System.Windows.Forms.Button
$btnLoad.Text = "Search"
$btnLoad.Location = New-Object System.Drawing.Point(268, 42); $btnLoad.Size = New-Object System.Drawing.Size(80, 26)
$btnLoad.Add_Click({ Load-Characters })
$form.Controls.Add($btnLoad)

$chkBackup = New-Object System.Windows.Forms.CheckBox
$chkBackup.Text = "I have a backup (required before any write)"
$chkBackup.Location = New-Object System.Drawing.Point(360, 45); $chkBackup.Size = New-Object System.Drawing.Size(320, 22)
$form.Controls.Add($chkBackup)

# --- grid
$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(10, 78)
$grid.Size = New-Object System.Drawing.Size(560, 190)
$grid.ReadOnly = $true
$grid.AllowUserToAddRows = $false
$grid.SelectionMode = 'FullRowSelect'
$grid.MultiSelect = $false
$grid.AutoSizeColumnsMode = 'None'
$grid.Add_SelectionChanged({
    if ($grid.CurrentRow -ne $null) {
        $script:SelectedSid = $grid.CurrentRow.Cells['sid'].Value
        $script:SelectedName = $grid.CurrentRow.Cells['name'].Value
        $lblSel.Text = "Selected: $($script:SelectedName) (sid $($script:SelectedSid))"
    }
})
$form.Controls.Add($grid)

$lblSel = New-Object System.Windows.Forms.Label
$lblSel.Text = "Selected: none"
$lblSel.Location = New-Object System.Drawing.Point(10, 272); $lblSel.Size = New-Object System.Drawing.Size(560, 20)
$form.Controls.Add($lblSel)

# --- right panel
$x = 584
function New-Label($text, $y) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text
    $l.Location = New-Object System.Drawing.Point($x, $y)
    $l.Size = New-Object System.Drawing.Size(70, 20)
    $form.Controls.Add($l)
}
function New-Text($text, $y, $w) {
    $t = New-Object System.Windows.Forms.TextBox
    $t.Text = $text
    $t.Location = New-Object System.Drawing.Point(($x + 74), $y)
    $t.Size = New-Object System.Drawing.Size($w, 24)
    $form.Controls.Add($t)
    return $t
}
function New-Button($text, $y, $handler) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object System.Drawing.Point($x, $y)
    $b.Size = New-Object System.Drawing.Size(330, 26)
    $b.Add_Click($handler)
    $form.Controls.Add($b)
}

New-Label "Gold =" 76  | Out-Null
$txtGold   = New-Text "1000000" 76 120
New-Label "Add"    102 | Out-Null
$txtAddGold= New-Text "100000"  102 120

$y = 128
New-Button "Set gold (exact)"      $y { Do-SetGold }    | Out-Null
$y += 26
New-Button "Add gold"              $y { Do-AddGold }    | Out-Null
$y += 26

New-Label "Level =" ($y + 3) | Out-Null
$txtLevel = New-Text "200" $y 120
$y += 26
New-Button "Set level" $y { Do-SetLevel } | Out-Null
$y += 26

New-Label "Exp" ($y + 3) | Out-Null
$txtExp = New-Text "1000000" $y 60

$lblJp = New-Object System.Windows.Forms.Label
$lblJp.Text = "JP"
$lblJp.Location = New-Object System.Drawing.Point(($x + 190), ($y + 3))
$lblJp.Size = New-Object System.Drawing.Size(24, 20)
$form.Controls.Add($lblJp)

$txtJp = New-Object System.Windows.Forms.TextBox
$txtJp.Text = "0"
$txtJp.Location = New-Object System.Drawing.Point(($x + 214), $y)
$txtJp.Size = New-Object System.Drawing.Size(116, 24)
$form.Controls.Add($txtJp)
$y += 26
New-Button "Add exp / jp" $y { Do-AddExp } | Out-Null
$y += 26

New-Label "Perm =" ($y + 3) | Out-Null
$txtPerm = New-Text "0" $y 120
$y += 26
New-Button "Set permission" $y { Do-SetPermission } | Out-Null
$y += 26

# --- teleport block
$lblTp = New-Object System.Windows.Forms.Label
$lblTp.Text = "Teleport  x / y / z / layer"
$lblTp.Location = New-Object System.Drawing.Point(10, 300)
$lblTp.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($lblTp)

$txtX = New-Object System.Windows.Forms.TextBox
$txtX.Text = "0"; $txtX.Location = New-Object System.Drawing.Point(10, 322); $txtX.Size = New-Object System.Drawing.Size(70, 24)
$form.Controls.Add($txtX)

$txtY = New-Object System.Windows.Forms.TextBox
$txtY.Text = "0"; $txtY.Location = New-Object System.Drawing.Point(86, 322); $txtY.Size = New-Object System.Drawing.Size(70, 24)
$form.Controls.Add($txtY)

$txtZ = New-Object System.Windows.Forms.TextBox
$txtZ.Text = "0"; $txtZ.Location = New-Object System.Drawing.Point(162, 322); $txtZ.Size = New-Object System.Drawing.Size(70, 24)
$form.Controls.Add($txtZ)

$txtLayer = New-Object System.Windows.Forms.TextBox
$txtLayer.Text = "1"; $txtLayer.Location = New-Object System.Drawing.Point(238, 322); $txtLayer.Size = New-Object System.Drawing.Size(50, 24)
$form.Controls.Add($txtLayer)

$btnTp = New-Object System.Windows.Forms.Button
$btnTp.Text = "Teleport"
$btnTp.Location = New-Object System.Drawing.Point(296, 320); $btnTp.Size = New-Object System.Drawing.Size(90, 26)
$btnTp.Add_Click({ Do-Teleport })
$form.Controls.Add($btnTp)

$chkBlock = New-Object System.Windows.Forms.CheckBox
$chkBlock.Text = "block account"
$chkBlock.Location = New-Object System.Drawing.Point(455, 491); $chkBlock.Size = New-Object System.Drawing.Size(120, 22)
$form.Controls.Add($chkBlock)

$btnBlock = New-Object System.Windows.Forms.Button
$btnBlock.Text = "Apply block flag"
$btnBlock.Location = New-Object System.Drawing.Point(565, 488); $btnBlock.Size = New-Object System.Drawing.Size(100, 26)
$btnBlock.Add_Click({ Do-BlockAccount })
$form.Controls.Add($btnBlock)

$btnSchema = New-Object System.Windows.Forms.Button
$btnSchema.Text = "Schema (read-only)"
$btnSchema.Location = New-Object System.Drawing.Point(838, 430)
$btnSchema.Size = New-Object System.Drawing.Size(1, 1)
$btnSchema.Add_Click({ Do-Schema })
$form.Controls.Add($btnSchema)

$btnAll = New-Object System.Windows.Forms.Button
$btnAll.Text = "Set gold for ALL characters"
$btnAll.Location = New-Object System.Drawing.Point(670, 488); $btnAll.Size = New-Object System.Drawing.Size(145, 26)
$btnAll.Add_Click({ Do-SetGoldAll })
$form.Controls.Add($btnAll)

# --- log
$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true
$txtLog.ScrollBars = 'Vertical'
$txtLog.ReadOnly = $true
$txtLog.Location = New-Object System.Drawing.Point(10, 356)
$txtLog.Size = New-Object System.Drawing.Size(920, 96)
$form.Controls.Add($txtLog)

$btnSchema2 = New-Object System.Windows.Forms.Button
$btnSchema2.Text = "Print table/column names (read-only)"
$btnSchema2.Location = New-Object System.Drawing.Point(10, 458)
$btnSchema2.Size = New-Object System.Drawing.Size(260, 26)
$btnSchema2.Add_Click({ Do-Schema })
$form.Controls.Add($btnSchema2)


$btnItemInfo = New-Object System.Windows.Forms.Button
$btnItemInfo.Text = "Item delivery info (read-only)"
$btnItemInfo.Location = New-Object System.Drawing.Point(280, 458)
$btnItemInfo.Size = New-Object System.Drawing.Size(260, 26)
$btnItemInfo.Add_Click({ Do-ItemInfo })
$form.Controls.Add($btnItemInfo)

$btnPoints = New-Object System.Windows.Forms.Button
$btnPoints.Text = "Show points"
$btnPoints.Location = New-Object System.Drawing.Point(820, 458)
$btnPoints.Size = New-Object System.Drawing.Size(120, 26)
$btnPoints.Add_Click({ Show-Points })
$form.Controls.Add($btnPoints)

$txtTalent = New-Object System.Windows.Forms.TextBox
$txtTalent.Text = "10"
$txtTalent.Location = New-Object System.Drawing.Point(180, 490)
$txtTalent.Size = New-Object System.Drawing.Size(70, 24)
$form.Controls.Add($txtTalent)

$btnTalent = New-Object System.Windows.Forms.Button
$btnTalent.Text = "Add talent_point"
$btnTalent.Location = New-Object System.Drawing.Point(10, 488)
$btnTalent.Size = New-Object System.Drawing.Size(160, 26)
$btnTalent.Add_Click({ Do-AddTalent })
$form.Controls.Add($btnTalent)

$txtJpAdd = New-Object System.Windows.Forms.TextBox
$txtJpAdd.Text = "1000"
$txtJpAdd.Location = New-Object System.Drawing.Point(370, 490)
$txtJpAdd.Size = New-Object System.Drawing.Size(80, 24)
$form.Controls.Add($txtJpAdd)

$btnJp = New-Object System.Windows.Forms.Button
$btnJp.Text = "Add jp"
$btnJp.Location = New-Object System.Drawing.Point(260, 488)
$btnJp.Size = New-Object System.Drawing.Size(100, 26)
$btnJp.Add_Click({ Do-AddJp })
$form.Controls.Add($btnJp)


$btnGiftPrep = New-Object System.Windows.Forms.Button
$btnGiftPrep.Text = "Gift prep (read-only)"
$btnGiftPrep.Location = New-Object System.Drawing.Point(550, 458)
$btnGiftPrep.Size = New-Object System.Drawing.Size(260, 26)
$btnGiftPrep.Add_Click({ Do-GiftPrep })
$form.Controls.Add($btnGiftPrep)

$txtQuery = New-Object System.Windows.Forms.TextBox
$txtQuery.Location = New-Object System.Drawing.Point(10, 522)
$txtQuery.Size = New-Object System.Drawing.Size(760, 24)
$txtQuery.Font = New-Object System.Drawing.Font("Consolas", 9)
$form.Controls.Add($txtQuery)

$btnQuery = New-Object System.Windows.Forms.Button
$btnQuery.Text = "Run SELECT"
$btnQuery.Location = New-Object System.Drawing.Point(780, 520)
$btnQuery.Size = New-Object System.Drawing.Size(150, 26)
$btnQuery.Add_Click({ Do-SafeQuery })
$form.Controls.Add($btnQuery)


$lblGift = New-Object System.Windows.Forms.Label
$lblGift.Text = "Gift item code"
$lblGift.Location = New-Object System.Drawing.Point(10, 556)
$lblGift.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($lblGift)

$txtItemCode = New-Object System.Windows.Forms.TextBox
$txtItemCode.Text = "609040"
$txtItemCode.Location = New-Object System.Drawing.Point(112, 553)
$txtItemCode.Size = New-Object System.Drawing.Size(100, 24)
$form.Controls.Add($txtItemCode)

$lblCnt = New-Object System.Windows.Forms.Label
$lblCnt.Text = "count"
$lblCnt.Location = New-Object System.Drawing.Point(222, 556)
$lblCnt.Size = New-Object System.Drawing.Size(44, 20)
$form.Controls.Add($lblCnt)

$txtItemCnt = New-Object System.Windows.Forms.TextBox
$txtItemCnt.Text = "1"
$txtItemCnt.Location = New-Object System.Drawing.Point(266, 553)
$txtItemCnt.Size = New-Object System.Drawing.Size(60, 24)
$form.Controls.Add($txtItemCnt)

$btnSendItem = New-Object System.Windows.Forms.Button
$btnSendItem.Text = "Send gift to selected player"
$btnSendItem.Location = New-Object System.Drawing.Point(340, 551)
$btnSendItem.Size = New-Object System.Drawing.Size(220, 28)
$btnSendItem.Add_Click({ Do-SendItem })
$form.Controls.Add($btnSendItem)

$btnSendAll = New-Object System.Windows.Forms.Button
$btnSendAll.Text = "Send to ALL (event)"
$btnSendAll.Location = New-Object System.Drawing.Point(570, 551)
$btnSendAll.Size = New-Object System.Drawing.Size(200, 28)
$btnSendAll.Add_Click({ Do-SendItemAll })
$form.Controls.Add($btnSendAll)


$btnBuffPrep = New-Object System.Windows.Forms.Button
$btnBuffPrep.Text = "Buff prep (read-only)"
$btnBuffPrep.Location = New-Object System.Drawing.Point(820, 488)
$btnBuffPrep.Size = New-Object System.Drawing.Size(150, 26)
$btnBuffPrep.Add_Click({ Do-BuffPrep })
$form.Controls.Add($btnBuffPrep)


$lblB1 = New-Object System.Windows.Forms.Label
$lblB1.Text = "Buff code"
$lblB1.Location = New-Object System.Drawing.Point(10, 592)
$lblB1.Size = New-Object System.Drawing.Size(70, 20)
$form.Controls.Add($lblB1)

$txtBuffCode = New-Object System.Windows.Forms.TextBox
$txtBuffCode.Text = ""
$txtBuffCode.Location = New-Object System.Drawing.Point(82, 589)
$txtBuffCode.Size = New-Object System.Drawing.Size(90, 24)
$form.Controls.Add($txtBuffCode)

$lblB2 = New-Object System.Windows.Forms.Label
$lblB2.Text = "level"
$lblB2.Location = New-Object System.Drawing.Point(182, 592)
$lblB2.Size = New-Object System.Drawing.Size(36, 20)
$form.Controls.Add($lblB2)

$txtBuffLevel = New-Object System.Windows.Forms.TextBox
$txtBuffLevel.Text = "1"
$txtBuffLevel.Location = New-Object System.Drawing.Point(218, 589)
$txtBuffLevel.Size = New-Object System.Drawing.Size(50, 24)
$form.Controls.Add($txtBuffLevel)

$lblB3 = New-Object System.Windows.Forms.Label
$lblB3.Text = "minutes"
$lblB3.Location = New-Object System.Drawing.Point(278, 592)
$lblB3.Size = New-Object System.Drawing.Size(56, 20)
$form.Controls.Add($lblB3)

$txtBuffMin = New-Object System.Windows.Forms.TextBox
$txtBuffMin.Text = "10"
$txtBuffMin.Location = New-Object System.Drawing.Point(336, 589)
$txtBuffMin.Size = New-Object System.Drawing.Size(50, 24)
$form.Controls.Add($txtBuffMin)

$btnSendBuff = New-Object System.Windows.Forms.Button
$btnSendBuff.Text = "Send buff to selected"
$btnSendBuff.Location = New-Object System.Drawing.Point(396, 587)
$btnSendBuff.Size = New-Object System.Drawing.Size(170, 28)
$btnSendBuff.Add_Click({ Do-SendBuff })
$form.Controls.Add($btnSendBuff)

$btnClearBuffs = New-Object System.Windows.Forms.Button
$btnClearBuffs.Text = "Clear buffs"
$btnClearBuffs.Location = New-Object System.Drawing.Point(576, 587)
$btnClearBuffs.Size = New-Object System.Drawing.Size(110, 28)
$btnClearBuffs.Add_Click({ Do-ClearBuffs })
$form.Controls.Add($btnClearBuffs)

$btnFindStates = New-Object System.Windows.Forms.Button
$btnFindStates.Text = "Find buff names (read-only)"
$btnFindStates.Location = New-Object System.Drawing.Point(696, 587)
$btnFindStates.Size = New-Object System.Drawing.Size(200, 28)
$btnFindStates.Add_Click({ Do-FindStates })
$form.Controls.Add($btnFindStates)

Log "RZ-GM Tool v1.6 ready."
Log "1) Press Connect   2) Search a name   3) Tick the backup box   4) Use the buttons"
Log "Changes apply when the character logs in. Use the in-game board for live self-grants."

[void]$form.ShowDialog()
