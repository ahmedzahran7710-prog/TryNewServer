-- ============================================================
--  rz_gift_box.lua  v1.1   (ASCII ONLY)
--  First-login gift bag  --  Rappelz Epic 9.1
--
--  v1.1 changes
--    * one bag per character class (Fighter / Hunter / Magician / Summoner)
--    * the bag id selects the content list -> no class detection in Lua
--    * shared content (buffs / energy / boosters) is added to every bag
--    * announcement is OFF by default
--
--  HOW IT WORKS
--    1. Arcadia.dbo.ItemResource:
--         script_text   = 'rz_gift_open'
--         item_use_flag = 527   (USE + CANT_TRADE + CANT_STORAGE
--                                + CANT_DONATE + CANT_ENHANCE)
--    2. The server loads this file, get_module_name() = "rz_gift_open"
--    3. A player USES the bag  ->  rz_gift_open(id)
--    4. The matching content list is inserted
--    5. The bag is removed (no duplication)
-- ============================================================

RZ_GIFT = RZ_GIFT or {}
RZ_GIFT.VERSION = "1.1"
RZ_GIFT.tag = "[RZ-GIFT]"

-- ============================================================
--  SETTINGS
-- ============================================================

RZ_GIFT.announce = false      -- server-wide notice on open
RZ_GIFT.consume_bag = true    -- remove the bag after opening
RZ_GIFT.strict = true         -- true = only listed bag ids can be opened

-- ============================================================
--  SHARED CONTENT  (added to every bag)
--  { code, qty, "note" }
-- ============================================================

RZ_GIFT.buff_items = {
  -- { 0, 1, "Anais buff 1" },
}

RZ_GIFT.energy_items = {
  -- { 0, 1, "energy part" },
}

RZ_GIFT.consumables = {
  -- { 0, 20, "activity stabilizer"         },
  -- { 0,  5, "deluxe activity stabilizer"  },
  -- { 0, 20, "exp multiplier"              },
  -- { 0,  5, "legendary exp multiplier"    },
}

-- ============================================================
--  CLASS BAGS  -- one bag item id per class
--  The delivery trigger gives the right bag based on the
--  character's class, so this file never needs to detect it.
-- ============================================================

RZ_GIFT.bags = {
  -- [97000001] = { label = "Fighter", items = {
  --     { 0, 1, "150 armor - fighter" },
  --     { 0, 1, "150 weapon - fighter" },
  -- }},
  -- [97000002] = { label = "Hunter", items = {
  --     { 0, 1, "150 armor - hunter" },
  --     { 0, 1, "150 weapon - hunter" },
  -- }},
  -- [97000003] = { label = "Magician", items = {
  --     { 0, 1, "150 armor - magician" },
  --     { 0, 1, "150 weapon - magician" },
  -- }},
  -- [97000004] = { label = "Summoner", items = {
  --     { 0, 1, "150 armor - summoner" },
  --     { 0, 1, "150 weapon - summoner" },
  -- }},
}

-- ============================================================
--  HELPERS
-- ============================================================

local function log(msg)
  if type(print) == "function" then
    pcall(print, RZ_GIFT.tag .. " " .. tostring(msg))
  end
end

RZ_GIFT.log = log

local function count(t)
  if t == nil then return 0 end
  if table.getn ~= nil then return table.getn(t) end
  local n, k, v = 0, nil, nil
  for k, v in pairs(t) do n = n + 1 end
  return n
end

local function isfn(f) return type(f) == "function" end

local function try2(f, a, b)
  if not isfn(f) then return false end
  return pcall(f, a, b)
end

-- number of keys in the bags table (it is keyed by id, not array)
function RZ_GIFT.bag_count()
  local n, k, v = 0, nil, nil
  for k, v in pairs(RZ_GIFT.bags) do n = n + 1 end
  return n
end

-- ============================================================
--  INSERT ENGINE  (three known signatures, tried in order)
-- ============================================================

function RZ_GIFT.give(code, qty)
  if code == nil or code == 0 then return false end
  if qty == nil or qty < 1 then qty = 1 end

  if isfn(insert_item) then
    if pcall(insert_item, code, qty, 0, 0, 2) then return true end
    if pcall(insert_item, code, qty, 0, 0)    then return true end
    if pcall(insert_item, code, qty, 2, 0)    then return true end
    if pcall(insert_item, code, qty)          then return true end
  end

  if isfn(give_item) then if try2(give_item, code, qty) then return true end end
  if isfn(add_item)  then if try2(add_item,  code, qty) then return true end end

  return false
end

-- ============================================================
--  REMOVE ENGINE
-- ============================================================

function RZ_GIFT.take_bag(id, qty)
  if id == nil then return false end
  if isfn(delete_item) then
    if pcall(delete_item, id, qty) then return true end
    if pcall(delete_item, id)      then return true end
  end
  if isfn(remove_item)  then if try2(remove_item,  id, qty) then return true end end
  if isfn(consume_item) then if try2(consume_item, id, qty) then return true end end
  return false
end

-- ============================================================
--  NOTICE
-- ============================================================

function RZ_GIFT.notice(text)
  if isfn(SCRIPT_BroadcastNotice) then if pcall(SCRIPT_BroadcastNotice, text) then return true end end
  if isfn(SCRIPT_Announce)        then if pcall(SCRIPT_Announce, text)        then return true end end
  if isfn(broadcast_notice)       then if pcall(broadcast_notice, text)       then return true end end
  return false
end

function RZ_GIFT.who()
  if isfn(get_name) then
    local ok, n = pcall(get_name)
    if ok and n ~= nil then return tostring(n) end
  end
  return "player"
end

-- ============================================================
--  GIVING
-- ============================================================

local function give_list(list, label, stats)
  local i
  for i = 1, count(list) do
    local it = list[i]
    if it[1] ~= nil and it[1] ~= 0 then
      if RZ_GIFT.give(it[1], it[2]) then
        stats.ok = stats.ok + 1
        log("  + " .. label .. " " .. tostring(it[1]) .. " x" .. tostring(it[2]))
      else
        stats.fail = stats.fail + 1
        log("  ! FAILED " .. label .. " " .. tostring(it[1]))
      end
    end
  end
end

-- ============================================================
--  OPEN
-- ============================================================

function rz_gift_open(id)
  local stats = { ok = 0, fail = 0 }
  local who = RZ_GIFT.who()
  local bag = RZ_GIFT.bags[id]

  if bag == nil and RZ_GIFT.strict == true and RZ_GIFT.bag_count() > 0 then
    log("refused: item " .. tostring(id) .. " is not a registered gift bag")
    return false
  end

  local label = "shared"
  if bag ~= nil and bag.label ~= nil then label = bag.label end

  log("opening " .. label .. " gift for " .. who .. " (item " .. tostring(id) .. ")")

  if bag ~= nil then
    give_list(bag.items, label, stats)
  end

  give_list(RZ_GIFT.buff_items,   "buff",   stats)
  give_list(RZ_GIFT.energy_items, "energy", stats)
  give_list(RZ_GIFT.consumables,  "item",   stats)

  if RZ_GIFT.consume_bag == true then
    if RZ_GIFT.take_bag(id, 1) then log("bag removed")
    else log("WARNING: could not remove the bag - check for duplication") end
  end

  log("result: " .. stats.ok .. " granted, " .. stats.fail .. " failed")

  if RZ_GIFT.announce == true and stats.ok > 0 then
    RZ_GIFT.notice("[GM] " .. who .. " opened the first-login gift bag!")
  end

  return true
end

-- ============================================================
--  MODULE NAME
-- ============================================================

function get_module_name()
  return "rz_gift_open"
end

-- ============================================================
--  BOOT REPORT
-- ============================================================

log("gift box v" .. RZ_GIFT.VERSION ..
    " loaded. bags = " .. tostring(RZ_GIFT.bag_count()) ..
    " | buffs = " .. tostring(count(RZ_GIFT.buff_items)) ..
    " | energy = " .. tostring(count(RZ_GIFT.energy_items)) ..
    " | consumables = " .. tostring(count(RZ_GIFT.consumables)))
