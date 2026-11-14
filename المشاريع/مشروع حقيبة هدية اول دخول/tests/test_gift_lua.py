import os
from lupa import LuaRuntime

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = open(os.path.join(HERE, '..', 'lua', 'rz_gift_box.lua'), encoding='utf-8').read()
fails = []


def check(name, cond):
    print(("  OK   " if cond else "  FAIL ") + name)
    if not cond:
        fails.append(name)


def build(configured=True):
    L = LuaRuntime(unpack_returned_tuples=True)
    g = L.globals()
    L.execute("""
      GIVEN, REMOVED, NOTICE = {}, {}, nil
      function insert_item(code, qty, a, b, c)
          table.insert(GIVEN, tostring(code).."x"..tostring(qty))
      end
      function delete_item(id, qty) table.insert(REMOVED, tostring(id)) end
      function get_name() return "OwnerZahran" end
      function SCRIPT_BroadcastNotice(t) NOTICE = t end
    """)
    L.execute(SRC)
    if configured:
        L.execute("""
          RZ_GIFT.buff_items   = { {2001,1,"anais"} }
          RZ_GIFT.energy_items = { {3001,1,"energy"} }
          RZ_GIFT.consumables  = { {4001,20,"stab"}, {4002,5,"stab-deluxe"},
                                   {4003,20,"exp"},  {4004,5,"exp-legend"} }
          RZ_GIFT.bags = {
            [97000001] = { label="Fighter",  items={ {1001,1,"fighter armor"}, {1011,1,"fighter weapon"} } },
            [97000003] = { label="Magician", items={ {1003,1,"magician armor"}, {1013,1,"magician weapon"} } },
          }
        """)
    return g


print("== module registration ==")
g = build()
check("get_module_name -> rz_gift_open", str(g.get_module_name()) == "rz_gift_open")
check("rz_gift_open exists", g.rz_gift_open is not None)

print("== class bag: fighter ==")
g = build()
res = g.rz_gift_open(97000001)
given = list(g.GIVEN.values())
check("returns true", res is True)
check("2 class items + 1 buff + 1 energy + 4 consumables = 8", len(given) == 8)
check("fighter weapon present", any(x.startswith("1011") for x in given))
check("NO magician item", not any(x.startswith("1013") for x in given))
check("quantities kept", any(x.endswith("x20") for x in given) and any(x.endswith("x5") for x in given))
check("bag removed", "97000001" in list(g.REMOVED.values()))
check("no announcement (announce=false)", g.NOTICE is None)

print("== class bag: magician ==")
g = build()
g.rz_gift_open(97000003)
given = list(g.GIVEN.values())
check("magician weapon present", any(x.startswith("1013") for x in given))
check("no fighter item", not any(x.startswith("1011") for x in given))

print("== unknown bag is refused ==")
g = build()
res = g.rz_gift_open(11111111)
check("returns false", res is False)
check("nothing granted", len(list(g.GIVEN.values())) == 0)

print("== unconfigured build does not crash ==")
g = build(configured=False)
res = g.rz_gift_open(12345)
check("returns true", res is True)
check("nothing granted", len(list(g.GIVEN.values())) == 0)

print("== no engine api at all ==")
L = LuaRuntime(unpack_returned_tuples=True)
try:
    L.execute(SRC)
    L.execute("rz_gift_open(5)")
    ok = True
except Exception as e:
    ok = False
    print("   error:", e)
check("survives a build with no engine api", ok)

print()
if fails:
    print("FAILED:", fails)
    raise SystemExit(1)
print("ALL GIFT LUA TESTS PASSED")
