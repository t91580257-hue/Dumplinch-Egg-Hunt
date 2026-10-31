extends "res://scripts/ui/window_base.gd"
## Инвентарь: яйца (открытие по одному и пачкой), ускорители, косметика.

const Icon = preload("res://scripts/ui/icon.gd")


func _init():
    super("Инвентарь")


func build(box):
    box.add_child(UIF.currency_bar())
    box.add_child(UIF.label("Яйца", 28, Color("ffd24a")))
    var any = false
    for egg in GameData.EGGS:
        var n = GameState.eggs.get(egg.id, 0)
        if n <= 0:
            continue
        any = true
        var v = UIF.card(box)
        var r = UIF.row(v)
        r.add_child(Icon.new("egg", 44))
        var l = UIF.label("%s  x%d" % [egg.name, n], 24, egg.color.lightened(0.35))
        l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        r.add_child(l)
        var b1 = UIF.button("Открыть", Vector2(150, 56))
        b1.pressed.connect(_open_egg.bind(egg.id, 1))
        r.add_child(b1)
        if n >= 2:
            var cnt = mini(n, 10)
            var b2 = UIF.button("Открыть x%d" % cnt, Vector2(190, 56))
            b2.pressed.connect(_open_egg.bind(egg.id, cnt))
            r.add_child(b2)
    if not any:
        box.add_child(UIF.label("Яиц нет. Найдите их в мире (кнопка действия рядом с яйцом) или купите в магазине.", 20, Color(0.8, 0.85, 1.0), true))
    box.add_child(UIF.label("Ускорители", 28, Color("ffd24a")))
    var names = {"coins": "x2 монеты", "xp": "x2 опыт"}
    var any_b = false
    for k in GameState.boosters:
        if GameState.boosters[k] > 0.0:
            any_b = true
            var s = int(GameState.boosters[k])
            box.add_child(UIF.label("%s: осталось %d:%02d" % [names[k], s / 60, s % 60], 22))
    if not any_b:
        box.add_child(UIF.label("Нет активных ускорителей.", 20, Color(0.8, 0.85, 1.0)))
    box.add_child(UIF.label("Шапка героя", 28, Color("ffd24a")))
    var r2 = UIF.row(box)
    for key in GameState.cosmetics_owned:
        if GameData.COSMETICS.has(key):
            var b = UIF.button(GameData.COSMETICS[key].name, Vector2(0, 56), 20)
            b.disabled = (GameState.cosmetic == key)
            b.pressed.connect(_equip_cosmetic.bind(key))
            r2.add_child(b)


func _open_egg(id, n):
    GameState.request_open_egg.emit(id, n)


func _equip_cosmetic(key):
    GameState.cosmetic = key
    GameState.settings_changed.emit()
    refresh_all()
