import os
from lupa import LuaRuntime

HERE = os.path.dirname(os.path.abspath(__file__))
BOARD = open(os.path.join(HERE, '..', 'lua', 'NPC_GM_Board.lua'), encoding='utf-8').read()
fails = []


def make(mocks=True):
    L = LuaRuntime(unpack_returned_tuples=True)
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
        function add_state(c, l, ms, name)
            if name then logd("add_state "..c.." "..l.." "..ms.." -> "..name)
            else logd("add_state "..c.." "..l.." "..ms) end
        end
        function set_env(k, v) logd("set_env "..k.."="..v) end
        function add_event_state(c, l) logd("add_event_state "..c.." "..l) end
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


def menu_labels(g):
    if g.MENU is None:
        return []
    return [str(item[1]) for item in g.MENU.values()]


print("== scenario 1: full engine mock ==")
for L, g in [make(True)]:
    # main menu: 6 tabbed entries
    g.gm_open()
    labels = menu_labels(g)
    check("main menu has 6 tabs", len(labels) == 6)
    check("main has buff tab (Arabic)", any("البفات" in s for s in labels))
    check("main has world buff tab", any("جماعي" in s for s in labels))
    check("main has target tab", any("استهداف" in s for s in labels))

    # target menu
    g.MENU = None
    L.execute("MENU = nil")
    g.gm_target_menu()
    labels = menu_labels(g)
    check("target menu: self first", labels and "نفسي" in labels[0])
    check("target menu lists players", any("Admin" in s for s in labels))

    # pick named target
    g.gm_tgt2()  # Admin
    check("target set to Admin", str(g.GM.target) == "Admin")

    # buff menu shows Arabic names with code + power
    g.MENU = None
    L.execute("MENU = nil")
    g.gm_buff_menu()
    labels = menu_labels(g)
    check("buff page1 has 6 buffs", len([s for s in labels if s.startswith('[')]) == 6)
    check("buff label has Arabic name", any("زيادة قوة الهجوم" in s for s in labels))
    check("buff label has power +150", any("+150" in s for s in labels))
    check("buff menu has duration line", any("المدة" in s for s in labels))

    # pagination -> page 2 (buffs 7..12)
    g.MENU = None
    L.execute("MENU = nil")
    g.gm_buff_next()
    labels = menu_labels(g)
    check("page 2 shows more buffs", len([s for s in labels if s.startswith('[')]) == 6)
    check("page 2 has prev nav", any("السابق" in s for s in labels))

    # apply buff to NAMED target (4th arg)
    L.execute("CALLS = nil ; CALLS = {}")
    g.GM.target = "Admin"
    g.GM.duration_idx = 2  # 1 hour
    g.gm_buf1()
    calls = [str(x) for x in g.CALLS.values()]
    check("buff to name: add_state 4th arg = Admin",
          any(c.startswith("add_state 1007 150 3600000 -> Admin") for c in calls))
    check("gift message names the target", "Admin" in str(g.LOG_X))

    # apply buff to self (3 args)
    L.execute("CALLS = nil ; CALLS = {}")
    g.GM.target = "self"
    g.gm_buf1()
    calls = [str(x) for x in g.CALLS.values()]
    check("buff to self: no name arg",
          any(c == "add_state 1007 150 3600000" for c in calls))

    # duration menu
    g.MENU = None
    L.execute("MENU = nil")
    g.gm_dur_menu()
    labels = menu_labels(g)
    check("duration menu has 4 options + back", len(labels) == 5)
    g.gm_dur3()
    check("duration set to idx 3", int(g.GM.duration_idx) == 3)

    # world menu: rates + world buffs
    g.MENU = None
    L.execute("MENU = nil")
    g.gm_world_menu()
    labels = menu_labels(g)
    check("world menu: 3 rates + 3 buffs + back", len(labels) == 7)
    check("world rate Arabic exp", any("خبرة x300" in s for s in labels))
    check("world buff Arabic", any("هجوم للكل" in s for s in labels))

    # rate via set_env
    L.execute("CALLS = nil ; CALLS = {}")
    g.gm_rate1()
    calls = [str(x) for x in g.CALLS.values()]
    check("rate calls set_env", any("set_env game.exp_rate=300" in c for c in calls))

    # world state buff via add_event_state
    L.execute("CALLS = nil ; CALLS = {}")
    g.gm_wbuf2()
    calls = [str(x) for x in g.CALLS.values()]
    check("world buff calls add_event_state", any("add_event_state 1007 150" in c for c in calls))

    # gifts tab
    g.MENU = None
    L.execute("MENU = nil")
    g.gm_gift_menu()
    labels = menu_labels(g)
    check("gift menu has 5 types + back", len(labels) == 6)

    # gold still works on self
    L.execute("CALLS = nil ; CALLS = {}")
    g.GM.target = "self"
    g.gm_gold_menu()
    g.gm_amt3()
    calls = [str(x) for x in g.CALLS.values()]
    check("gold 100000 on self", any("insert_gold 100000" in c for c in calls))

    # gold blocked for other target
    g.GM.target = "Admin"
    g.gm_amt3()
    check("gold to other player shows guidance",
          "GM-Tool" in str(g.LOG_X) or "غير مدعوم" in str(g.LOG_X) or "نفسك" in str(g.LOG_X))

    # report (full list lives in GM.report_lines, dialog shows first 12)
    g.MENU = None
    L.execute("MENU = nil")
    g.gm_report()
    lines = [str(x) for x in g.GM.report_lines().values()]
    check("report shows OK for set_env",
          any("OK" in s and "set_env" in s for s in lines))
    check("report counts world fns",
          any("add_event_state" in s for s in lines))
    check("dialog report truncated but present", "RZ-GM Report" in str(g.LOG_T))

print("== scenario 2: no engine functions at all ==")
L2 = LuaRuntime(unpack_returned_tuples=True)
g2 = L2.globals()
L2.execute(BOARD)
try:
    g2.gm_open()
    check("opens without engine (gate deny or empty)", True)
except Exception as e:
    check("opens without engine (gate deny or empty)", False)
    print("   error:", e)

try:
    g2.gm_main()
    check("main renders without engine", True)
except Exception as e:
    check("main renders without engine", False)
    print("   error:", e)

print("== scenario 3: gate ==")
L3 = LuaRuntime(unpack_returned_tuples=True)
g3 = L3.globals()
L3.execute("""
function get_name() return "RandomPlayer" end
function dlg_title(t) end
function dlg_text(t) LOG_X = t end
function dlg_menu(l, cb) end
function dlg_show() end
""")
L3.execute(BOARD)
g3.gm_open()
check("non-GM sees restricted message", "جي ام" in str(g3.LOG_X) or "GM" in str(g3.LOG_X))

print()
if fails:
    print("FAILED %d: %s" % (len(fails), fails))
    raise SystemExit(1)
print("ALL TESTS PASSED")
