extends "res://scripts/ui/window_base.gd"
## Магазин: яйца, усиления героя, слоты питомцев, ускорители, косметика.

var tab = "eggs"


func _init():
    super("Магазин")


func _set_tab(t):
    tab = t
    refresh_all()


func build(box):
    box.add_child(UIF.currency_bar())
    var tabs = UIF.row(box)
    for t in [["eggs", "Яйца"], ["hero", "Герой"], ["pets", "Слоты"], ["boost", "Ускорители"], ["cosm", "Шапки"]]:
        var b = UIF.button(t[1], Vector2(0, 56), 20)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.disabled = (tab == t[0])
        b.pressed.connect(_set_tab.bind(t[0]))
        tabs.add_child(b)
    match tab:
        "eggs": _eggs(box)
        "hero": _hero(box)
        "pets": _slots(box)
        "boost": _boost(box)
        "cosm": _cosm(box)


func _fail():
    AudioManager.play_ui("error")
    GameState.message.emit("Недостаточно средств")


func _ok():
    AudioManager.play_ui("coin")
    refresh_all()


func _eggs(box):
    for egg in GameData.EGGS:
        var v = UIF.card(box)
        v.add_child(UIF.label(egg.name, 26, egg.color.lightened(0.35)))
        var info = []
        for c in GameState.egg_chances(egg.id):
            info.append("%s %d%% (%s)" % [c[0].name, int(round(c[1])), GameData.rarity_name(c[0].rarity)])
        v.add_child(UIF.label("; ".join(info), 18, Color(0.8, 0.85, 1.0), true))
        var r = UIF.row(v)
        var b1 = UIF.button("Купить x1 - " + UIF.cost_text(egg.cur, egg.price), Vector2(0, 54), 19)
        b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b1.pressed.connect(_buy_egg.bind(egg.id, 1))
        r.add_child(b1)
        var p10 = int(egg.price * 9)
        var b2 = UIF.button("x10 (-10%) - " + UIF.cost_text(egg.cur, p10), Vector2(0, 54), 19)
        b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b2.pressed.connect(_buy_egg.bind(egg.id, 10))
        r.add_child(b2)
    var ev = UIF.card(box, Color(0.3, 0.14, 0.3, 0.95))
    ev.add_child(UIF.label("Событие: Радужное яйцо за жетоны", 24, Color("ff9ed0")))
    var be = UIF.button("Обменять 8 жетонов на Радужное яйцо", Vector2(0, 56), 20)
    be.pressed.connect(_buy_event_egg)
    ev.add_child(be)


func _buy_egg(id, n):
    var egg = GameData.egg(id)
    var price = egg.price * n
    if n == 10:
        price = int(egg.price * 9)
    if GameState.spend(egg.cur, price):
        GameState.add_egg(id, n)
        GameState.message.emit("Куплено: %s x%d" % [egg.name, n])
        _ok()
    else:
        _fail()


func _buy_event_egg():
    if GameState.spend("tokens", 8):
        GameState.add_egg("rainbow", 1)
        _ok()
    else:
        _fail()


func _hero(box):
    for u in GameData.UPGRADES:
        var lvl = GameState.upgrades.get(u.key, 0)
        var v = UIF.card(box)
        v.add_child(UIF.label("%s  (ур. %d/%d)" % [u.name, lvl, u.max], 24, Color("ffd24a")))
        v.add_child(UIF.label(u.desc, 18, Color(0.8, 0.85, 1.0)))
        var cost = GameState.upgrade_cost(u)
        var b = UIF.button("Улучшить - " + UIF.cost_text(u.cur, cost), Vector2(0, 54), 20)
        b.disabled = lvl >= u.max
        b.pressed.connect(_buy_upgrade.bind(u.key))
        v.add_child(b)
    var v2 = UIF.card(box)
    v2.add_child(UIF.label("Зелье здоровья", 24, Color("ff8a9a")))
    var bh = UIF.button("Полностью восстановить здоровье - 80 монет", Vector2(0, 54), 20)
    bh.pressed.connect(_buy_potion)
    v2.add_child(bh)


func _buy_upgrade(key):
    if GameState.buy_upgrade(key):
        _ok()
    else:
        _fail()


func _buy_potion():
    if GameState.spend("coins", 80):
        GameState.heal(9999)
        _ok()
    else:
        _fail()


func _slots(box):
    var v = UIF.card(box)
    v.add_child(UIF.label("Слоты питомцев: %d / 8" % GameState.pet_slots, 26, Color("ffd24a")))
    var cost = 10 * (GameState.pet_slots - 2)
    var b = UIF.button("Купить слот - %d самоцв." % cost, Vector2(0, 56), 20)
    b.disabled = GameState.pet_slots >= 8
    b.pressed.connect(_buy_slot.bind(cost))
    v.add_child(b)


func _buy_slot(cost):
    if GameState.spend("gems", cost):
        GameState.pet_slots += 1
        GameState.pets_changed.emit()
        _ok()
    else:
        _fail()


func _boost(box):
    for bo in GameData.BOOSTERS:
        var v = UIF.card(box)
        v.add_child(UIF.label(bo.name, 24, Color("ffd24a")))
        var b = UIF.button("Купить - " + UIF.cost_text(bo.cur, bo.price), Vector2(0, 54), 20)
        b.pressed.connect(_buy_booster.bind(bo.key))
        v.add_child(b)


func _buy_booster(key):
    for bo in GameData.BOOSTERS:
        if bo.key == key:
            if GameState.spend(bo.cur, bo.price):
                GameState.boosters[key] = GameState.boosters.get(key, 0.0) + bo.time
                GameState.currency_changed.emit()
                _ok()
            else:
                _fail()


func _cosm(box):
    for key in GameData.COSMETICS:
        var c = GameData.COSMETICS[key]
        var v = UIF.card(box)
        v.add_child(UIF.label(c.name, 24, c.color.lightened(0.3)))
        var owned = GameState.cosmetics_owned.has(key)
        var b = UIF.button("Надета" if GameState.cosmetic == key else ("Надеть" if owned else "Купить - " + UIF.cost_text(c.cur, c.price)), Vector2(0, 54), 20)
        b.disabled = GameState.cosmetic == key
        b.pressed.connect(_cosm_action.bind(key))
        v.add_child(b)


func _cosm_action(key):
    var c = GameData.COSMETICS[key]
    if not GameState.cosmetics_owned.has(key):
        if not GameState.spend(c.cur, c.price):
            _fail()
            return
        GameState.cosmetics_owned.append(key)
    GameState.cosmetic = key
    GameState.settings_changed.emit()
    _ok()
