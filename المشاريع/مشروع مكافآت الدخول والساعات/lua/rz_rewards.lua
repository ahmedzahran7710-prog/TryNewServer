-- ============================================================
--  rz_rewards.lua  v1.0
--  Daily login rewards + hourly online rewards
--  Rappelz 9.1  (GameServer Lua)   ASCII ONLY
--
--  ECONOMY RULE (why this cannot inflate the market):
--    * no gold is ever granted
--    * no tradeable item is ever granted (bind bits forced)
--    * rewards only REPLACE things the player would spend gold on
--  => it removes a cost, it never adds income to the market.
-- ============================================================

local unpack = (table and table.unpack) or unpack

local M = {}
RZ_RW = M
M.version = "1.0"

-- ------------------------------------------------------------
-- 1. CONFIG  (edit only this block + item codes below)
-- ------------------------------------------------------------
M.cfg = {
  enabled          = true,   -- master switch
  per_account      = true,   -- true = one reward set per ACCOUNT per day (anti-alt)
  min_level        = 40,     -- hourly rewards require this level
  hour_window      = 3600,   -- seconds of online time per hourly reward
  hour_max_per_day = 4,      -- hard cap of hourly rewards per day
  streak_max       = 7,      -- daily cycle length
  tz_offset_sec    = 0,      -- e.g. 7200 for UTC+2 if day boundary is off
  notify           = true,   -- whisper the player on grant
  bind_bits        = 515,    -- CANT_DONATE(1) + CANT_STORAGE(2) + CANT_TRADE(512)
}

-- ------------------------------------------------------------
-- 2. ITEM CODES  (0 = not configured yet -> that reward is skipped)
--    Fill these from sql/01-discover-items.sql
-- ------------------------------------------------------------
M.items = {
  repair_kit      = 0,
  potion_hp       = 0,
  potion_mp       = 0,
  exp10           = 0,
  exp20           = 0,
  exp30           = 0,
  drop10          = 0,
  teleport_scroll = 0,
  res_scroll      = 0,
  pet_food        = 0,
  buff_scroll     = 0,
}

-- ------------------------------------------------------------
-- 3. REWARD TABLES  (loaded from rz_rewards_table.lua)
--    The owner fills that file; this engine only validates + runs it.
--    Empty table = nothing is granted (safe default).
-- ------------------------------------------------------------
local T = _G.RZ_TABLE or {}
M.daily_cycle = T.daily  or {}
M.hour_cycle  = T.hourly or {}

-- Validates the owner-supplied table. Bad rows are reported, never fatal.
function M.validate()
  local problems = {}

  local function check_cycle(cyc, tag)
    if cyc == nil then
      problems[#problems + 1] = tag .. ": missing (treated as empty)"
      return
    end
    if type(cyc) ~= "table" then
      problems[#problems + 1] = tag .. ": not a table"
      return
    end
    local slots = 0
    for i, bundle in pairs(cyc) do
      slots = slots + 1
      local where = tag .. "[" .. tostring(i) .. "]"
      if type(bundle) ~= "table" then
        problems[#problems + 1] = where .. ": bundle is not a table"
      elseif type(bundle.items) ~= "table" then
        problems[#problems + 1] = where .. ": missing items list"
      else
        local n_items = 0
        for j, it in pairs(bundle.items) do
          n_items = n_items + 1
          local w = where .. ".items[" .. tostring(j) .. "]"
          if type(it) ~= "table" then
            problems[#problems + 1] = w .. ": item is not a table"
          else
            if type(it.k) ~= "string" then
              problems[#problems + 1] = w .. ": key 'k' must be a string"
            elseif M.items[it.k] == nil then
              problems[#problems + 1] = w .. ": unknown item key '" .. tostring(it.k) .. "'"
            end
            local q = tonumber(it.n)
            if not q or q < 1 or q > 99 or q ~= math.floor(q) then
              problems[#problems + 1] = w .. ": quantity must be an integer 1..99"
            end
          end
        end
        if n_items == 0 then
          problems[#problems + 1] = where .. ": empty items list"
        end
      end
    end
    if slots == 0 then
      problems[#problems + 1] = tag .. ": no slots defined yet (nothing will be granted)"
    end
  end

  check_cycle(M.daily_cycle,  "daily")
  check_cycle(M.hour_cycle,   "hourly")
  return problems
end

function M.has_rewards()
  local d, h = 0, 0
  for _ in pairs(M.daily_cycle) do d = d + 1 end
  for _ in pairs(M.hour_cycle)  do h = h + 1 end
  return (d + h) > 0, d, h
end

-- ------------------------------------------------------------
-- 4. ENGINE BRIDGE  (every engine call is optional / pcall-guarded)
-- ------------------------------------------------------------
local function has(fn)
  return type(_G[fn]) == "function"
end

local function engine(fn, ...)
  if not has(fn) then return nil end
  local r = { pcall(_G[fn], ...) }
  if r[1] then return r[2], r[3] end
  return nil
end

function M.now()
  if _G.os and type(_G.os.time) == "function" then
    local ok, t = pcall(_G.os.time)
    if ok and tonumber(t) then return tonumber(t) end
  end
  local t = engine("get_now")
  return tonumber(t) or 0
end

function M.log(msg)
  if has("message") then pcall(_G.message, msg) else print(msg) end
end

-- read a StructPlayer field for a character
function M.pget(name, field)
  local v = engine("get_value", field, name)
  if v == nil then v = engine("gv", field, name) end
  if v == nil then v = engine("get_value", field) end
  if v == nil then v = engine("gv", field) end
  return v
end

-- true / false / nil(unknown)
function M.online(name)
  local list = { "is_online", "is_connected", "check_online", "is_user_online" }
  for i = 1, #list do
    local fn = _G[list[i]]
    if type(fn) == "function" then
      local ok, r = pcall(fn, name)
      if ok then return r and true or false end
    end
  end
  return nil
end

-- ------------------------------------------------------------
-- 5. STATE STORE  (dbo.GlobalVariable through the engine)
-- ------------------------------------------------------------
function M.sget(key)
  local v = engine("get_global_variable", key)
  if v == nil then return nil end
  v = tostring(v)
  if v == "" then return nil end
  return v
end

function M.sset(key, value)
  engine("set_global_variable", key, value)
end

function M.scope(name)
  local id
  if M.cfg.per_account then
    local acct = M.pget(name, "account_id")
    if acct ~= nil and tostring(acct) ~= "" then id = "A" .. tostring(acct) end
  end
  if id == nil then id = "C" .. tostring(name) end
  return "RZ_RW." .. id
end

function M.day_id(t)
  t = tonumber(t) or M.now()
  return math.floor((t + M.cfg.tz_offset_sec) / 86400)
end

-- ------------------------------------------------------------
-- 6. DELIVERY
-- ------------------------------------------------------------
function M.notice(name, text)
  if not M.cfg.notify then return end
  if has("whisper") then
    if pcall(_G.whisper, name, text) then return end
  end
  if has("private_notice") then
    local ok = pcall(_G.private_notice, text)
    if ok then return end
  end
end

-- Tries several insert_item signatures. First non-error wins.
function M.give(name, code, qty)
  code = tonumber(code) or 0
  if code <= 0 then return false end
  qty = tonumber(qty) or 1
  local flag = M.cfg.bind_bits

  if has("insert_item") then
    local tests = {
      { code, qty, 0, 0, flag, name },
      { code, qty, 0, 0, flag },
      { code, qty, 0, 0, 2, name },
      { code, qty, 0, 0, 2 },
      { code, qty, 0, 0 },
      { code, qty },
    }
    for i = 1, #tests do
      local ok = pcall(_G.insert_item, unpack(tests[i]))
      if ok then return true end
    end
  end

  if has("give_item") then
    if pcall(_G.give_item, name, code, qty) then return true end
  end
  if has("add_item") then
    if pcall(_G.add_item, name, code, qty) then return true end
  end
  return false
end

function M.grant(name, bundle, tag)
  if not bundle or not bundle.items then return 0 end
  local delivered, skipped = 0, 0
  for i = 1, #bundle.items do
    local it = bundle.items[i]
    local code = M.items[it.k]
    if code and tonumber(code) and tonumber(code) > 0 then
      if M.give(name, code, it.n) then delivered = delivered + 1 else skipped = skipped + 1 end
    else
      skipped = skipped + 1
    end
  end
  if delivered > 0 and M.cfg.notify then
    M.notice(name, string.format("[Reward] %s delivered (%d item types).", tostring(tag), delivered))
  end
  if skipped > 0 and skipped == #bundle.items then
    M.log("[RZ-REWARDS] " .. tostring(tag) .. " skipped - item codes not configured in M.items")
  end
  return delivered
end

-- ------------------------------------------------------------
-- 7. DAILY LOGIN REWARD
-- ------------------------------------------------------------
function M.daily(name)
  if not M.cfg.enabled then return "disabled" end
  if not name or name == "" then return "noname" end
  if M.online(name) == false then return "offline" end

  local s = M.scope(name)
  local today = M.day_id()
  local last = tonumber(M.sget(s .. ".last_daily")) or -1
  if last == today then return "already" end

  local streak = tonumber(M.sget(s .. ".streak")) or 0
  if last == today - 1 then
    streak = streak + 1
  else
    streak = 1
  end
  if streak > M.cfg.streak_max or streak < 1 then streak = 1 end

  local bundle = M.daily_cycle[streak]
  if not bundle then
    local any = M.has_rewards()
    if not any then return "no_rewards" end
    return "nocycle"
  end

  local n = M.grant(name, bundle, bundle.label)
  M.sset(s .. ".streak", streak)
  M.sset(s .. ".last_daily", today)
  return "ok", streak, n
end

-- ------------------------------------------------------------
-- 8. HOURLY ONLINE REWARD
-- ------------------------------------------------------------
function M.hourly(name)
  if not M.cfg.enabled then return "disabled" end
  if not name or name == "" then return "noname" end
  if M.online(name) == false then return "offline" end

  local lvl = tonumber(M.pget(name, "level")) or 0
  if lvl < M.cfg.min_level then return "low_level" end

  local s = M.scope(name)
  local today = M.day_id()
  local hday = tonumber(M.sget(s .. ".hour_day")) or -1
  local count = 0
  if hday == today then count = tonumber(M.sget(s .. ".hour_count")) or 0 end
  if count >= M.cfg.hour_max_per_day then return "cap" end

  local now = M.now()
  local last = tonumber(M.sget(s .. ".hour_last")) or 0
  if last > 0 and (now - last) < M.cfg.hour_window then
    return "wait", M.cfg.hour_window - (now - last)
  end

  local any = M.has_rewards()
  if not any then return "no_rewards" end

  local idx = count + 1
  local bundle = M.hour_cycle[idx]
  if not bundle then
    bundle = M.hour_cycle[((idx - 1) % #M.hour_cycle) + 1]
  end
  if not bundle then return "nocycle" end

  local n = M.grant(name, bundle, bundle.label)
  M.sset(s .. ".hour_day", today)
  M.sset(s .. ".hour_count", count + 1)
  M.sset(s .. ".hour_last", now)
  return "ok", idx, n
end

-- ------------------------------------------------------------
-- 9. SESSIONS + LOGIN HOOK
-- ------------------------------------------------------------
M.sessions = {}

function M.session_add(name) M.sessions[tostring(name)] = true end
function M.session_drop(name) M.sessions[tostring(name)] = nil end

function M.on_login(name)
  if not name or name == "" then return "noname" end
  M.session_add(name)
  if not M.cfg.enabled then return "disabled" end

  local s = M.scope(name)
  local now = M.now()
  local last = tonumber(M.sget(s .. ".hour_last")) or 0

  -- if the player was away longer than one window, the clock restarts
  -- (he must actually play the hour; no offline accrual exploit)
  if last <= 0 or (now - last) >= M.cfg.hour_window then
    M.sset(s .. ".hour_last", now)
  end

  local st, streak = M.daily(name)
  if st == "ok" then
    M.log(string.format("[RZ-REWARDS] daily granted to %s (streak %s)", tostring(name), tostring(streak)))
  end
  return st
end

function M.on_logout(name)
  if name then M.session_drop(name) end
  return "ok"
end

-- ------------------------------------------------------------
-- 10. TICK  (call from any periodic hook -> see rz_tick.lua)
-- ------------------------------------------------------------
function M.tick()
  if not M.cfg.enabled then return 0 end
  local granted = 0
  for name in pairs(M.sessions) do
    if M.online(name) == false then
      M.sessions[name] = nil
    else
      local st = M.hourly(name)
      if st == "ok" then granted = granted + 1 end
    end
  end
  return granted
end

-- ------------------------------------------------------------
-- 11. DIAGNOSTICS
-- ------------------------------------------------------------
function M.unset_items()
  local list = {}
  for k, v in pairs(M.items) do
    if not tonumber(v) or tonumber(v) <= 0 then list[#list + 1] = k end
  end
  table.sort(list)
  return list
end

function M.status(name)
  local s = M.scope(name)
  return string.format(
    "scope=%s level=%s day=%s last_daily=%s streak=%s hour_day=%s count=%s",
    s,
    tostring(M.pget(name, "level")),
    tostring(M.day_id()),
    tostring(M.sget(s .. ".last_daily")),
    tostring(M.sget(s .. ".streak")),
    tostring(M.sget(s .. ".hour_day")),
    tostring(M.sget(s .. ".hour_count"))
  )
end

function M.boot()
  local miss = M.unset_items()
  local any, dcount, hcount = M.has_rewards()
  M.log(string.format(
    "[RZ-REWARDS] v%s loaded | enabled=%s | per_account=%s | hourly cap=%d/day | min level=%d | item codes unset=%d | daily slots=%d | hourly slots=%d",
    M.version, tostring(M.cfg.enabled), tostring(M.cfg.per_account),
    M.cfg.hour_max_per_day, M.cfg.min_level, #miss, dcount, hcount))
  if not any then
    M.log("[RZ-REWARDS] REWARD TABLE IS EMPTY -> nothing will be granted. Fill lua/rz_rewards_table.lua")
  end
  if #miss > 0 then
    M.log("[RZ-REWARDS] item codes still unset in M.items: " .. table.concat(miss, ", "))
  end
  local probs = M.validate()
  if #probs > 0 then
    for i = 1, #probs do
      M.log("[RZ-REWARDS] table warning: " .. tostring(probs[i]))
    end
  end
end

M.boot()
return M
