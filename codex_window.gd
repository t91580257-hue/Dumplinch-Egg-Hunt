extends "res://scripts/ui/window_base.gd"
## Достижения, коллекция яиц и коллекция боссов (вкладки).

var tab = "ach"


func _init():
    super("Коллекции и достижения")


func _set_tab(t):
    tab = t
    refresh_all()


func build(box):
    var tabs = UIF.row(box)
    for t in [["ach", "Достижения"], ["eggs", "Коллекция яиц"], ["bosses", "Коллекция боссов"]]:
        var b = UIF.button(t[1], Vector2(0, 56), 20)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.disabled = tab == t[0]
        b.pressed.connect(_set_tab.bind(t[0]))
        tabs.add_child(b)
    match tab:
        "ach": _ach(box)
        "eggs": _eggs(box)
        "bosses": _bosses(box)


func _ach(box):
    box.add_child(UIF.label("Титул: " + GameState.current_title(), 28, Color("ffd24a")))
    for q in GameData.ACHIEVEMENTS:
        var done = GameState.claimed.has(q.id)
        var v = UIF.card(box, Color(0.1, 0.25, 0.15, 0.9) if done else Color(0.12, 0.15, 0.3, 0.9))
        v.add_child(UIF.label(q.title + ("  (получено)" if done else ""), 22, Color("9fe8a0") if done else Color.WHITE, true))
        var cur = mini(GameState.stat_value(q.key), int(q.target))
        var b = UIF.bar(Color("ffb62e"), 16, 200)
        b.max_value = int(q.target)
        b.value = cur
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        v.add_child(b)
        v.add_child(UIF.label("%d / %d     Награда: %s" % [cur, int(q.target), GameData.reward_text(q.reward)], 17, Color(0.8, 0.85, 1.0), true))
    box.add_child(UIF.label("Все титулы", 24, Color("ffd24a")))
    for t in GameData.TITLES:
        var ok = GameState.stat_value(t.key) >= t.target
        box.add_child(UIF.label(("[x] " if ok else "[ ] ") + t.name, 20, Color("9fe8a0") if ok else Color(0.7, 0.7, 0.8)))


func _eggs(box):
    box.add_child(UIF.label("Найдено питомцев: %d / %d" % [GameState.discovered.size(), GameData.PETS.size()], 26, Color("ffd24a")))
    for egg in GameData.EGGS:
        var v = UIF.card(box)
        v.add_child(UIF.label("%s  (%s)" % [egg.name, UIF.cost_text(egg.cur, egg.price)], 24, egg.color.lightened(0.35)))
        for c in GameState.egg_chances(egg.id):
            var p = c[0]
            var known = GameState.discovered.has(p.id)
            var txt = "%s - %s, шанс %d%%" % [p.name, GameData.rarity_name(p.rarity), int(round(c[1]))] if known else "??? - шанс %d%%" % int(round(c[1]))
            v.add_child(UIF.label(txt, 19, GameData.rarity_color(p.rarity).lightened(0.2) if known else Color(0.6, 0.6, 0.7)))


func _bosses(box):
    box.add_child(UIF.label("Побеждено боссов: %d / %d" % [GameState.defeated_bosses.size(), GameData.BOSSES.size()], 26, Color("ffd24a")))
    for b in GameData.BOSSES:
        var done = GameState.defeated_bosses.has(b.id)
        var v = UIF.card(box, Color(0.1, 0.25, 0.15, 0.9) if done else Color(0.12, 0.15, 0.3, 0.9))
        v.add_child(UIF.label(b.name + ("  (побеждён)" if done else ""), 24, b.color.lightened(0.4)))
        v.add_child(UIF.label("Регион: %s | Здоровье: %d | Урон: %d" % [GameData.REGIONS[b.region].name, b.hp, b.dmg], 18, Color(0.8, 0.85, 1.0), true))
        v.add_child(UIF.label("Награда: %d монет, %d самоцв., %d кристаллов, %s" % [b.coins, b.gems, b.crystals, GameData.egg(b.egg).name], 18, Color(0.8, 0.85, 1.0), true))
