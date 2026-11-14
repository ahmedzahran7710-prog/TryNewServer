-- ============================================================
--  RZ-GM Board  v2.0
--  Arabic tabbed GM board - Rappelz Epic 9.1 (Revolution)
--
--  DESIGN (user rules 2026-11-14):
--   * Chat commands work:  /run add_state(code,val,ms,"Name")
--   * Cross-player BY NAME works (4th argument)
--   * Menus are organized tabs, Arabic labels, practical
--   * Buff tab: Arabic name + code + power + duration
--   * Target player name always visible
--   * Server-wide buff button (rates + world states)
--
--  SAFE BY DESIGN
--   * every engine call wrapped in pcall
--   * missing functions detected, never assumed
--   * normal players see the ORIGINAL npc dialog unchanged
--
--  ENCODING: this source is UTF-8 (readable in git).
--  INSTALL converts it to Windows-1256 for the game client.
-- ============================================================

GM = GM or {}
GM.VERSION = "2.0"
GM.tag     = "[RZ-GM]"

-- ============================================================
--  1) CONFIG  (edit this block only)
-- ============================================================

GM.enabled = true

-- Characters that see the board instead of the normal npc dialog.
GM.gm_names = { "OwnerZahran" }

-- Optional key item gate. 0 = disabled.
GM.key_item = 0

-- Print a server-wide notice on gifts? (OFF until notice call proven)
GM.announce = false

-- Named targets for the target picker (max 8).
GM.players = { "OwnerZahran", "Admin" }

-- ---------- BUFF CATALOG ----------
-- { state_code, power, "Arabic name" }
-- power = value passed to add_state (قوة الباف)
GM.buffs = {
  { 1007, 150, "زيادة قوة الهجوم" },
  { 1008, 150, "زيادة قوة الهجوم السحري" },
  { 1009, 250, "زيادة قوة الدفاع" },
  { 1010, 450, "زيادة قوة الدفاع السحري" },
  { 1011,  90, "زيادة سرعة الهجوم" },
  { 1012,  50, "زيادة سرعة التفعيل" },
  { 1013, 150, "زيادة سرعة الحركة" },
  { 1014, 100, "زيادة الدقة" },
  { 1015, 150, "زيادة المراوغة" },
  { 4102,  50, "مضاعف الخبرة" },
  { 1513,  60, "زيادة اقصى صحة" },
  { 1507,  50, "زيادة الحظ" },
}

-- ---------- DURATION PICKER ----------
-- { "Arabic label", milliseconds }
GM.durations = {
  { "10 دقائق",       600000 },
  { "ساعة",          3600000 },
  { "2.5 ساعة",      9000000 },
  { "دائم (~23 يوم)", 2000000000 },
}
GM.duration_idx = 1   -- default: 10 minutes

-- ---------- SERVER-WIDE RATES (set_env - affects EVERYONE) ----------
-- { "Arabic label", env key, value }
GM.rates = {
  { "خبرة x300 للسيرفر",  "game.exp_rate",       "300" },
  { "دروب x200 للسيرفر",  "game.item_drop_rate", "200" },
  { "ذهب x200 للسيرفر",   "game.gold_drop_rate",  "200" },
}

-- ---------- WORLD STATE BUFFS (all online players at once) ----------
-- try order: add_event_state -> cast_world_state
GM.world_buffs = {
  { 1013, 150, "سرعة حركة للكل" },
  { 1007, 150, "هجوم للكل" },
  { 4102,  50, "خبرة للكل" },
}

-- ---------- GIFTS ----------
GM.amounts  = { 1000, 10000, 100000, 1000000 }
GM.level_ops = {
  { "add", 1  }, { "add", 10 }, { "add", 50 }, { "set", 200 },
}
GM.exp_ops = {
  { 100000, 0 }, { 1000000, 0 }, { 0, 100000 }, { 10000000, 1000000 },
}
GM.items = {
  -- { item_code, count, "Arabic label" },
}

-- Buff page size (keep menus <= 8 lines - proven safe on this build)
GM.page_size = 6

-- ============================================================
--  2) ENGINE BINDINGS
-- ============================================================

GM.fn = {}
GM.fn.dlg_title  = dlg_title
GM.fn.dlg_text   = dlg_text
GM.fn.dlg_menu   = dlg_menu
GM.fn.dlg_show   = dlg_show

GM.fn.get_name   = get_name
GM.fn.get_level  = get_level
GM.fn.has_item   = has_item
GM.fn.get_item_count = get_item_count

GM.fn.set_value   = set_value
GM.fn.insert_gold = insert_gold
GM.fn.set_gold    = set_gold
GM.fn.add_gold    = add_gold

GM.fn.set_level   = set_level
GM.fn.add_exp_jp  = add_exp_jp
GM.fn.add_exp     = add_exp
GM.fn.add_jp      = add_jp

GM.fn.add_state   = add_state
GM.fn.heal        = heal
GM.fn.full_heal   = full_heal

GM.fn.insert_item = insert_item
GM.fn.give_item   = give_item

-- server-wide tools
GM.fn.set_env           = set_env
GM.fn.get_env           = get_env
GM.fn.add_event_state   = add_event_state
GM.fn.cast_world_state  = cast_world_state

GM.fn.notice_a = SCRIPT_BroadcastNotice
GM.fn.notice_b = SCRIPT_Announce
GM.fn.notice_c = broadcast_notice
GM.fn.notice_d = notice

GM.fn.find_player = find_player
GM.fn.get_player  = get_player_by_name
GM.fn.get_player_b = get_pc_by_name
GM.fn.get_player_c = get_pc
GM.fn.is_online   = is_online

GM.fn.add_level   = add_level
GM.fn.set_lv      = set_lv

GM.fn.gv     = gv
GM.fn.get_value = get_value

GM.fn.db_select = db_select
GM.fn.db_exec   = db_exec

-- ============================================================
--  3) HELPERS
-- ============================================================

local function count(t)
  if t == nil then return 0 end
  if table.getn ~= nil then return table.getn(t) end
  local n, k, v
  n = 0
  for k, v in pairs(t) do n = n + 1 end
  return n
end

local function log(msg)
  local line = GM.tag .. " " .. tostring(msg)
  if type(message) == "function" then pcall(message, line) end
  if type(print)   == "function" then pcall(print,   line) end
end
GM.log = log

local function isfn(f)
  return type(f) == "function"
end

function GM.t0(f)
  if not isfn(f) then return false end
  return pcall(f)
end

function GM.t1(f, a)
  if not isfn(f) then return false end
  return pcall(f, a)
end

function GM.t2(f, a, b)
  if not isfn(f) then return false end
  return pcall(f, a, b)
end

function GM.t3(f, a, b, c)
  if not isfn(f) then return false end
  return pcall(f, a, b, c)
end

function GM.t4(f, a, b, c, d)
  if not isfn(f) then return false end
  return pcall(f, a, b, c, d)
end

-- current player name ("" if unavailable)
function GM.me()
  if isfn(GM.fn.get_name) then
    local ok, n = pcall(GM.fn.get_name)
    if ok and n ~= nil and tostring(n) ~= "" then return tostring(n) end
  end
  local helpers = { "gv", "get_value", "get_player_name", "get_char_name" }
  local i, f, ok, v
  for i = 1, #helpers do
    f = nil
    if type(_G) == "table" then f = _G[helpers[i]] end
    if isfn(f) then
      ok, v = pcall(f, "name")
      if (not ok) or v == nil then ok, v = pcall(f) end
      if ok and v ~= nil and tostring(v) ~= "" and tostring(v) ~= "name" then
        return tostring(v)
      end
    end
  end
  return ""
end

function GM.my_level()
  if isfn(GM.fn.get_level) then
    local ok, v = pcall(GM.fn.get_level)
    if ok and type(v) == "number" then return v end
  end
  local names = { "gv", "get_value" }
  local keys  = { "level", "lv" }
  local i, j, f, ok, v
  for i = 1, #names do
    f = nil
    if type(_G) == "table" then f = _G[names[i]] end
    if isfn(f) then
      for j = 1, #keys do
        ok, v = pcall(f, keys[j])
        if ok and type(v) == "number" and v > 0 and v < 1000 then return v end
      end
    end
  end
  return nil
end

function GM.gate_ok()
  if GM.enabled ~= true then return false end
  local name = GM.me()
  local i
  for i = 1, count(GM.gm_names) do
    if name ~= "" and GM.gm_names[i] == name then return true end
  end
  if GM.key_item ~= 0 then
    if isfn(GM.fn.has_item) then
      local ok, v = pcall(GM.fn.has_item, GM.key_item)
      if ok and v then return true end
    elseif isfn(GM.fn.get_item_count) then
      local ok, v = pcall(GM.fn.get_item_count, GM.key_item)
      if ok and type(v) == "number" and v > 0 then return true end
    end
  end
  return false
end

-- current target ("self" or a character name)
function GM.cur_target()
  if GM.target == nil or GM.target == "" then return "self" end
  return GM.target
end

function GM.duration_ms()
  local d = GM.durations[GM.duration_idx]
  if d == nil then return 600000 end
  return d[2]
end

function GM.duration_label()
  local d = GM.durations[GM.duration_idx]
  if d == nil then return "?" end
  return d[1]
end

-- ============================================================
--  4) DIALOG
-- ============================================================

local function show(title, text, list)
  if isfn(GM.fn.dlg_title) then GM.t1(GM.fn.dlg_title, title) end
  if isfn(GM.fn.dlg_text)  then GM.t1(GM.fn.dlg_text, text)  end
  local i
  for i = 1, count(list) do
    if isfn(GM.fn.dlg_menu) then
      GM.t2(GM.fn.dlg_menu, list[i][1], list[i][2] .. "()")
    end
  end
  if isfn(GM.fn.dlg_show) then GM.t0(GM.fn.dlg_show) end
end

function GM.msg(title, text)
  show(title, text, { { "رجوع", "gm_main" }, { "اغلاق", "gm_close" } })
end

-- ============================================================
--  5) ACTION ENGINE
-- ============================================================

function GM.act_gold(n)
  if GM.t1(GM.fn.insert_gold, n) then return true end
  if GM.t1(GM.fn.add_gold, n)    then return true end
  if GM.t2(GM.fn.set_value, "gold", n) then return true end
  if GM.t1(GM.fn.set_gold, n)    then return true end
  return false
end

function GM.act_level(mode, n)
  if mode == "set" then
    if GM.t1(GM.fn.set_level, n) then return true end
    if GM.t1(GM.fn.set_lv,    n) then return true end
    if GM.t2(GM.fn.set_value, "lv", n) then return true end
    if GM.t2(GM.fn.set_value, "level", n) then return true end
    log("set level " .. n .. " FAILED - all setters refused")
    return false
  end
  if GM.t1(GM.fn.add_level, n) then return true end
  local cur = GM.my_level()
  if cur == nil then
    log("level add refused: current level unknown")
    return false
  end
  local target = cur + n
  if GM.t1(GM.fn.set_level, target) then return true end
  if GM.t1(GM.fn.set_lv,    target) then return true end
  if GM.t2(GM.fn.set_value, "lv", target) then return true end
  return false
end

function GM.act_exp(exp, jp)
  if GM.t2(GM.fn.add_exp_jp, exp, jp) then return true end
  if exp > 0 and GM.t1(GM.fn.add_exp, exp) then return true end
  if jp  > 0 and GM.t1(GM.fn.add_jp,  jp)  then return true end
  return false
end

-- buff on CURRENT player
function GM.act_buff_ms(code, value, ms)
  return GM.t3(GM.fn.add_state, code, value, ms)
end

-- buff a player BY NAME (4th arg - confirmed working on this build)
function GM.act_buff_to(name, code, value, ms)
  if name == nil or tostring(name) == "" then return false end
  local ok = GM.t4(GM.fn.add_state, code, value, ms, tostring(name))
  if ok then log("add_state(name) ok -> " .. tostring(name))
  else log("add_state(name) REFUSED for " .. tostring(name)) end
  return ok
end

-- SERVER-WIDE state buff: try event/world hooks (all players at once)
-- returns name of the call that worked, or nil
function GM.act_world_state(code, value, ms)
  if GM.t2(GM.fn.add_event_state, code, value) then
    log("add_event_state ok " .. code)
    return "add_event_state"
  end
  if GM.t3(GM.fn.cast_world_state, code, value, ms) then
    log("cast_world_state ok " .. code)
    return "cast_world_state"
  end
  return nil
end

-- SERVER-WIDE rate (set_env - everyone, memory-only until restart)
function GM.act_rate(key, val)
  return GM.t2(GM.fn.set_env, key, val)
end

function GM.act_heal()
  if GM.t0(GM.fn.heal) then return true end
  if GM.t0(GM.fn.full_heal) then return true end
  return false
end

function GM.act_item(code, cnt)
  if GM.t2(GM.fn.insert_item, code, cnt) then return true end
  if GM.t2(GM.fn.give_item, code, cnt) then return true end
  return false
end

GM.notice_state = nil

function GM.act_notice(text)
  if GM.notice_state == false then return false end
  if GM.t1(GM.fn.notice_c, text) then GM.notice_state = true; return true end
  if GM.t1(GM.fn.notice_d, text) then GM.notice_state = true; return true end
  if GM.t2(GM.fn.notice_c, text, 0) then GM.notice_state = true; return true end
  if GM.t2(GM.fn.notice_a, text, 0) then GM.notice_state = true; return true end
  if GM.t2(GM.fn.notice_b, text, 0) then GM.notice_state = true; return true end
  GM.notice_state = false
  log("notice disabled: no working announce call on this build")
  return false
end

function GM.gift(label, ok, target_name)
  if not ok then
    GM.msg("RZ-GM", label .. " : غير مدعوم على هذا البناء.\nافتح [تقرير القدرات] لترى الناقص.")
    return
  end
  local who = target_name
  if who == nil or who == "" then who = GM.me() end
  if who == "" then who = "player" end
  if GM.announce == true then
    local text = "[GM] " .. who .. " received: " .. label
    GM.act_notice(text)
  end
  GM.msg("RZ-GM", "تم: " .. label .. " -> " .. who)
end

-- ============================================================
--  6) CAPABILITY PROBE / REPORT
-- ============================================================

GM.probe_list = {
  { "dialog dlg_title",    GM.fn.dlg_title  },
  { "dialog dlg_text",     GM.fn.dlg_text   },
  { "dialog dlg_menu",     GM.fn.dlg_menu   },
  { "dialog dlg_show",     GM.fn.dlg_show   },
  { "get_name",            GM.fn.get_name   },
  { "gv / get_value",      GM.fn.gv         },
  { "set_value",           GM.fn.set_value  },
  { "insert_gold",         GM.fn.insert_gold},
  { "set_level",           GM.fn.set_level  },
  { "add_exp_jp",          GM.fn.add_exp_jp },
  { "add_state",           GM.fn.add_state  },
  { "heal",                GM.fn.heal       },
  { "insert_item",         GM.fn.insert_item},
  { "SCRIPT_BroadcastNotice", GM.fn.notice_a },
  { "set_env",             GM.fn.set_env    },
  { "add_event_state",     GM.fn.add_event_state },
  { "cast_world_state",    GM.fn.cast_world_state },
  { "find_player (cross)", GM.fn.find_player },
  { "get_pc_by_name",      GM.fn.get_player_b },
  { "is_online",           GM.fn.is_online  },
  { "db_select (SQL)",     GM.fn.db_select  },
  { "db_exec (SQL)",       GM.fn.db_exec    },
}

function GM.report_lines()
  local lines, i, p
  lines = {}
  for i = 1, count(GM.probe_list) do
    p = GM.probe_list[i]
    local st = "MISSING"
    if isfn(p[2]) then st = "OK" end
    lines[count(lines) + 1] = st .. "  " .. p[1]
  end
  return lines
end

function GM.report_dump()
  local lines = GM.report_lines()
  local i
  for i = 1, count(lines) do log("probe | " .. lines[i]) end
end

function gm_report()
  local lines = GM.report_lines()
  local txt = "RZ-GM Report v" .. GM.VERSION .. "\n"
  local i, n_ok, n_all
  n_ok, n_all = 0, 0
  for i = 1, count(lines) do
    n_all = n_all + 1
    if string.sub(lines[i], 1, 2) == "OK" then n_ok = n_ok + 1 end
    if i <= 12 then txt = txt .. lines[i] .. "\n" end
  end
  txt = txt .. "(" .. n_ok .. "/" .. n_all .. " ok - full list in console)"
  GM.msg("RZ-GM Report", txt)
end

-- ============================================================
--  7) MENUS  (new tabbed structure - v2.0)
-- ============================================================

function gm_close()
  if isfn(GM.fn.dlg_show) then
    if isfn(GM.fn.dlg_title) then GM.t1(GM.fn.dlg_title, " ") end
    if isfn(GM.fn.dlg_text)  then GM.t1(GM.fn.dlg_text, " ")  end
    GM.t0(GM.fn.dlg_show)
  end
end

function gm_open()
  if GM.gate_ok() ~= true then
    GM.msg("RZ-GM", "هذه اللوحة لشخصيات الجي ام فقط.")
    return
  end
  GM.target  = GM.target or "self"
  GM.buff_page = 1
  gm_main()
end

-- ---------- MAIN TAB ----------
function gm_main()
  local info = "RZ-GM v" .. GM.VERSION
  info = info .. "\nاللاعب: " .. GM.me()
  local lv = GM.my_level()
  if lv ~= nil then info = info .. "  |  المستوى: " .. tostring(lv) end
  info = info .. "\nالهدف الحالي: " .. GM.cur_target()
  info = info .. "  |  المدة: " .. GM.duration_label()

  local list = {
    { "استهداف لاعب",              "gm_target_menu" },
    { "البفات",                    "gm_buff_menu"   },
    { "بف جماعي للسيرفر كله",      "gm_world_menu"  },
    { "هدايا (فلوس/خبرة/ايتم)",    "gm_gift_menu"   },
    { "تقرير القدرات",             "gm_report"      },
    { "اغلاق",                     "gm_close"       },
  }
  show("RZ-GM Board", info, list)
end

-- ---------- TARGET TAB ----------
function gm_target_menu()
  local list = {}
  list[count(list) + 1] = { "نفسي (الحالي)", "gm_tgt_self" }
  local i
  for i = 1, count(GM.players) do
    if count(list) < 7 then
      list[count(list) + 1] = { GM.players[i], "gm_tgt" .. i }
    end
  end
  list[count(list) + 1] = { "رجوع", "gm_main" }
  show("RZ-GM - استهداف لاعب", "اختر اللاعب المستهدف:\n(الهدف: " .. GM.cur_target() .. ")", list)
end

function gm_tgt_self()
  GM.target = "self"
  gm_main()
end

local function pick_target(n)
  local name = GM.players[n]
  if name == nil then return end
  GM.target = name
  gm_main()
end

function gm_tgt1() pick_target(1) end
function gm_tgt2() pick_target(2) end
function gm_tgt3() pick_target(3) end
function gm_tgt4() pick_target(4) end
function gm_tgt5() pick_target(5) end
function gm_tgt6() pick_target(6) end
function gm_tgt7() pick_target(7) end
function gm_tgt8() pick_target(8) end

-- ---------- BUFF TAB ----------
function gm_buff_menu()
  GM.buff_page = GM.buff_page or 1
  local total = count(GM.buffs)
  if total == 0 then
    GM.msg("RZ-GM", "لا توجد بافات معرفة.\nعدّل GM.buffs في الملف ثم اعد الضغط.")
    return
  end
  local first = (GM.buff_page - 1) * GM.page_size + 1
  local last  = first + GM.page_size - 1
  if last > total then last = total end

  local list = {}
  local i, b, lbl
  for i = first, last do
    b = GM.buffs[i]
    lbl = "[" .. tostring(b[1]) .. "] " .. b[3] .. " +" .. tostring(b[2])
    list[count(list) + 1] = { lbl, "gm_buf" .. i }
  end
  if last < total then
    list[count(list) + 1] = { "التالي >>", "gm_buff_next" }
  elseif first > 1 then
    list[count(list) + 1] = { "<< السابق", "gm_buff_prev" }
  end
  if first > 1 and last < total then
    -- both nav fit? keep simple: next has priority, prev added above only when no next
  end
  list[count(list) + 1] = { "المدة: " .. GM.duration_label() .. " (تغيير)", "gm_dur_menu" }
  list[count(list) + 1] = { "رجوع", "gm_main" }

  local txt = "الهدف: " .. GM.cur_target() .. "\n"
  txt = txt .. "المدة: " .. GM.duration_label() .. "  |  صفحة " ..
        tostring(GM.buff_page) .. "\nاختر الباف:"
  show("RZ-GM - البفات", txt, list)
end

function gm_buff_next()
  GM.buff_page = (GM.buff_page or 1) + 1
  gm_buff_menu()
end

function gm_buff_prev()
  GM.buff_page = (GM.buff_page or 1) - 1
  if GM.buff_page < 1 then GM.buff_page = 1 end
  gm_buff_menu()
end

local function apply_buff(i)
  local b = GM.buffs[i]
  if b == nil then return end
  local code, value = b[1], b[2]
  local ms = GM.duration_ms()
  local t = GM.cur_target()
  local ok
  if t == "self" or t == GM.me() then
    ok = GM.act_buff_ms(code, value, ms)
  else
    ok = GM.act_buff_to(t, code, value, ms)
  end
  GM.gift(b[3] .. " (+" .. tostring(value) .. ")", ok, t)
end

-- dynamic handlers: gm_buf1 .. gm_buf48
function gm_buf1()  apply_buff(1)  end
function gm_buf2()  apply_buff(2)  end
function gm_buf3()  apply_buff(3)  end
function gm_buf4()  apply_buff(4)  end
function gm_buf5()  apply_buff(5)  end
function gm_buf6()  apply_buff(6)  end
function gm_buf7()  apply_buff(7)  end
function gm_buf8()  apply_buff(8)  end
function gm_buf9()  apply_buff(9)  end
function gm_buf10() apply_buff(10) end
function gm_buf11() apply_buff(11) end
function gm_buf12() apply_buff(12) end
function gm_buf13() apply_buff(13) end
function gm_buf14() apply_buff(14) end
function gm_buf15() apply_buff(15) end
function gm_buf16() apply_buff(16) end
function gm_buf17() apply_buff(17) end
function gm_buf18() apply_buff(18) end
function gm_buf19() apply_buff(19) end
function gm_buf20() apply_buff(20) end
function gm_buf21() apply_buff(21) end
function gm_buf22() apply_buff(22) end
function gm_buf23() apply_buff(23) end
function gm_buf24() apply_buff(24) end

-- ---------- DURATION SUB-TAB ----------
function gm_dur_menu()
  local list = {}
  local i
  for i = 1, count(GM.durations) do
    local mark = "  "
    if i == GM.duration_idx then mark = "* " end
    list[count(list) + 1] = { mark .. GM.durations[i][1], "gm_dur" .. i }
  end
  list[count(list) + 1] = { "رجوع", "gm_buff_menu" }
  show("RZ-GM - مدة الباف", "اختر المدة (تُطبق على كل البفات):", list)
end

local function set_dur(n)
  if GM.durations[n] == nil then return end
  GM.duration_idx = n
  gm_buff_menu()
end

function gm_dur1() set_dur(1) end
function gm_dur2() set_dur(2) end
function gm_dur3() set_dur(3) end
function gm_dur4() set_dur(4) end
function gm_dur5() set_dur(5) end

-- ---------- WORLD / SERVER-WIDE TAB ----------
function gm_world_menu()
  local list = {}
  local i
  for i = 1, count(GM.rates) do
    list[count(list) + 1] = { GM.rates[i][1], "gm_rate" .. i }
  end
  for i = 1, count(GM.world_buffs) do
    local b = GM.world_buffs[i]
    list[count(list) + 1] = { "جماعي: " .. b[3] .. " +" .. tostring(b[2]), "gm_wbuf" .. i }
  end
  list[count(list) + 1] = { "رجوع", "gm_main" }
  show("RZ-GM - بف جماعي",
       "للسيرفر كله في وقت واحد:\n(المعدلات تعيد بعد اعادة التشغيل)", list)
end

local function do_rate(i)
  local r = GM.rates[i]
  if r == nil then return end
  local ok = GM.act_rate(r[2], r[3])
  if ok then
    GM.msg("RZ-GM", "تم: " .. r[1] .. "\n(معدل مؤقت - يعود بعد الريستارت)")
  else
    GM.msg("RZ-GM", "set_env غير متاح على هذا البناء.\nجرب من الشات:\n/run set_env(\"" ..
      r[2] .. "\",\"" .. r[3] .. "\")")
  end
end

function gm_rate1() do_rate(1) end
function gm_rate2() do_rate(2) end
function gm_rate3() do_rate(3) end
function gm_rate4() do_rate(4) end
function gm_rate5() do_rate(5) end

local function do_world_buff(i)
  local b = GM.world_buffs[i]
  if b == nil then return end
  local ms = GM.duration_ms()
  local how = GM.act_world_state(b[1], b[2], ms)
  if how ~= nil then
    GM.msg("RZ-GM", "تم (جماعي عبر " .. how .. "):\n" .. b[3] ..
      " +" .. tostring(b[2]) .. "\nالمدة: " .. GM.duration_label())
  else
    GM.msg("RZ-GM", b[3] .. ": دوال العالم غير موجودة هنا.\n" ..
      "بديل - كونسول لكل لاعب:\n#add_state(" .. tostring(b[1]) .. "," ..
      tostring(b[2]) .. "," .. tostring(ms) .. ",\"NAME\")")
  end
end

function gm_wbuf1() do_world_buff(1) end
function gm_wbuf2() do_world_buff(2) end
function gm_wbuf3() do_world_buff(3) end
function gm_wbuf4() do_world_buff(4) end
function gm_wbuf5() do_world_buff(5) end
function gm_wbuf6() do_world_buff(6) end

-- ---------- GIFTS TAB ----------
function gm_gift_menu()
  local list = {
    { "فلوس",          "gm_gold_menu"  },
    { "خبرة / نقاط",   "gm_exp_menu"   },
    { "مستوى",         "gm_level_menu" },
    { "ايتم",          "gm_item_menu"  },
    { "علاج كامل",     "gm_do_heal"    },
    { "رجوع",          "gm_main"       },
  }
  show("RZ-GM - هدايا", "الهدف: " .. GM.cur_target() .. "\nاختر النوع:", list)
end

-- gold
function gm_gold_menu()
  local list = {}
  local i
  for i = 1, count(GM.amounts) do
    list[count(list) + 1] = { tostring(GM.amounts[i]) .. " ذهب", "gm_amt" .. i }
  end
  list[count(list) + 1] = { "رجوع", "gm_gift_menu" }
  show("RZ-GM - فلوس", "الهدف: " .. GM.cur_target() .. "\nاختر المبلغ:", list)
end

local function do_gold(n)
  local t = GM.cur_target()
  if t ~= "self" and t ~= GM.me() then
    GM.msg("RZ-GM", "الفلوس تعمل على نفسك فقط في اللعب.\n" ..
      "للاعب آخر استخدم اداة الويندوز GM-Tool.")
    return
  end
  local ok = GM.act_gold(n)
  GM.gift(tostring(n) .. " ذهب", ok, GM.me())
end

function gm_amt1() do_gold(GM.amounts[1]) end
function gm_amt2() do_gold(GM.amounts[2]) end
function gm_amt3() do_gold(GM.amounts[3]) end
function gm_amt4() do_gold(GM.amounts[4]) end
function gm_amt5() do_gold(GM.amounts[5]) end
function gm_amt6() do_gold(GM.amounts[6]) end

-- level
function gm_level_menu()
  local list = {}
  local i, op, lbl
  for i = 1, count(GM.level_ops) do
    op = GM.level_ops[i]
    if op[1] == "set" then lbl = "تعيين المستوى " .. tostring(op[2])
    else lbl = " +" .. tostring(op[2]) .. " مستوى" end
    list[count(list) + 1] = { lbl, "gm_lvl" .. i }
  end
  list[count(list) + 1] = { "رجوع", "gm_gift_menu" }
  show("RZ-GM - مستوى", "الهدف: " .. GM.cur_target() .. "\nاختر:", list)
end

local function do_level(i)
  local op = GM.level_ops[i]
  if op == nil then return end
  local t = GM.cur_target()
  if t ~= "self" and t ~= GM.me() then
    GM.msg("RZ-GM", "المستوى يعمل على نفسك فقط في اللعب.\nللاعب آخر: GM-Tool.")
    return
  end
  if op[1] ~= "set" and GM.my_level() == nil then
    GM.msg("RZ-GM", "لا يمكن قراءة مستواك الحالي - استخدم خيار التعيين.")
    return
  end
  local ok = GM.act_level(op[1], op[2])
  GM.gift("مستوى " .. tostring(op[1]) .. " " .. tostring(op[2]), ok, GM.me())
end

function gm_lvl1() do_level(1) end
function gm_lvl2() do_level(2) end
function gm_lvl3() do_level(3) end
function gm_lvl4() do_level(4) end
function gm_lvl5() do_level(5) end

-- exp / jp
function gm_exp_menu()
  local list = {}
  local i, op
  for i = 1, count(GM.exp_ops) do
    op = GM.exp_ops[i]
    list[count(list) + 1] = { "خبرة " .. tostring(op[1]) .. " / نقطة " .. tostring(op[2]), "gm_exp" .. i }
  end
  list[count(list) + 1] = { "رجوع", "gm_gift_menu" }
  show("RZ-GM - خبرة", "الهدف: " .. GM.cur_target() .. "\nاختر:", list)
end

local function do_exp(i)
  local op = GM.exp_ops[i]
  if op == nil then return end
  local t = GM.cur_target()
  if t ~= "self" and t ~= GM.me() then
    GM.msg("RZ-GM", "الخبرة تعمل على نفسك فقط في اللعب.\nللاعب آخر: GM-Tool.")
    return
  end
  local ok = GM.act_exp(op[1], op[2])
  GM.gift("خبرة " .. tostring(op[1]) .. " / نقطة " .. tostring(op[2]), ok, GM.me())
end

function gm_exp1() do_exp(1) end
function gm_exp2() do_exp(2) end
function gm_exp3() do_exp(3) end
function gm_exp4() do_exp(4) end
function gm_exp5() do_exp(5) end

-- item
function gm_item_menu()
  if count(GM.items) == 0 then
    GM.msg("RZ-GM", "لا توجد ايتمات معرفة.\n" ..
      "لإرسال ايتم للاعب بالاسم استخدم GM-Tool او:\n" ..
      "/run insert_item(CODE,COUNT)")
    return
  end
  local list = {}
  local i, it, lbl
  for i = 1, count(GM.items) do
    it = GM.items[i]
    lbl = it[3]
    if lbl == nil then lbl = "ايتم " .. tostring(it[1]) end
    list[count(list) + 1] = { lbl .. " x" .. tostring(it[2]), "gm_item" .. i }
  end
  list[count(list) + 1] = { "رجوع", "gm_gift_menu" }
  show("RZ-GM - ايتمات", "الهدف: " .. GM.cur_target(), list)
end

local function do_item(i)
  local it = GM.items[i]
  if it == nil then return end
  local ok = GM.act_item(it[1], it[2])
  GM.gift((it[3] or ("ايتم " .. tostring(it[1]))) .. " x" .. tostring(it[2]), ok, GM.me())
end

function gm_item1() do_item(1) end
function gm_item2() do_item(2) end
function gm_item3() do_item(3) end
function gm_item4() do_item(4) end
function gm_item5() do_item(5) end
function gm_item6() do_item(6) end

function gm_do_heal()
  local t = GM.cur_target()
  if t ~= "self" and t ~= GM.me() then
    GM.msg("RZ-GM", "العلاج يعمل على نفسك فقط في اللعب.")
    return
  end
  local ok = GM.act_heal()
  GM.gift("علاج كامل", ok, GM.me())
end

-- ============================================================
--  8) HOOK INTO AN EXISTING NPC
-- ============================================================

function GM.install_hook(fn_name)
  local G = nil
  if type(_G) == "table" then G = _G end
  if G == nil and type(getfenv) == "function" then
    local ok, e = pcall(getfenv, 1)
    if ok then G = e end
  end
  if G == nil then
    log("hook failed: no global environment")
    return false
  end
  local orig = G[fn_name]
  if type(orig) ~= "function" then
    log("hook failed: " .. tostring(fn_name) .. " not found")
    return false
  end
  G[fn_name] = function()
    local nm = "?"
    pcall(function() nm = GM.me() end)
    if nm == "" then nm = "?" end
    log("contact fired | who=" .. tostring(nm))
    local ok = false
    pcall(function() ok = GM.gate_ok() end)
    if ok then
      log("gate PASS -> opening board")
      pcall(gm_open)
    else
      log("gate DENY -> original npc dialog")
      pcall(orig)
    end
  end
  GM.hooked = fn_name
  log("hook installed on " .. fn_name)
  return true
end

-- ============================================================
--  9) BOOT
-- ============================================================

GM.report_dump()
log("Board v" .. GM.VERSION .. " loaded. GM names: " .. tostring(GM.gm_names[1]))

-- The installer appends one line at the end of this file:
--   GM.install_hook("NPC_<name>_contact")

-- installed hook (v2.0)
GM.install_hook("NPC_Auction_Gaia_contact")
