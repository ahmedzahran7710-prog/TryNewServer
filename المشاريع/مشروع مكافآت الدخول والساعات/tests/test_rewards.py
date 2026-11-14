#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tests/test_rewards.py  --  offline logic tests for lua/rz_rewards.lua
Uses lupa (Lua inside Python) with a mocked GameServer environment.
Run:  python3 tests/test_rewards.py
"""

import os
import sys

try:
    import lupa
except ImportError:
    print("FATAL: lupa not installed (pip install lupa)")
    sys.exit(2)

HERE = os.path.dirname(os.path.abspath(__file__))
LUA = os.path.join(HERE, "..", "lua", "rz_rewards.lua")

MOCK = r"""
-- ---------- mock engine ----------
FAKE_NOW   = 1699963200   -- noon of a fixed day (no day rollover during tests)
DUMMY      = {}
GRANTS     = {}
NOTICES    = {}
INFO       = {}
ONLINE     = {}

os = os or {}
os.time = function() return FAKE_NOW end

function get_global_variable(k)
  local v = DUMMY[k]
  if v == nil then return "" end
  return v
end
function set_global_variable(k, v) DUMMY[k] = v end

function get_value(field, name)
  local r = INFO[name]
  if not r then return nil end
  return r[field]
end

function insert_item(code, qty, e1, e2, flag, target)
  GRANTS[#GRANTS + 1] = { code = code, qty = qty, flag = flag, target = target }
end

function is_online(name)
  if ONLINE[name] == nil then return true end
  return ONLINE[name]
end

function whisper(name, text) NOTICES[#NOTICES + 1] = text end
function message(text) end

function reset_world()
  FAKE_NOW = 1699963200
  DUMMY    = {}
  GRANTS   = {}
  NOTICES  = {}
  INFO     = {}
  ONLINE   = {}
end

function add_char(name, acct, level)
  INFO[name] = { account_id = acct, level = level or 100, name = name }
end

function grant_count() return #GRANTS end
function notice_count() return #NOTICES end
"""

TEST_TABLE = r"""
RZ_TABLE = {
  daily = {
    [1] = { label = "d1", items = { { k = "repair_kit", n = 3 }, { k = "exp10", n = 1 } } },
    [2] = { label = "d2", items = { { k = "potion_hp", n = 20 } } },
    [3] = { label = "d3", items = { { k = "exp20", n = 1 } } },
    [4] = { label = "d4", items = { { k = "drop10", n = 1 } } },
    [5] = { label = "d5", items = { { k = "exp30", n = 2 } } },
    [6] = { label = "d6", items = { { k = "res_scroll", n = 1 } } },
    [7] = { label = "d7", items = { { k = "exp30", n = 3 } } },
  },
  hourly = {
    [1] = { label = "h1", items = { { k = "repair_kit", n = 1 } } },
    [2] = { label = "h2", items = { { k = "potion_hp", n = 10 } } },
    [3] = { label = "h3", items = { { k = "exp10", n = 1 } } },
    [4] = { label = "h4", items = { { k = "teleport_scroll", n = 1 } } },
  },
}
"""

EMPTY_TABLE = "RZ_TABLE = { daily = {}, hourly = {} }"

FIXTURE = """
reset_world()
add_char('Hero', 1, 100)
add_char('Alt',  1, 100)
add_char('Noob', 2, 5)
"""

ITEM_KEYS = ["repair_kit", "potion_hp", "potion_mp", "exp10", "exp20", "exp30",
             "drop10", "teleport_scroll", "res_scroll", "pet_food", "buff_scroll"]

results = []


def check(name, cond, detail=""):
    results.append((name, bool(cond), detail))
    print(("PASS  " if cond else "FAIL  ") + name + (("  -> " + detail) if detail else ""))


def first(r):
    return r[0] if isinstance(r, tuple) else r


def main():
    lua = lupa.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    lua.execute(FIXTURE)
    lua.execute(TEST_TABLE)
    lua.execute(open(LUA, encoding="utf-8").read())

    R = lua.eval("RZ_RW")
    G = lua.globals()
    CFG = lua.eval("RZ_RW.cfg")
    ITEMS = lua.eval("RZ_RW.items")
    DC = lua.eval("RZ_RW.daily_cycle")
    HC = lua.eval("RZ_RW.hour_cycle")

    for i, k in enumerate(ITEM_KEYS, start=1):
        lua.execute(f"RZ_RW.items['{k}'] = {9000 + i}")

    # ---------- 1. day id math ----------
    d0 = int(R.day_id(0))
    d1 = int(R.day_id(86399))
    d2 = int(R.day_id(86400))
    check("day_id increases once per 86400s", d1 == d0 and d2 == d0 + 1, f"{d0},{d1},{d2}")

    # ---------- 2. first daily claim ----------
    lua.execute(FIXTURE)
    check("first daily claim returns ok", first(R.daily("Hero")) == "ok")
    check("first daily claim grants items", int(G.grant_count()) > 0)

    # ---------- 3. same day ----------
    before = int(G.grant_count())
    check("same-day second claim blocked", first(R.daily("Hero")) == "already")
    check("same-day second claim grants nothing", int(G.grant_count()) == before)

    # ---------- 4. streak increments ----------
    lua.execute("FAKE_NOW = FAKE_NOW + 86400")
    R.daily("Hero")
    check("streak becomes 2 on the next day",
          int(R.sget(R.scope("Hero") + ".streak")) == 2)

    # ---------- 5. streak resets after a gap ----------
    lua.execute("FAKE_NOW = FAKE_NOW + 86400 * 3")
    R.daily("Hero")
    check("streak resets to 1 after missing a day",
          int(R.sget(R.scope("Hero") + ".streak")) == 1)

    # ---------- 6. streak cycles ----------
    lua.execute(FIXTURE)
    for _ in range(7):                      # 7 consecutive claims -> streak 7
        R.daily("Hero")
        lua.execute("FAKE_NOW = FAKE_NOW + 86400")
    R.daily("Hero")                          # 8th claim starts a new cycle
    check("streak cycles back to 1 after 7",
          int(R.sget(R.scope("Hero") + ".streak")) == 1)

    # ---------- 7. hourly needs a full window ----------
    lua.execute(FIXTURE)
    R.on_login("Hero")
    check("hourly blocked right after login", first(R.hourly("Hero")) == "wait")

    # ---------- 8. hourly after the window ----------
    lua.execute("FAKE_NOW = FAKE_NOW + 3600")
    r = R.hourly("Hero")
    check("hourly granted after 3600s online", first(r) == "ok", str(r))
    check("hourly grant delivered items", len(r) > 2 and int(r[2]) > 0, str(r))

    # ---------- 9. per-day cap ----------
    for _ in range(3):                      # fills grants #2 #3 #4
        lua.execute("FAKE_NOW = FAKE_NOW + 3600")
        R.hourly("Hero")
    lua.execute("FAKE_NOW = FAKE_NOW + 3600")
    check("hourly cap of 4/day enforced", first(R.hourly("Hero")) == "cap")

    # ---------- 10. resets next day ----------
    lua.execute("FAKE_NOW = FAKE_NOW + 86400")
    check("hourly counter resets on a new day", first(R.hourly("Hero")) == "ok")

    # ---------- 11. kill switch ----------
    lua.execute(FIXTURE)
    CFG.enabled = False
    before = int(G.grant_count())
    check("disabled -> daily does nothing", first(R.daily("Hero")) == "disabled")
    check("disabled -> hourly does nothing", first(R.hourly("Hero")) == "disabled")
    check("disabled -> no items granted", int(G.grant_count()) == before)
    CFG.enabled = True

    # ---------- 12. min level ----------
    lua.execute(FIXTURE)
    R.on_login("Noob")
    lua.execute("FAKE_NOW = FAKE_NOW + 7200")
    check("low level blocked from hourly", first(R.hourly("Noob")) == "low_level")

    # ---------- 13. per-account sharing ----------
    lua.execute(FIXTURE)
    R.on_login("Hero")
    for _ in range(4):                      # exhaust the 4 hourly grants
        lua.execute("FAKE_NOW = FAKE_NOW + 3600")
        R.hourly("Hero")
    R.on_login("Alt")
    lua.execute("FAKE_NOW = FAKE_NOW + 3600")
    check("alt on the same account shares the cap", first(R.hourly("Alt")) == "cap")

    # ---------- 14. offline refused ----------
    lua.execute(FIXTURE)
    lua.execute("ONLINE['Hero'] = false")
    check("offline character cannot claim hourly", first(R.hourly("Hero")) == "offline")
    check("offline character cannot claim daily", first(R.daily("Hero")) == "offline")
    lua.execute("ONLINE['Hero'] = true")

    # ---------- 15. bind flag applied ----------
    lua.execute(FIXTURE)
    R.on_login("Hero")
    lua.execute("FAKE_NOW = FAKE_NOW + 3600")
    R.hourly("Hero")
    flags = sorted({int(g.flag) for g in G.GRANTS.values()})
    check("every insert_item call carries the bind flag 515", flags == [515], str(flags))

    # ---------- 16. no economy-breaking entries ----------
    bad = [k for k in ITEMS.keys()
           if any(w in str(k).lower() for w in ("gold", "coin", "stone", "weapon", "armor"))]
    check("no gold/coin/stone/gear keys in reward items", not bad, str(bad))

    # ---------- 17. bundle keys exist ----------
    missing = set()
    for cyc in (DC, HC):
        for i in cyc.keys():
            for it in cyc[i]["items"].values():
                if str(it["k"]) not in ITEMS.keys():
                    missing.add(str(it["k"]))
    check("all bundle item keys are configured", not missing, str(missing))

    # ---------- 18. cycle lengths ----------
    check("daily cycle has 7 entries", len(list(DC.keys())) == 7, str(len(list(DC.keys()))))
    check("hour cycle has 4 entries", len(list(HC.keys())) == 4, str(len(list(HC.keys()))))

    # ---------- 19. tick drops offline sessions ----------
    lua.execute(FIXTURE)
    lua.execute("RZ_RW.sessions = {}")
    R.on_login("Hero")
    R.on_login("Noob")
    lua.execute("ONLINE['Hero'] = false")
    lua.execute("FAKE_NOW = FAKE_NOW + 3600")
    R.tick()
    sess = lua.eval("RZ_RW.sessions")
    check("tick drops the offline session", "Hero" not in sess.keys())
    check("tick keeps the online session", "Noob" in sess.keys())

    # ---------- 20. notices ----------
    lua.execute(FIXTURE)
    R.on_login("Hero")
    check("players get a notification on grant", int(G.notice_count()) > 0)

    # ---------- 21. unset item codes: warn, never crash ----------
    lua.execute(FIXTURE)
    for k in ITEM_KEYS:
        lua.execute(f"RZ_RW.items['{k}'] = 0")
    check("unset item codes do not crash", first(R.daily("Hero")) == "ok")
    check("unset item codes are reported",
          len(list(R.unset_items().keys())) == len(ITEM_KEYS))
    for i, k in enumerate(ITEM_KEYS, start=1):
        lua.execute(f"RZ_RW.items['{k}'] = {9000 + i}")

    # ---------- 22. supplied table validates clean ----------
    probs = R.validate()
    check("owner-supplied table validates with 0 problems", len(list(probs.keys())) == 0,
          str(list(probs.values())[:3] if hasattr(probs, "values") else probs))

    # ---------- 23. empty table grants nothing ----------
    lua.execute(FIXTURE)
    lua.execute("RZ_RW.daily_cycle = {} ; RZ_RW.hour_cycle = {}")
    before = int(G.grant_count())
    check("empty table -> daily returns no_rewards", first(R.daily("Hero")) == "no_rewards")
    check("empty table -> hourly returns no_rewards", first(R.hourly("Hero")) == "no_rewards")
    check("empty table -> nothing granted", int(G.grant_count()) == before)
    check("empty table -> day is NOT consumed",
          R.sget(R.scope("Hero") + ".last_daily") is None)

    # ---------- 24. bad rows are reported, not fatal ----------
    lua.execute("""RZ_RW.daily_cycle = {
        [1] = { label = "bad1", items = { { k = "not_an_item", n = 1 } } },
        [2] = { label = "bad2", items = { { k = "repair_kit", n = 0 } } },
        [3] = { label = "bad3" },
    }""")
    probs = list(R.validate().values())
    joined = " | ".join(str(x) for x in probs)
    check("unknown item key is reported", "unknown item key" in joined, joined[:120])
    check("bad quantity is reported", "quantity must be" in joined, joined[:120])
    check("bundle without items is reported", "missing items list" in joined, joined[:120])
    st_bad = first(R.daily("Hero"))
    check("daily still runs with a bad row (skips it)", st_bad in ("ok", "nocycle", "already"), str(st_bad))

    # ---------- summary ----------
    passed = sum(1 for _, ok, _ in results if ok)
    total = len(results)
    print("\n" + "=" * 52)
    if passed == total:
        print(f"ALL PASSED  ({passed}/{total})")
        return 0
    print(f"FAILED {total - passed} of {total}")
    for n, ok, d in results:
        if not ok:
            print("  - " + n + ("  -> " + d if d else ""))
    return 1


if __name__ == "__main__":
    sys.exit(main())
