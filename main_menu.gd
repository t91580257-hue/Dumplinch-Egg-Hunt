extends Control
## Главное меню поверх 3D-мира (камера медленно облетает локацию).

const UIF = preload("res://scripts/ui/ui_factory.gd")
signal play_pressed(new_game)
var _confirm = false
var _box
var _new_btn


func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var dim = ColorRect.new()
    dim.color = Color(0.03, 0.05, 0.12, 0.45)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(dim)
    var center = CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    _box = VBoxContainer.new()
    _box.add_theme_constant_override("separation", 14)
    center.add_child(_box)
    var title = UIF.label("DUMPLINCH", 84, Color("ffd24a"))
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_constant_override("outline_size", 14)
    _box.add_child(title)
    var sub = UIF.label("EGG HUNT", 52, Color("ff9ed0"))
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sub.add_theme_constant_override("outline_size", 10)
    _box.add_child(sub)
    var cont = UIF.button("Продолжить", Vector2(420, 72), 28)
    cont.disabled = not SaveSystem.has_save()
    cont.pressed.connect(func(): play_pressed.emit(false))
    _box.add_child(cont)
    _new_btn = UIF.button("Новая игра", Vector2(420, 72), 28)
    _new_btn.pressed.connect(_on_new)
    _box.add_child(_new_btn)
    var q = UIF.button("Выход", Vector2(420, 64), 24)
    q.pressed.connect(func(): get_tree().quit())
    _box.add_child(q)
    var ver = UIF.label("Версия 0.1.0 - ранний прототип", 18, Color(0.8, 0.85, 1.0))
    ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _box.add_child(ver)
    modulate.a = 0.0
    create_tween().tween_property(self, "modulate:a", 1.0, 0.8)


func _on_new():
    if SaveSystem.has_save() and not _confirm:
        _confirm = true
        _new_btn.text = "Точно удалить прогресс? Нажмите ещё раз"
        return
    play_pressed.emit(true)
