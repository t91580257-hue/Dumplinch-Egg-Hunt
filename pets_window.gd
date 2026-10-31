extends "res://scripts/ui/window_base.gd"
## Питомцы: сортировка, фильтры, экипировка, избранное, уровни, объединение, эволюция.

var sort_mode = 0
var filter_r = -1
var selected = -1


func _init():
    super("Питомцы")


func _set_sort(i):
    sort_mode = i
    refresh_all.call_deferred()


func _set_filter(i):
    filter_r = i - 1
    refresh_all.call_deferred()


func _select(uid):
    selected = uid
    refresh_all()


func _cmp(a, b):
    if a.fav != b.fav:
        return a.fav
    var da = GameData.pet(a.id)
    var db = GameData.pet(b.id)
    match sort_mode:
        1:
            if da.rarity != db.rarity:
                return da.rarity > db.rarity
        2:
            if a.level != b.level:
                return a.level > b.level
    return GameState.pet_power(a) > GameState.pet_power(b)


func build(box):
    box.add_child(UIF.label("Экипировано: %d / %d     Всего: %d" % [GameState.equipped_pets().size(), GameState.pet_slots, GameState.pets.size()], 22, Color("ffd24a")))
    var sel = GameState.get_pet(selected)
    if sel != null:
        _detail(box, sel)
    var r = UIF.row(box)
    r.add_child(UIF.label("Сортировка:", 20))
    var ob = OptionButton.new()
    ob.custom_minimum_size = Vector2(190, 50)
    for t in ["По силе", "По редкости", "По уровню"]:
        ob.add_item(t)
    ob.select(sort_mode)
    ob.item_selected.connect(_set_sort)
    r.add_child(ob)
    r.add_child(UIF.label("Фильтр:", 20))
    var of = OptionButton.new()
    of.custom_minimum_size = Vector2(220, 50)
    of.add_item("Все")
    for rr in GameData.RARITIES:
        of.add_item(rr.name)
    of.select(filter_r + 1)
    of.item_selected.connect(_set_filter)
    r.add_child(of)
    var list = GameState.pets.filter(func(p): return filter_r < 0 or GameData.pet(p.id).rarity == filter_r)
    list.sort_custom(_cmp)
    if list.is_empty():
        box.add_child(UIF.label("Питомцев нет. Откройте яйцо!", 22, Color(0.8, 0.85, 1.0)))
        return
    var grid = GridContainer.new()
    grid.columns = 3
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 8)
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_child(grid)
    for p in list:
        var d = GameData.pet(p.id)
        var b = Button.new()
        b.focus_mode = Control.FOCUS_NONE
        b.custom_minimum_size = Vector2(0, 112)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.text = "%s\nур.%d  сила %d%s%s" % [GameState.pet_title(p), p.level, int(GameState.pet_power(p)), "  [Э]" if p.equipped else "", "  [И]" if p.fav else ""]
        b.add_theme_font_size_override("font_size", 18)
        b.add_theme_color_override("font_color", GameData.rarity_color(d.rarity).lightened(0.2))
        var border = Color("4ad66d") if p.equipped else (Color("ffd24a") if p.uid == selected else Color("6f8cff"))
        b.add_theme_stylebox_override("normal", UIF.style(Color("2b3766"), 14, border, 3))
        b.pressed.connect(_select.bind(p.uid))
        grid.add_child(b)


func _detail(box, p):
    var d = GameData.pet(p.id)
    var rc = GameData.rarity_color(d.rarity)
    var v = UIF.card(box, Color(0.16, 0.2, 0.42, 0.97))
    v.add_child(UIF.label(GameState.pet_title(p), 28, rc.lightened(0.2)))
    v.add_child(UIF.label("%s | сила %d | %s" % [GameData.rarity_name(d.rarity), int(GameState.pet_power(p)), GameData.ability_text(d.ability, d.rarity)], 20, Color.WHITE, true))
    v.add_child(UIF.label("Уровень %d/25   Звёзды %d/5   Форма %d/2" % [p.level, p.stars, p.form], 20))
    var r = UIF.row(v)
    var be = UIF.button("Снять" if p.equipped else "Экипировать", Vector2(0, 56), 20)
    be.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    be.pressed.connect(_act.bind("equip", p.uid))
    r.add_child(be)
    var bf = UIF.button("Убрать из избранного" if p.fav else "В избранное", Vector2(0, 56), 20)
    bf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bf.pressed.connect(_act.bind("fav", p.uid))
    r.add_child(bf)
    var r2 = UIF.row(v)
    var cost = GameState.pet_level_cost(p)
    var bl = UIF.button("Улучшить (%d монет)" % cost, Vector2(0, 56), 20)
    bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bl.disabled = p.level >= 25 or GameState.coins < cost
    bl.pressed.connect(_act.bind("level", p.uid))
    r2.add_child(bl)
    var cands = GameState.merge_candidates(p).size()
    var bm = UIF.button("Объединить 3 (%d/2 копий)" % mini(cands, 2), Vector2(0, 56), 20)
    bm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bm.disabled = cands < 2 or p.stars >= 5
    bm.pressed.connect(_act.bind("merge", p.uid))
    r2.add_child(bm)
    var be2 = UIF.button("Эволюция (%d самоцв., нужен ур.%d)" % [GameState.evolve_cost(p), 8 * (p.form + 1)], Vector2(0, 56), 20)
    be2.disabled = not GameState.can_evolve(p) or GameState.gems < GameState.evolve_cost(p)
    be2.pressed.connect(_act.bind("evolve", p.uid))
    v.add_child(be2)


func _act(what, uid):
    match what:
        "equip": GameState.toggle_equip(uid)
        "fav": GameState.toggle_fav(uid)
        "level": GameState.level_up_pet(uid)
        "merge":
            if GameState.merge_pet(uid):
                AudioManager.play_ui("reward")
        "evolve":
            if GameState.evolve_pet(uid):
                AudioManager.play_ui("reward")
    refresh_all()
