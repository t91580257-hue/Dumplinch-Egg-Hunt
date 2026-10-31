extends Control
## HUD: здоровье, опыт, валюты, мини-карта, задание, кнопки окон, уведомления, босс-бар.

const UIF = preload("res://scripts/ui/ui_factory.gd")
const Icon = preload("res://scripts/ui/icon.gd")
const MiniMap = preload("res://scripts/ui/minimap.gd")
const TouchControls = preload("res://scripts/ui/touch_controls.gd")
const MainMenu = preload("res://scripts/ui/main_menu.gd")
const InventoryWindow = preload("res://scripts/ui/inventory_window.gd")
const PetsWindow = preload("res://scripts/ui/pets_window.gd")
const ShopWindow = preload("res://scripts/ui/shop_window.gd")
const MapWindow = preload("res://scripts/ui/map_window.gd")
const QuestsWindow = preload("res://scripts/ui/quests_window.gd")
const CodexWindow = preload("res://scripts/ui/codex_window.gd")
const SettingsWindow = preload("res://scripts/ui/settings_window.gd")
const RevealWindow = preload("res://scripts/ui/reveal_window.gd")

signal menu_play(new_game)

var game_layer
var hp_bar
var hp_label
var xp_bar
var lvl_label
var quest_label
var cur_labels = {}
var boss_panel
var boss_name
var boss_bar
var banner
var toast_box
var flash_rect
var prompt_label
var reveal_label
var buttons_row
var minimap
var windows = {}
var reveal_window
var menu
var _rect_t = 0.0


func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    theme = UIF.make_theme()
    set_anchors_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    game_layer = Control.new()
    game_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
    game_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(game_layer)
    game_layer.add_child(TouchControls.new())
    _build_status()
    _build_top_right()
    _build_center()
    flash_rect = ColorRect.new()
    flash_rect.color = Color(1, 1, 1, 0)
    flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
    flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    game_layer.add_child(flash_rect)
    windows = {"inv": InventoryWindow.new(), "pets": PetsWindow.new(), "shop": ShopWindow.new(), "map": MapWindow.new(),
        "quests": QuestsWindow.new(), "codex": CodexWindow.new(), "settings": SettingsWindow.new()}
    for k in windows:
        add_child(windows[k])
    reveal_window = RevealWindow.new()
    add_child(reveal_window)
    menu = MainMenu.new()
    menu.play_pressed.connect(func(n): menu_play.emit(n))
    add_child(menu)
    GameState.currency_changed.connect(refresh)
    GameState.stats_changed.connect(refresh)
    GameState.message.connect(toast)
    GameState.quest_completed.connect(_on_quest_done)
    GameState.boss_bar.connect(_on_boss_bar)
    GameState.region_changed.connect(_on_region)
    GameState.screen_flash.connect(_on_flash)
    GameState.prompt_changed.connect(_on_prompt)
    GameState.player_died.connect(_on_died)
    GameState.reveal_pet.connect(_on_reveal)
    GameState.victory.connect(_on_victory)
    refresh()


func set_in_menu(b):
    menu.visible = b
    game_layer.visible = not b
    if b:
        for k in windows:
            windows[k].close()
        reveal_window.close()


func _build_status():
    var p = PanelContainer.new()
    p.position = Vector2(12, 10)
    game_layer.add_child(p)
    var v = VBoxContainer.new()
    v.add_theme_constant_override("separation", 4)
    p.add_child(v)
    var r = UIF.row(v)
    r.add_child(Icon.new("heart", 30))
    hp_bar = UIF.bar(Color("e8485a"), 28, 250)
    r.add_child(hp_bar)
    hp_label = UIF.label("100/100", 18)
    hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
    hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    hp_bar.add_child(hp_label)
    lvl_label = UIF.label("Ур. 1", 22, Color("ffd24a"))
    v.add_child(lvl_label)
    xp_bar = UIF.bar(Color("4aa8ff"), 14, 280)
    v.add_child(xp_bar)
    quest_label = UIF.label("", 17, Color(0.85, 0.92, 1.0), true)
    quest_label.custom_minimum_size = Vector2(280, 0)
    v.add_child(quest_label)


func _icon_btn(kind, win):
    var b = UIF.icon_button(kind, 68)
    b.pressed.connect(open_window.bind(win))
    buttons_row.add_child(b)


func _build_top_right():
    var v = VBoxContainer.new()
    v.add_theme_constant_override("separation", 6)
    v.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    v.grow_horizontal = Control.GROW_DIRECTION_BEGIN
    v.offset_right = -12
    v.offset_top = 10
    game_layer.add_child(v)
    var cp = PanelContainer.new()
    v.add_child(cp)
    var ch = HBoxContainer.new()
    ch.add_theme_constant_override("separation", 10)
    cp.add_child(ch)
    for c in ["coins", "gems", "crystals", "tokens"]:
        ch.add_child(Icon.new(UIF.CUR_ICONS[c], 28))
        var l = UIF.label("0", 22, Color("ffe9a0"))
        l.custom_minimum_size = Vector2(60, 0)
        ch.add_child(l)
        cur_labels[c] = l
    buttons_row = HBoxContainer.new()
    buttons_row.add_theme_constant_override("separation", 6)
    buttons_row.alignment = BoxContainer.ALIGNMENT_END
    v.add_child(buttons_row)
    _icon_btn("bag", "inv")
    _icon_btn("paw", "pets")
    _icon_btn("shop", "shop")
    _icon_btn("map", "map")
    _icon_btn("scroll", "quests")
    _icon_btn("trophy", "codex")
    _icon_btn("gear", "settings")
    minimap = MiniMap.new(false)
    minimap.size_flags_horizontal = Control.SIZE_SHRINK_END
    minimap.custom_minimum_size = Vector2(190, 190)
    v.add_child(minimap)


func _build_center():
    banner = UIF.label("", 56, Color.WHITE)
    banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
    banner.anchor_left = 0.0
    banner.anchor_right = 1.0
    banner.offset_top = 150
    banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner.add_theme_constant_override("outline_size", 12)
    banner.modulate.a = 0.0
    banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    game_layer.add_child(banner)
    toast_box = VBoxContainer.new()
    toast_box.anchor_left = 0.25
    toast_box.anchor_right = 0.75
    toast_box.offset_top = 90
    toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    game_layer.add_child(toast_box)
    boss_panel = PanelContainer.new()
    boss_panel.anchor_left = 0.25
    boss_panel.anchor_right = 0.75
    boss_panel.offset_top = 8
    boss_panel.visible = false
    game_layer.add_child(boss_panel)
    var bv = VBoxContainer.new()
    boss_panel.add_child(bv)
    boss_name = UIF.label("", 24, Color("ff9ed0"))
    boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    bv.add_child(boss_name)
    boss_bar = UIF.bar(Color("c030ff"), 24, 300)
    boss_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bv.add_child(boss_bar)
    prompt_label = UIF.label("", 24, Color("9fffa0"))
    prompt_label.anchor_left = 0.0
    prompt_label.anchor_right = 1.0
    prompt_label.anchor_top = 0.62
    prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    game_layer.add_child(prompt_label)
    reveal_label = UIF.label("", 44, Color.WHITE)
    reveal_label.anchor_left = 0.0
    reveal_label.anchor_right = 1.0
    reveal_label.anchor_top = 0.68
    reveal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    reveal_label.add_theme_constant_override("outline_size", 12)
    reveal_label.modulate.a = 0.0
    reveal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    game_layer.add_child(reveal_label)


func open_window(key):
    if GameState.cinematic_busy or GameState.in_menu:
        return
    for k in windows:
        if k != key:
            windows[k].close()
    windows[key].open()


func close_all():
    for k in windows:
        windows[k].close()
    reveal_window.close()


func refresh():
    if hp_bar == null:
        return
    for c in cur_labels:
        cur_labels[c].text = str(GameState.get_cur(c))
    var mh = GameState.max_hp()
    hp_bar.max_value = mh
    hp_bar.value = maxf(GameState.hp, 0.0)
    hp_label.text = "%d/%d" % [int(maxf(GameState.hp, 0.0)), int(mh)]
    xp_bar.max_value = GameState.xp_needed()
    xp_bar.value = GameState.xp
    lvl_label.text = "Ур. %d  -  %s" % [GameState.level, GameState.current_title()]
    var q = GameState.active_story()
    if q != null:
        quest_label.text = "Задание: %s (%d/%d)" % [q.title, mini(GameState.stat_value(q.key), int(q.target)), int(q.target)]
    else:
        quest_label.text = "Все сюжетные задания выполнены"


func _process(delta):
    _rect_t -= delta
    if _rect_t <= 0.0:
        _rect_t = 0.5
        var vp = get_viewport_rect().size
        GameState.ui_rects = [Rect2(vp.x - 700, 0, 700, 330), Rect2(0, 0, 330, 260)]


func toast(text):
    if toast_box == null:
        return
    var l = UIF.label(text, 24, Color("fff2b0"))
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    toast_box.add_child(l)
    while toast_box.get_child_count() > 4:
        toast_box.get_child(0).queue_free()
        toast_box.remove_child(toast_box.get_child(0))
    var tw = l.create_tween()
    tw.tween_interval(2.6)
    tw.tween_property(l, "modulate:a", 0.0, 0.6)
    tw.tween_callback(l.queue_free)


func show_banner(text, color = Color.WHITE, dur = 2.2):
    banner.text = text
    banner.add_theme_color_override("font_color", color)
    var tw = create_tween()
    tw.tween_property(banner, "modulate:a", 1.0, 0.3)
    tw.tween_interval(dur)
    tw.tween_property(banner, "modulate:a", 0.0, 0.6)


func _on_quest_done(title):
    toast("Задание выполнено: " + title)
    AudioManager.play_ui("reward")


func _on_boss_bar(bname, hp, max_hp, shown):
    boss_panel.visible = shown
    if shown:
        boss_name.text = bname
        boss_bar.max_value = max_hp
        boss_bar.value = maxf(hp, 0.0)


func _on_region(i):
    var rd = GameData.REGIONS[i]
    show_banner(rd.name, rd.sky_hor.lightened(0.2))


func _on_flash(color, dur):
    flash_rect.color = Color(color.r, color.g, color.b, color.a)
    var tw = create_tween()
    tw.tween_property(flash_rect, "color:a", 0.0, dur)


func _on_prompt(text):
    prompt_label.text = text


func _on_died():
    show_banner("Поражение", Color("ff5a5a"), 1.8)


func _on_victory():
    show_banner("ПОБЕДА! Вы - Король Яиц!", Color("ffd24a"), 6.0)


func _on_reveal(pet):
    var d = GameData.pet(pet.id)
    reveal_label.text = "%s\n%s" % [d.name, GameData.rarity_name(d.rarity)]
    reveal_label.add_theme_color_override("font_color", GameData.rarity_color(d.rarity).lightened(0.3))
    var tw = create_tween()
    tw.tween_property(reveal_label, "modulate:a", 1.0, 0.25)
    tw.tween_interval(2.3)
    tw.tween_property(reveal_label, "modulate:a", 0.0, 0.5)
