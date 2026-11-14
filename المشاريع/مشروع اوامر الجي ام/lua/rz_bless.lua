-- ============================================================
--  RZ-BLESS  v1.0  --  permanent blessing states (stage 2)
--  Applies a list of STATES to the player, with the longest
--  duration the field can hold (~23 days), refreshed on use.
--
--  HOW IT IS USED (choose ONE):
--    A) hook a buff NPC  -> RZ_Bless_hook("NPC_xxx_contact")
--    B) call from on_login.lua -> RZ_Bless_give()
--  ASCII ONLY inside this file.
-- ============================================================

RZ_BLESS = {}

-- longest safe value for the int field (~23 days in ms)
RZ_BLESS.DURATION_MS = 2000000000

RZ_BLESS.enabled = true

-- { code, level }   -- 1007 ATK, 1009 DEF, 1010 MDEF, 1013 speed, 1513 MAXHP
RZ_BLESS.states = {
  { 1007, 5 },
  { 1009, 5 },
  { 1013, 5 },
  { 1513, 5 }
}

local function log(m)
  local line = "[RZ-BLESS] " .. tostring(m)
  if type(message) == "function" then pcall(message, line) end
  if type(print) == "function" then pcall(print, line) end
end

local function isfn(f) return type(f) == "function" end

-- works on Lua 5.0 / 5.1 / 5.5
local function count(t)
  if t == nil then return 0 end
  if table.getn ~= nil then return table.getn(t) end
  local n, k = 0, nil
  for k in pairs(t) do n = n + 1 end
  return n
end


-- apply every configured state to the CURRENT player
function RZ_Bless_give()
  if RZ_BLESS.enabled ~= true then return 0 end
  if not isfn(add_state) then
    log("add_state is not available on this build")
    return 0
  end

  local n = 0
  local i
  for i = 1, count(RZ_BLESS.states) do
    local code = RZ_BLESS.states[i][1]
    local lvl  = RZ_BLESS.states[i][2]
    local ok = pcall(add_state, code, lvl, RZ_BLESS.DURATION_MS)
    if ok then
      n = n + 1
      log("state " .. tostring(code) .. " lv" .. tostring(lvl) .. " applied")
    else
      log("state " .. tostring(code) .. " FAILED")
    end
  end
  return n
end

-- replace an npc contact function with: blessing + original dialog
function RZ_Bless_hook(fn_name)
  local G = _G
  local orig = G[fn_name]
  if type(orig) ~= "function" then
    log("hook failed: " .. tostring(fn_name) .. " not found")
    return false
  end
  if G[fn_name .. "_rzbless"] == true then return true end
  G[fn_name .. "_rzbless"] = true

  G[fn_name] = function(...)
    RZ_Bless_give()
    -- Lua 5.0 gives us an "arg" table; Lua 5.1+ gives "..."
    local a = arg
    if a ~= nil then return orig(unpack(a)) end
    return orig(...)
  end
  log("hook installed on " .. tostring(fn_name))
  return true
end

log("rz_bless v1.0 loaded. states: " .. tostring(count(RZ_BLESS.states)))
