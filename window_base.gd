extends Control
## Базовое окно: затемнение, панель, заголовок, прокручиваемое содержимое.
## Наследники переопределяют build(box). Любое действие вызывает refresh_all().

const UIF = preload("res://scripts/ui/ui_factory.gd")
signal closed
var title_text = ""
var content
var panel


func _init(t = ""):
    title_text = t
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var dim = ColorRect.new()
    dim.color = Color(0, 0, 0, 0.6)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(dim)
    panel = PanelContainer.new()
    panel.anchor_left = 0.04
    panel.anchor_right = 0.96
    panel.anchor_top = 0.05
    panel.anchor_bottom = 0.95
    add_child(panel)
    var v = VBoxContainer.new()
    v.add_theme_constant_override("separation", 8)
    panel.add_child(v)
    var top = HBoxContainer.new()
    v.add_child(top)
    var tl = UIF.label(t, 32, Color("ffd24a"))
    tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(tl)
    var cb = UIF.button("Закрыть", Vector2(160, 60))
    cb.pressed.connect(close)
    top.add_child(cb)
    var scroll = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    v.add_child(scroll)
    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 10)
    scroll.add_child(content)


func open():
    refresh_all()
    if not visible:
        visible = true
        GameState.window_opened()


func close():
    if visible:
        visible = false
        GameState.window_closed()
        closed.emit()


func refresh_all():
    for c in content.get_children():
        content.remove_child(c)
        c.queue_free()
    build(content)


func build(_box):
    pass
