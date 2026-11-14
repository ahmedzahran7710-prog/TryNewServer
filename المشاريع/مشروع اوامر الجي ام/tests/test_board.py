import sys
from lupa import LuaRuntime

import os
HERE = os.path.dirname(os.path.abspath(__file__))
BOARD = open(os.path.join(HERE, '..', 'lua', 'NPC_GM_Board.lua'), encoding='utf-8').read()
fails = []


def make(mocks=True):
    L = LuaRuntime(unpack_returned_tuples=True)
    out = {'dlg': [], 'calls': []}
    g = L.globals()

    if mocks:
        L.execute("""
        function dlg_title(t) LOG_T = t end
        function dlg_text(t) LOG_X = t end
        function dlg_menu(l, cb) MENU = MENU or {} ; table.insert(MENU, {l, cb}) end
        function dlg_show() SHOWN = true end
        function get_name() return "OwnerZahran" end
        function get_level() return 100 end
        function insert_gold(n) GOLD_ADDED = (GOLD_ADDED or 0) + n ; logd("insert_gold "..n) end
        function set_value(k, v) SETV = k .. "=" .. tostring(v) ; logd("set_value "..SETV) end
        function set_level(n) LEVEL = n ; logd("set_level "..n) end
        function add_exp_jp(e, j) logd("add_exp_jp "..e.." "..j) end
        function add_state(c, l, ms) logd("add_state "..c.." "..l.." "..ms) end
        function SCRIPT_BroadcastNotice(t) NOTICE = t ; logd("notice "..t) end
        function insert_item(c, n) logd("insert_item "..c.."x"..n) end
        function heal() logd("heal") end
        CALLS = {}
        function logd(s) table.insert(CALLS, s) end
        """)

    L.execute(BOARD)
    return L, g


def check(name, cond):
    print(("  OK   " if cond else "  FAIL ") + name)
    if not cond:
        fails.append(name)


print("== scenario 1: full engine mock ==")
for L, g in [make(True)]:
    g.gm_open()
    menu = g.MENU
    check("main menu rendered", menu is not None and len(menu) == 6)
    g.MENU = None
    L.execute("MENU = nil")
    g.gm_t_self()
    check("actions menu has 8 entries", len(g.MENU) == 8)
    L.execute("MENU = nil")
    g.gm_do_gold()
    check("gold menu has 4 amounts + back", len(g.MENU) == 5)
    g.MENU = None
    g.gm_amt3()
    check("insert_gold 100000 called", 'insert_gold 100000' in list(g.CALLS.values()))
    check("no announce while GM.announce is off", g.NOTICE is None)
    g.GM.announce = True
    g.gm_amt3()
    check("notice names the player when announce is on", 'OwnerZahran' in str(g.NOTICE))
    g.GM.announce = False
    g.MENU = None
    g.gm_t_self()
    g.gm_do_level()
    g.MENU = None
    g.gm_lvl2()
    check("set_level 110 (add 10 to 100)", g.LEVEL == 110)
    g.MENU = None
    g.gm_report()
    check("report shows OK for set_value", 'OK' in str(g.LOG_X))

print("== scenario 2: no engine functions at all ==")
L2 = LuaRuntime(unpack_returned_tuples=True)
g2 = L2.globals()
L2.execute(BOARD)
try:
    g2.gm_open()
    ok2 = True
except Exception as e:
    ok2 = False
    print("    error:", e)
check("gm_open survives without any engine api", ok2)
rep = g2.GM.report_lines()
missing = [rep[i] for i in range(1, len(rep) + 1) if 'MISSING' in rep[i]]
check("report marks everything MISSING", len(missing) >= 15)

print("== scenario 3: hook install ==")
L3 = LuaRuntime(unpack_returned_tuples=True)
g3 = L3.globals()
L3.execute("""
function dlg_title(t) end function dlg_text(t) end
function dlg_menu(l, cb) end function dlg_show() end
function get_name() return "OwnerZahran" end
function NPC_test_contact() ORIG = true end
""")
L3.execute(BOARD)
res = g3.GM.install_hook("NPC_test_contact")
check("hook returns true", res is True)
g3.NPC_test_contact()
check("gm path taken (not original)", g3.ORIG is None)

L4 = LuaRuntime(unpack_returned_tuples=True)
g4 = L4.globals()
L4.execute("""
function dlg_title(t) end function dlg_text(t) end
function dlg_menu(l, cb) end function dlg_show() end
function get_name() return "SomeNormalPlayer" end
function NPC_test_contact() ORIG = true end
""")
L4.execute(BOARD)
g4.GM.install_hook("NPC_test_contact")
g4.NPC_test_contact()
check("normal player still gets original npc", g4.ORIG is True)

print()
if fails:
    print("FAILED:", fails)
    sys.exit(1)
print("ALL LUA TESTS PASSED")
