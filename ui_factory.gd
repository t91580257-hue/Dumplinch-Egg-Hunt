extends RefCounted
## Фабрика элементов интерфейса: тема, кнопки, подписи, карточки.

const Icon = preload("res://scripts/ui/icon.gd")
const CUR_NAMES = {"coins": "монет", "gems": "самоцв.", "crystals": "кристаллов", "tokens": "жетонов"}
const CUR_ICONS = {"coins": "coin", "gems": "gem", "crystals": "crystal", "tokens": "token"}


static func style(bg, radius = 14, border = Color(0, 0, 0, 0), bw = 0, margin = 10):
    var s = StyleBoxFlat.new()
    s.bg_color = bg
    s.set_corner_radius_all(radius)
    s.border_color = border
    s.set_border_width_all(bw)
    s.set_content_margin_all(margin)
    return s


static func make_theme():
    var t = Theme.new()
    t.default_font_size = 22
    var edge = Color("6f8cff")
    for tn in ["Button", "OptionButton"]:
        t.set_stylebox("normal", tn, style(Color("2b3766"), 14, edge, 2))
        t.set_stylebox("hover", tn, style(Color("38478a"), 14, edge, 2))
        t.set_stylebox("pressed", tn, style(Color("1b2547"), 14, edge, 2))
        t.set_stylebox("disabled", tn, style(Color(0.18, 0.18, 0.24, 0.8), 14, Color(0.3, 0.3, 0.4), 1))
        t.set_stylebox("focus", tn, StyleBoxEmpty.new())
        t.set_color("font_color", tn, Color.WHITE)
        t.set_color("font_hover_color", tn, Color.WHITE)
        t.set_color("font_pressed_color", tn, Color(0.85, 0.9, 1.0))
        t.set_color("font_disabled_color", tn, Color(0.55, 0.55, 0.65))
    t.set_stylebox("panel", "PanelContainer", style(Color(0.07, 0.09, 0.2, 0.95), 18, edge, 2))
    t.set_stylebox("panel", "PopupMenu", style(Color(0.07, 0.09, 0.2, 0.98), 10, edge, 2))
    t.set_stylebox("hover", "PopupMenu", style(Color("38478a"), 6))
    t.set_font_size("font_size", "PopupMenu", 24)
    t.set_stylebox("background", "ProgressBar", style(Color(0, 0, 0, 0.55), 8, Color(1, 1, 1, 0.25), 1, 0))
    t.set_stylebox("fill", "ProgressBar", style(Color("4ad66d"), 8, Color(0, 0, 0, 0), 0, 0))
    return t


static func button(text, min_size = Vector2(0, 64), font = 22):
    var b = Button.new()
    b.text = text
    b.custom_minimum_size = min_size
    b.add_theme_font_size_override("font_size", font)
    b.focus_mode = Control.FOCUS_NONE
    b.pressed.connect(func(): AudioManager.play_ui("click"))
    return b


static func label(text, size = 22, color = Color.WHITE, wrap = false):
    var l = Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    l.add_theme_constant_override("outline_size", 4)
    l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
    if wrap:
        l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return l


static func bar(color, height = 26, width = 260):
    var b = ProgressBar.new()
    b.show_percentage = false
    b.custom_minimum_size = Vector2(width, height)
    b.add_theme_stylebox_override("fill", style(color, 8, Color(0, 0, 0, 0), 0, 0))
    return b


static func row(parent):
    var r = HBoxContainer.new()
    r.add_theme_constant_override("separation", 10)
    r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(r)
    return r


static func card(parent, color = Color(0.12, 0.15, 0.3, 0.9)):
    var p = PanelContainer.new()
    p.add_theme_stylebox_override("panel", style(color, 12, Color(0.35, 0.45, 0.8, 0.6), 1))
    p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var v = VBoxContainer.new()
    v.add_theme_constant_override("separation", 6)
    p.add_child(v)
    parent.add_child(p)
    return v


static func cost_text(cur, amount):
    return "%d %s" % [amount, CUR_NAMES.get(cur, "")]


static func currency_bar():
    var h = HBoxContainer.new()
    h.add_theme_constant_override("separation", 18)
    for c in ["coins", "gems", "crystals", "tokens"]:
        h.add_child(Icon.new(CUR_ICONS[c], 30))
        h.add_child(label(str(GameState.get_cur(c)), 24, Color("ffe9a0")))
    return h


static func icon_button(kind, size = 68):
    var b = Button.new()
    b.custom_minimum_size = Vector2(size, size)
    b.focus_mode = Control.FOCUS_NONE
    b.pressed.connect(func(): AudioManager.play_ui("click"))
    var ic = Icon.new(kind, size * 0.55)
    ic.set_anchors_preset(Control.PRESET_FULL_RECT)
    ic.offset_left = size * 0.2
    ic.offset_top = size * 0.2
    ic.offset_right = -size * 0.2
    ic.offset_bottom = -size * 0.2
    b.add_child(ic)
    return b
