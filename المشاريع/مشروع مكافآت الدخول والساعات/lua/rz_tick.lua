-- ============================================================
--  rz_tick.lua  v1.0
--  Periodic hook bridge for rz_rewards.lua   (ASCII ONLY)
--
--  WHY THIS FILE EXISTS:
--  Rappelz GameServer Lua builds differ in what periodic entry
--  point they call. This file defines the common candidate names
--  and throttles all of them to once per 60 seconds, so:
--     - if the engine calls one of them  -> hourly rewards work live
--     - if the engine calls none of them -> nothing breaks
--  It never overwrites a function that already exists.
--  The boot log tells you which one fired (search: TICK-FIRED).
-- ============================================================

local M = RZ_RW
if not M then
  print("[RZ-TICK] rz_rewards.lua not loaded - tick bridge disabled")
  return
end

local last_run = 0
local fired    = nil

local function guard(tag)
  local now = M.now()
  if now - last_run < 60 then return end
  last_run = now
  if fired ~= tag then
    fired = tag
    M.log("[RZ-TICK] TICK-FIRED via " .. tostring(tag))
  end
  local n = M.tick()
  if n and n > 0 then
    M.log("[RZ-TICK] hourly rewards granted: " .. tostring(n))
  end
end

local names = { "on_minute", "on_1min", "on_min", "run_minute", "on_timer", "timer_tick", "on_second" }

for i = 1, #names do
  local n = names[i]
  if type(_G[n]) ~= "function" then
    _G[n] = function() guard(n) end
  end
end

-- Manual fallback: any NPC script can call RZ_RW.tick() directly.
M.log("[RZ-TICK] tick bridge armed (60s throttle)")
