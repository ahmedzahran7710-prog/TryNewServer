-- ============================================================
--  RZ-GM Board  v1.0
--  In-game GM command board + capability probe
--  Target: Rappelz Epic 9.1 (Revolution Team files)
--
--  SAFE BY DESIGN
--   * every engine call is wrapped in pcall
--   * every missing function is detected, never assumed
--   * normal players see the ORIGINAL npc dialog unchanged
--
--  ASCII ONLY - do not add non-ASCII characters to this file
-- ============================================================

GM = GM or {}
GM.VERSION = "1.5"
GM.tag     = "[RZ-GM]"

-- ============================================================
--  1) CONFIG  (edit this block only)
-- ============================================================

GM.enabled = true

-- Characters that see the GM board instead of the normal npc dialog.
-- Put your GM character name here. Case sensitive.
GM.gm_names = { "OwnerZahran" }

-- Optional extra gate: require this item code in inventory.
-- 0 = disabled.
GM.key_item = 0

-- Print a server-wide notice when a gift is granted?
-- v1.2: OFF. On this build the notice call returns "invalid argument" and
-- spams the console red. The board dialog already confirms every gift.
-- Turn on only after the "Plain test notice" option proves it works.
GM.announce = false

-- Target list for "Named player" menu (max 8 names).
GM.players = { "OwnerZahran", "Zahran" }

-- Gold amounts for the amount buttons.
GM.amounts = { 1000, 10000, 100000, 1000000 }

-- Level operations: {"add", n} or {"set", n}
GM.level_ops = {
  { "add", 1   },
  { "add", 10  },
  { "add", 50  },
  { "set", 200 }
}

-- Exp / JP pairs granted by the buttons. { exp, jp }
GM.exp_ops = {
  { 100000,   0 },
  { 1000000,  0 },
  { 0,   100000 },
  { 10000000, 1000000 }
}

-- Buffs: { state_code, level, minutes }
-- Add your own codes here. Empty = buff menu is disabled.
GM.buffs = {
  -- { state_code, level, minutes }
  { 1007, 5, 30 },   -- +ATK   (زيادة قوة الهجوم)
  { 1009, 5, 30 },   -- +DEF   (زيادة قوة الدفاع)
  { 1013, 5, 30 },   -- +speed (زيادة سرعة الحركة)
  { 1513, 5, 30 },   -- +MAX HP
}

-- Items: { item_code, count, "label" }
-- Empty = item menu is disabled.
GM.items = {
  -- { 1234, 1, "Test Item" },
}

-- v1.5: duration used by the "permanent blessing" option (~23 days).
GM.permanent_ms = 2000000000

-- Cross-player execution is OFF by default.
-- Enabling it makes the board call player-lookup functions that may not
-- exist on this build. Keep false unless the probe proves they exist.
GM.allow_cross_player = false

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
GM.fn.get_gold   = get_gold
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

GM.fn.notice_a = SCRIPT_BroadcastNotice
GM.fn.notice_b = SCRIPT_Announce
GM.fn.notice_c = broadcast_notice
GM.fn.notice_d = notice

GM.fn.find_player = find_player
GM.fn.get_player  = get_player_by_name

-- v1.3 probe bindings (may be nil on this build - the report tells us)
GM.fn.get_player_b  = get_pc_by_name
GM.fn.get_player_c  = get_pc
GM.fn.find_pc       = find_pc
GM.fn.is_online     = is_online

GM.fn.add_level     = add_level
GM.fn.set_lv        = set_lv
GM.fn.get_lv        = get_lv

GM.fn.add_skill     = add_skill_point
GM.fn.set_skill     = set_skill_point
GM.fn.get_skill     = get_skill_point
GM.fn.add_stat      = add_stat_point
GM.fn.set_stat      = set_stat_point

GM.fn.gv            = gv
GM.fn.get_value     = get_value

GM.fn.db_select = db_select
GM.fn.db_exec   = db_exec

-- ============================================================
--  3) HELPERS
-- ============================================================

local function count(t)
  if t == nil then return 0 end
  if table.getn ~= nil then return table.getn(t) end
  local n = 0
  local k, v
  for k, v in pairs(t) do n = n + 1 end
  return n
end

local function log(msg)
  local line = GM.tag .. " " .. tostring(msg)
  -- GameServer console uses message(); print() may not exist on every build
  if type(message) == "function" then pcall(message, line) end
  if type(print)   == "function" then pcall(print,   line) end
end

GM.log = log

local function isfn(f)
  return type(f) == "function"
end

-- pcall wrappers with fixed arity (safe on Lua 5.0 and 5.1)
function GM.t0(f)
  if not isfn(f) then return false end
  local ok = pcall(f)
  return ok
end

function GM.t1(f, a)
  if not isfn(f) then return false end
  local ok = pcall(f, a)
  return ok
end

function GM.t2(f, a, b)
  if not isfn(f) then return false end
  local ok = pcall(f, a, b)
  return ok
end

function GM.t3(f, a, b, c)
  if not isfn(f) then return false end
  local ok = pcall(f, a, b, c)
  return ok
end

function GM.t4(f, a, b, c, d)
  if not isfn(f) then return false end
  local ok = pcall(f, a, b, c, d)
  return ok
end

-- current player name ("" if unavailable)
-- Reads the talking player's character name.
-- Different 9.1 builds expose different helpers, so we try them all.
function GM.me()
  -- a) get_name()
  if isfn(GM.fn.get_name) then
    local ok, n = pcall(GM.fn.get_name)
    if ok and n ~= nil and tostring(n) ~= "" then return tostring(n) end
  end

  -- b) gv("name") / get_value("name")  (documented GS helpers)
  local helpers = { "gv", "get_value", "get_player_name", "get_char_name" }
  local i, k
  for i = 1, #helpers do
    local f = nil
    if type(_G) == "table" then f = _G[helpers[i]] end
    if isfn(f) then
      local ok, v = pcall(f, "name")
      if (not ok) or v == nil then ok, v = pcall(f) end
      if ok and v ~= nil and tostring(v) ~= "" and tostring(v) ~= "name" then
        return tostring(v)
      end
    end
  end
  return ""
end

function GM.my_level()
  -- a) native getter
  if isfn(GM.fn.get_level) then
    local ok, v = pcall(GM.fn.get_level)
    if ok and type(v) == "number" then return v end
  end

  -- b) documented GS value helpers: gv("level") / get_value("level")
  local names = { "gv", "get_value" }
  local keys  = { "level", "lv" }
  local i, j
  for i = 1, #names do
    local f = nil
    if type(_G) == "table" then f = _G[names[i]] end
    if isfn(f) then
      for j = 1, #keys do
        local ok, v = pcall(f, keys[j])
        if ok and type(v) == "number" and v > 0 and v < 1000 then return v end
      end
    end
  end

  -- c) other getters seen on 9.x builds
    local other = { "get_lv", "get_level_value", "player_level" }
  for i = 1, #other do
    local f = nil
    if type(_G) == "table" then f = _G[other[i]] end
    if isfn(f) then
      local ok, v = pcall(f)
      if ok and type(v) == "number" and v > 0 and v < 1000 then return v end
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

-- ============================================================
--  4) DIALOG
-- ============================================================

local function show(title, text, list)
  if isfn(GM.fn.dlg_title) then GM.t1(GM.fn.dlg_title, title) end
  if isfn(GM.fn.dlg_text) then  GM.t1(GM.fn.dlg_text, text)  end

  local i
  for i = 1, count(list) do
    if isfn(GM.fn.dlg_menu) then
      GM.t2(GM.fn.dlg_menu, list[i][1], list[i][2] .. "()")
    end
  end

  if isfn(GM.fn.dlg_show) then GM.t0(GM.fn.dlg_show) end
end

function GM.msg(title, text)
  show(title, text, { { "Close", "gm_close" } })
end

-- ============================================================
--  5) ACTION ENGINE
-- ============================================================

-- returns true if anything succeeded
function GM.act_gold(n)
  if GM.t1(GM.fn.insert_gold, n) then return true end
  if GM.t1(GM.fn.add_gold, n)    then return true end
  if GM.t2(GM.fn.set_value, "gold", n) then return true end
  if GM.t1(GM.fn.set_gold, n)    then return true end
  return false
end

function GM.act_level(mode, n)
  if mode == "set" then
    if GM.t1(GM.fn.set_level, n) then log("set_level " .. n .. " ok"); return true end
    if GM.t1(GM.fn.set_lv,    n) then log("set_lv " .. n .. " ok");    return true end
    if GM.t2(GM.fn.set_value, "lv", n) then log("set_value lv ok"); return true end
    if GM.t2(GM.fn.set_value, "level", n) then log("set_value level ok"); return true end
    log("set level " .. n .. " FAILED - all setters refused")
    return false
  end

  -- add mode: a native add_level also awards skill / stat points
  if GM.t1(GM.fn.add_level, n) then log("add_level " .. n .. " ok"); return true end

  local cur = GM.my_level()
  if cur == nil then
    -- v1.2 SAFETY: without a readable current level, "add" would have to
    -- guess, and set_level(n) would SET the level to n instead of adding it.
    log("level add refused: current level unknown")
    return false
  end
  local target = cur + n
  log("level add: cur=" .. tostring(cur) .. " target=" .. tostring(target))
  if GM.t1(GM.fn.set_level, target) then log("set_level " .. target .. " ok (silent, no skill points)"); return true end
  if GM.t1(GM.fn.set_lv, target) then log("set_lv " .. target .. " ok"); return true end
  if GM.t2(GM.fn.set_value, "lv", target) then return true end
  return false
end

function GM.act_exp(exp, jp)
  if GM.t2(GM.fn.add_exp_jp, exp, jp) then return true end
  if exp ~= 0 and GM.t1(GM.fn.add_exp, exp) then return true end
  if jp  ~= 0 and GM.t1(GM.fn.add_jp, jp)  then return true end
  return false
end

function GM.act_buff(code, level, minutes)
  local ms = minutes * 60000
  if GM.t3(GM.fn.add_state, code, level, ms) then return true end
  return false
end

-- v1.5: buff a player BY NAME (the 4th argument form used by GM commands)
function GM.act_buff_to(name, code, level, ms)
  if name == nil or tostring(name) == "" then return false end
  if GM.t4(GM.fn.add_state, code, level, ms, tostring(name)) then
    log("add_state(name) ok -> " .. tostring(name))
    return true
  end
  log("add_state(name) REFUSED for " .. tostring(name))
  return false
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

-- nil = not tested yet, true = works, false = dead (stop trying)
GM.notice_state = nil

function GM.act_notice(text)
  if GM.notice_state == false then return false end

  -- 1) plain single-argument calls
  if GM.t1(GM.fn.notice_c, text) then GM.notice_state = true; return true end
  if GM.t1(GM.fn.notice_d, text) then GM.notice_state = true; return true end

  -- 2) two-argument calls (text, type) - what SCRIPT_BroadcastNotice expects
  if GM.t2(GM.fn.notice_c, text, 0) then GM.notice_state = true; return true end
  if GM.t2(GM.fn.notice_a, text, 0) then GM.notice_state = true; return true end
  if GM.t2(GM.fn.notice_b, text, 0) then GM.notice_state = true; return true end

  GM.notice_state = false
  log("notice disabled: no working announce call on this build")
  return false
end

-- Gift wrapper: action + optional server-wide announcement
function GM.gift(label, ok, target_name)
  if not ok then
    GM.msg("RZ-GM", label .. " : NOT SUPPORTED on this server build.\nOpen [Report] to see what is missing.")
    return
  end

  local who = target_name
  if who == nil or who == "" then who = GM.me() end
  if who == "" then who = "player" end

  if GM.announce == true then
    local text = "[GM] " .. who .. " received: " .. label
    if not GM.act_notice(text) then
      log("notice failed: " .. text)
    end
  end

  GM.msg("RZ-GM", "Done: " .. label .. " -> " .. who)
end

-- ============================================================
--  6) CAPABILITY PROBE / REPORT
-- ============================================================

GM.probe = {
  { "dialog dlg_title",   GM.fn.dlg_title  },
  { "dialog dlg_text",    GM.fn.dlg_text   },
  { "dialog dlg_menu",    GM.fn.dlg_menu   },
  { "dialog dlg_show",    GM.fn.dlg_show   },
  { "player get_name",    GM.fn.get_name   },
  { "player get_level",   GM.fn.get_level  },
  { "player get_gold",    GM.fn.get_gold   },
  { "player has_item",    GM.fn.has_item   },
  { "gold set_value",     GM.fn.set_value  },
  { "gold insert_gold",   GM.fn.insert_gold},
  { "level set_level",    GM.fn.set_level  },
  { "exp add_exp_jp",     GM.fn.add_exp_jp },
  { "buff add_state",     GM.fn.add_state  },
  { "heal heal",          GM.fn.heal       },
  { "item insert_item",   GM.fn.insert_item},
  { "notice Broadcast",   GM.fn.notice_a   },
  { "notice Announce",    GM.fn.notice_b   },
  { "notice broadcast",   GM.fn.notice_c   },
  { "sql db_select",       GM.fn.db_select  },
  { "sql db_exec",         GM.fn.db_exec    },
  { "player find_player",  GM.fn.find_player },
  { "player get_player",   GM.fn.get_player  },
  { "player get_pc_by_nm", GM.fn.get_player_b},
  { "player get_pc",       GM.fn.get_player_c},
  { "player find_pc",      GM.fn.find_pc     },
  { "player is_online",    GM.fn.is_online   },
  { "level add_level",     GM.fn.add_level   },
  { "level get_lv",        GM.fn.get_lv      },
  { "skill add_skill_pt",  GM.fn.add_skill   },
  { "skill set_skill_pt",  GM.fn.set_skill   },
  { "skill get_skill_pt",  GM.fn.get_skill   },
  { "stat add_stat_pt",    GM.fn.add_stat    },
  { "stat set_stat_pt",    GM.fn.set_stat    },
  { "value gv",            GM.fn.gv          },
  { "value get_value",     GM.fn.get_value   },
  { "exp add_exp",         GM.fn.add_exp     },
  { "exp add_jp",          GM.fn.add_jp      }
}

function GM.report_lines()
  local out = {}
  local i
  for i = 1, count(GM.probe) do
    local mark = "MISSING"
    if isfn(GM.probe[i][2]) then mark = "OK" end
    out[i] = GM.probe[i][1] .. " = " .. mark
  end
  return out
end

function GM.report_dump()
  log("---- capability report ----")
  local l = GM.report_lines()
  local i
  for i = 1, count(l) do log(l[i]) end
  log("---- end report ----")
end

function gm_report()
  GM.report_dump()

  local l = GM.report_lines()
  local txt = ""
  local i
  for i = 1, count(l) do
    if i <= 12 then txt = txt .. l[i] .. "\n" end
  end
  txt = txt .. "(full list printed to server console)"

  GM.msg("RZ-GM Report", txt)
end

-- ============================================================
--  7) MENUS
-- ============================================================

function gm_close()
  if isfn(GM.fn.dlg_show) then
    -- an empty menu closes the window on most builds
    if isfn(GM.fn.dlg_title) then GM.t1(GM.fn.dlg_title, " ") end
    if isfn(GM.fn.dlg_text)  then GM.t1(GM.fn.dlg_text, " ")  end
    GM.t0(GM.fn.dlg_show)
  end
end

function gm_open()
  if GM.gate_ok() ~= true then
    GM.msg("Restricted", "This board is for GM characters only.")
    return
  end
  gm_main()
end

function gm_main()
  local info = "RZ-GM Board v" .. GM.VERSION
  info = info .. "\nPlayer: " .. GM.me()

  local lv = GM.my_level()
  if lv ~= nil then info = info .. "   Level: " .. tostring(lv) end

  local list = {
    { "Self - gold / level / exp / buff / item", "gm_t_self"  },
    { "All online players",                      "gm_t_all"   },
    { "Named player",                            "gm_t_named" },
    { "Announce message",                        "gm_announce_menu" },
    { "Capability report",                       "gm_report"  },
    { "Close",                                   "gm_close"   }
  }

  show(info, "Choose a target:", list)
end

function gm_t_self()
  GM.target = "self"
  gm_actions()
end

function gm_t_all()
  GM.target = "all"
  gm_actions()
end

function gm_t_named()
  local list = {}
  local i
  for i = 1, 8 do
    if GM.players[i] ~= nil then
      list[count(list) + 1] = { GM.players[i], "gm_named" .. i }
    end
  end
  list[count(list) + 1] = { "Back", "gm_main" }
  show("RZ-GM", "Pick the receiving character:", list)
end

local function named_pick(n)
  local name = GM.players[n]
  if name == nil then
    GM.msg("RZ-GM", "No name configured for slot " .. tostring(n))
    return
  end
  GM.target = name
  gm_actions()
end

function gm_named1() named_pick(1) end
function gm_named2() named_pick(2) end
function gm_named3() named_pick(3) end
function gm_named4() named_pick(4) end
function gm_named5() named_pick(5) end
function gm_named6() named_pick(6) end
function gm_named7() named_pick(7) end
function gm_named8() named_pick(8) end

function gm_actions()
  local t = GM.target
  if t == nil then t = "self" end

  local list = {
    { "Gold",        "gm_do_gold"  },
    { "Level",       "gm_do_level" },
    { "Exp / JP",    "gm_do_exp"   },
    { "Buff",        "gm_do_buff"  },
    { "Heal",        "gm_do_heal"  },
    { "Item",        "gm_do_item"  },
    { "Permanent blessing (all buffs)", "gm_buff_all" },
    { "Back",        "gm_main"     }
  }

  show("RZ-GM", "Target: " .. t .. "\nChoose an action:", list)
end

-- ---- gold ---------------------------------------------------
function gm_do_gold()
  local list = {}
  local i
  for i = 1, count(GM.amounts) do
    list[i] = { tostring(GM.amounts[i]) .. " gold", "gm_amt" .. i }
  end
  list[count(list) + 1] = { "Back", "gm_actions" }
  show("RZ-GM", "How much gold?", list)
end

local function do_gold(n)
  if GM.target ~= "self" and GM.target ~= GM.me() then
    GM.msg("RZ-GM", "Target: " .. tostring(GM.target) ..
      "\n\nThis build can only grant to the player who opened the board.\n" ..
      "Use the Windows tool (GM-Tool.ps1) for other players.")
    return
  end
  local ok = GM.act_gold(n)
  GM.gift(tostring(n) .. " gold", ok, GM.me())
end

function gm_amt1() do_gold(GM.amounts[1]) end
function gm_amt2() do_gold(GM.amounts[2]) end
function gm_amt3() do_gold(GM.amounts[3]) end
function gm_amt4() do_gold(GM.amounts[4]) end

-- ---- level --------------------------------------------------
function gm_do_level()
  local list = {}
  local i
  for i = 1, count(GM.level_ops) do
    local op = GM.level_ops[i]
    local lbl = ""
    if op[1] == "set" then lbl = "set to " .. tostring(op[2])
    else lbl = "+" .. tostring(op[2]) .. " level" end
    list[i] = { lbl, "gm_lvl" .. i }
  end
  list[count(list) + 1] = { "Back", "gm_actions" }
  show("RZ-GM", "Level change:", list)
end

local function do_level(i)
  local op = GM.level_ops[i]
  if op == nil then return end
  if GM.target ~= "self" and GM.target ~= GM.me() then
    GM.msg("RZ-GM", "This build can only change the level of the player who opened the board.")
    return
  end
  if op[1] ~= "set" and GM.my_level() == nil then
    GM.msg("RZ-GM", "Cannot read your current level on this build,\n" ..
      "so '+' operations are blocked to protect your character.\n\n" ..
      "Use a [set to N] option instead.")
    return
  end
  local ok = GM.act_level(op[1], op[2])
  GM.gift("level " .. tostring(op[1]) .. " " .. tostring(op[2]), ok, GM.me())
end

function gm_lvl1() do_level(1) end
function gm_lvl2() do_level(2) end
function gm_lvl3() do_level(3) end
function gm_lvl4() do_level(4) end

-- ---- exp / jp -----------------------------------------------
function gm_do_exp()
  local list = {}
  local i
  for i = 1, count(GM.exp_ops) do
    local op = GM.exp_ops[i]
    list[i] = { "exp " .. tostring(op[1]) .. " / jp " .. tostring(op[2]), "gm_exp" .. i }
  end
  list[count(list) + 1] = { "Back", "gm_actions" }
  show("RZ-GM", "Exp / JP:", list)
end

local function do_exp(i)
  local op = GM.exp_ops[i]
  if op == nil then return end
  local ok = GM.act_exp(op[1], op[2])
  GM.gift("exp " .. tostring(op[1]) .. " jp " .. tostring(op[2]), ok, GM.me())
end

function gm_exp1() do_exp(1) end
function gm_exp2() do_exp(2) end
function gm_exp3() do_exp(3) end
function gm_exp4() do_exp(4) end

-- ---- buff ---------------------------------------------------
function gm_do_buff()
  if count(GM.buffs) == 0 then
    GM.msg("RZ-GM", "No buffs configured.\n\nEdit GM.buffs inside NPC_GM_Board.lua and recompress.")
    return
  end
  local list = {}
  local i
  for i = 1, count(GM.buffs) do
    local b = GM.buffs[i]
    list[i] = { "state " .. tostring(b[1]) .. " lv" .. tostring(b[2]), "gm_buff" .. i }
  end
  list[count(list) + 1] = { "Back", "gm_actions" }
  show("RZ-GM", "Buffs:", list)
end

local function do_buff(i)
  local b = GM.buffs[i]
  if b == nil then return end
  local ok
  local t = GM.target
  if t == nil or t == "self" or t == "all" or t == GM.me() then
    ok = GM.act_buff(b[1], b[2], b[3])
  else
    ok = GM.act_buff_to(t, b[1], b[2], b[3] * 60000)
  end
  GM.gift("buff " .. tostring(b[1]) .. " -> " .. tostring(t or "self"), ok, t)
end

-- v1.5: apply every configured buff with the longest duration
function gm_buff_all()
  local t = GM.target
  local n = 0
  local i
  for i = 1, count(GM.buffs) do
    local b = GM.buffs[i]
    local ok
    if t == nil or t == "self" or t == "all" or t == GM.me() then
      ok = GM.act_buff(b[1], b[2], GM.permanent_ms / 60000)
    else
      ok = GM.act_buff_to(t, b[1], b[2], GM.permanent_ms)
    end
    if ok then n = n + 1 end
  end
  GM.msg("RZ-GM", "Permanent blessing: " .. tostring(n) .. "/" ..
    tostring(count(GM.buffs)) .. " states applied to " .. tostring(t or "self"))
end

function gm_buff1() do_buff(1) end
function gm_buff2() do_buff(2) end
function gm_buff3() do_buff(3) end
function gm_buff4() do_buff(4) end

-- ---- heal ---------------------------------------------------
function gm_do_heal()
  local ok = GM.act_heal()
  GM.gift("full heal", ok, GM.me())
end

-- ---- item ---------------------------------------------------
function gm_do_item()
  if count(GM.items) == 0 then
    GM.msg("RZ-GM", "No items configured.\n\nEdit GM.items inside NPC_GM_Board.lua and recompress.")
    return
  end
  local list = {}
  local i
  for i = 1, count(GM.items) do
    local it = GM.items[i]
    local lbl = it[3]
    if lbl == nil then lbl = "item " .. tostring(it[1]) end
    list[i] = { lbl .. " x" .. tostring(it[2]), "gm_item" .. i }
  end
  list[count(list) + 1] = { "Back", "gm_actions" }
  show("RZ-GM", "Items:", list)
end

local function do_item(i)
  local it = GM.items[i]
  if it == nil then return end
  local ok = GM.act_item(it[1], it[2])
  GM.gift((it[3] or ("item " .. tostring(it[1]))) .. " x" .. tostring(it[2]), ok, GM.me())
end

function gm_item1() do_item(1) end
function gm_item2() do_item(2) end
function gm_item3() do_item(3) end
function gm_item4() do_item(4) end

-- ---- announce -----------------------------------------------
function gm_announce_menu()
  if count(GM.players) == 0 then
    GM.msg("RZ-GM", "No names in GM.players.\n\nAdd names inside NPC_GM_Board.lua.")
    return
  end
  local list = {}
  local i
  for i = 1, count(GM.players) do
    if i <= 8 then
      list[count(list) + 1] = { "Announce gift to " .. GM.players[i], "gm_ann" .. i }
    end
  end
  list[count(list) + 1] = { "Plain test notice", "gm_ann_test" }
  list[count(list) + 1] = { "Back", "gm_main" }
  show("RZ-GM", "Announcements:", list)
end

local function ann(i)
  local name = GM.players[i]
  if name == nil then return end
  local ok = GM.act_notice("[GM] " .. name .. " has received a gift. Congratulations!")
  if ok then GM.msg("RZ-GM", "Notice sent.")
  else GM.msg("RZ-GM", "Notice NOT supported on this build. See [Report].") end
end

function gm_ann1() ann(1) end
function gm_ann2() ann(2) end
function gm_ann3() ann(3) end
function gm_ann4() ann(4) end
function gm_ann5() ann(5) end
function gm_ann6() ann(6) end
function gm_ann7() ann(7) end
function gm_ann8() ann(8) end

function gm_ann_test()
  local ok = GM.act_notice("[GM] RZ-GM board test notice.")
  if ok then GM.msg("RZ-GM", "Test notice sent.")
  else GM.msg("RZ-GM", "Notice NOT supported on this build. See [Report].") end
end

-- ============================================================
--  8) HOOK INTO AN EXISTING NPC
-- ============================================================

-- Replaces <npc_contact_fn> with a wrapper:
--   * GM character  -> RZ-GM board
--   * anyone else   -> the original npc dialog, untouched
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
    pcall(function()
      ok = GM.gate_ok()
    end)
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

-- installed hook (v1.5)
GM.install_hook("NPC_Auction_Gaia_contact")
