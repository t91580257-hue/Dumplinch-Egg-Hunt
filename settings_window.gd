extends "res://scripts/ui/window_base.gd"
## Настройки: громкость, камера, размер кнопок, качество графики, вибрация, сохранение.


func _init():
    super("Настройки")


func _slider(box, text, key, lo, hi, step = 0.05):
    var r = UIF.row(box)
    var l = UIF.label(text, 22)
    l.custom_minimum_size = Vector2(300, 0)
    r.add_child(l)
    var s = HSlider.new()
    s.min_value = lo
    s.max_value = hi
    s.step = step
    s.value = float(GameState.settings.get(key, 1.0))
    s.custom_minimum_size = Vector2(300, 44)
    s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    s.value_changed.connect(_on_slider.bind(key))
    r.add_child(s)


func _on_slider(v, key):
    GameState.settings[key] = v
    AudioManager.apply_volumes()
    GameState.settings_changed.emit()


func _check(box, text, key):
    var c = CheckButton.new()
    c.text = text
    c.add_theme_font_size_override("font_size", 22)
    c.button_pressed = bool(GameState.settings.get(key, false))
    c.focus_mode = Control.FOCUS_NONE
    c.custom_minimum_size = Vector2(0, 56)
    c.toggled.connect(_on_toggle.bind(key))
    box.add_child(c)


func _on_toggle(v, key):
    GameState.settings[key] = v
    GameState.settings_changed.emit()


func _quality(i):
    GameState.settings["quality"] = i
    GameState.settings_changed.emit()


func _save():
    if SaveSystem.save_game():
        GameState.message.emit("Игра сохранена")


func _menu():
    SaveSystem.save_game()
    close()
    GameState.request_menu.emit()


func build(box):
    box.add_child(UIF.label("Звук", 28, Color("ffd24a")))
    _slider(box, "Музыка", "music", 0.0, 1.0)
    _slider(box, "Эффекты", "sfx", 0.0, 1.0)
    _slider(box, "Интерфейс", "ui", 0.0, 1.0)
    box.add_child(UIF.label("Управление", 28, Color("ffd24a")))
    _slider(box, "Чувствительность камеры", "cam_sens", 0.3, 2.0, 0.1)
    _slider(box, "Размер кнопок", "btn_scale", 0.7, 1.5, 0.1)
    _check(box, "Инвертировать камеру по вертикали", "cam_invert")
    _check(box, "Вибрация", "vibration")
    _check(box, "Быстрое открытие яиц (без анимации)", "fast_open")
    box.add_child(UIF.label("Графика", 28, Color("ffd24a")))
    var r = UIF.row(box)
    for i in 3:
        var b = UIF.button(["Низкая", "Средняя", "Высокая"][i], Vector2(0, 60))
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.disabled = int(GameState.settings.get("quality", 1)) == i
        b.pressed.connect(_quality.bind(i))
        b.pressed.connect(refresh_all)
        r.add_child(b)
    box.add_child(UIF.label("Низкая: 60% разрешения, без теней, без свечения, мало декора. Высокая: полное разрешение, тени, свечение.", 18, Color(0.8, 0.85, 1.0), true))
    box.add_child(UIF.label("Игра", 28, Color("ffd24a")))
    var bs = UIF.button("Сохранить игру", Vector2(0, 60))
    bs.pressed.connect(_save)
    box.add_child(bs)
    var bm = UIF.button("Главное меню", Vector2(0, 60))
    bm.pressed.connect(_menu)
    box.add_child(bm)
    box.add_child(UIF.label("Мультиплеер (игра с друзьями, обмен питомцами, групповые бои) - будущая функция, сейчас не реализован.", 18, Color(0.8, 0.85, 1.0), true))
