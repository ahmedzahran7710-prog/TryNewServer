-- ============================================================
--  rz_rewards_table.lua   v1.0        ASCII ONLY
--  >>> THIS IS THE ONLY FILE YOU EDIT TO SET YOUR REWARDS <<<
--
--  It is EMPTY on purpose: nothing is granted until you fill it.
--  The engine (rz_rewards.lua) never needs to be touched.
--
--  TWO WAYS TO FILL IT:
--    (A) easy : fill  جدول-المكافآت.csv  then run
--               python3 tests/check_my_table.py --write
--               (the CSV is re-generated into this file, validated)
--    (B) manual: uncomment / write the rows below by hand.
--
--  RULES (enforced by M.validate(), bad rows are skipped + logged):
--    * k = an item KEY from M.items inside rz_rewards.lua
--    * n = quantity, integer 1..99
--    * put entries in order 1,2,3...
--    * daily  -> one table per streak day (1..7 by default)
--    * hourly -> one table per hour slot (1..hour_max_per_day)
--
--  NOTE: item keys already exist in the engine. If you want a NEW
--  item key (e.g. "my_scroll"), add it to M.items first, then use it.
-- ============================================================

RZ_TABLE = {

  -- ----------------------------------------------------------
  -- DAILY LOGIN REWARDS
  -- ----------------------------------------------------------
  daily = {
    -- [1] = { label = "day 1", items = {
    --     { k = "repair_kit", n = 3 },
    --     { k = "exp10",      n = 1 },
    -- } },
    -- [2] = { label = "day 2", items = {
    --     { k = "potion_hp", n = 20 },
    -- } },
  },

  -- ----------------------------------------------------------
  -- HOURLY ONLINE REWARDS
  -- ----------------------------------------------------------
  hourly = {
    -- [1] = { label = "hour 1", items = {
    --     { k = "repair_kit", n = 1 },
    -- } },
    -- [2] = { label = "hour 2", items = {
    --     { k = "potion_hp", n = 10 },
    --     { k = "potion_mp", n = 10 },
    -- } },
  },
}
