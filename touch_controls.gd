extends Control
## Мобильное управление: плавающий джойстик слева, свайп камеры справа,
## щипок для зума, кнопки действий (настоящий мультитач). На ПК: WASD/мышь (см. README).

const TouchBtn = preload("res://scripts/ui/touch_button.gd")
var buttons = []
var touches = {}
var joy_center = Vector2.ZERO
var joy_pos = Vector2.ZERO
var joy_active = false
var rmb = false
var pinch_last = -1.0
var _vp = Vector2.ZERO


func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_preset(Control.PRESET_FULL_RECT)
    for d in [["attack", "sword"], ["jump", "arrow_up"], ["special", "star"], ["dodge", "dash"], ["interact", "hand"], ["pets", "paw"]]:
        var b = TouchBtn.new()
        add_child(b)
        b.setup(d[0], d[1], 50.0)
        buttons.append(b)
    GameState.settings_changed.connect(_layout)
    _layout()


func _layout():
    _vp = get_viewport_rect().size
    var u = 90.0 * float(GameState.settings.get("btn_scale", 1.0))
    var a = Vector2(_vp.x - 1.6 * u, _vp.y - 1.5 * u)
    var spec = {"attack": [Vector2(0, 0), 0.95], "jump": [Vector2(-2.0, 0.15), 0.7], "special": [Vector2(-1.45, -1.5), 0.62],
        "dodge": [Vector2(0.1, -2.35), 0.58], "interact": [Vector2(-3.3, -0.4), 0.55], "pets": [Vector2(-2.9, -1.7), 0.55]}
    for b in buttons:
        var s = spec[b.action]
        var r = u * s[1]
        b.set_radius(r)
        b.position = a + s[0] * u - Vector2(r, r)


func _process(_d):
    if get_viewport_rect().size != _vp:
        _layout()
    var pl = GameState.player_node
    for b in buttons:
        b.cd = pl.cd_frac(b.action) if pl != null else 0.0
    queue_redraw()


func _draw():
    var sc = float(GameState.settings.get("btn_scale", 1.0))
    var rad = 110.0 * sc
    if joy_active:
        draw_circle(joy_center, rad, Color(0.1, 0.15, 0.35, 0.35))
        draw_arc(joy_center, rad, 0, TAU, 48, Color(0.75, 0.85, 1.0, 0.7), 3.0)
        draw_circle(joy_center + (joy_pos - joy_center).limit_length(rad), rad * 0.38, Color(0.6, 0.75, 1.0, 0.75))
    else:
        var c = Vector2(_vp.x * 0.14, _vp.y * 0.74)
        draw_arc(c, rad, 0, TAU, 48, Color(0.75, 0.85, 1.0, 0.25), 3.0)
        draw_circle(c, rad * 0.38, Color(0.6, 0.75, 1.0, 0.2))


func _button_at(p):
    for b in buttons:
        if b.contains(p):
            return b
    return null


func _excluded(p):
    for r in GameState.ui_rects:
        if r.has_point(p):
            return true
    return false


func _press_btn(idx, b):
    touches[idx] = {"role": "btn", "btn": b}
    b.held = true
    Input.action_press(b.action)
    GameState.latched[b.action] = true


func _on_press(idx, pos):
    var b = _button_at(pos)
    if b != null:
        _press_btn(idx, b)
        return
    if _excluded(pos):
        return
    if pos.x < _vp.x * 0.42 and pos.y > _vp.y * 0.25 and not joy_active:
        joy_active = true
        joy_center = pos
        joy_pos = pos
        touches[idx] = {"role": "joy"}
        return
    touches[idx] = {"role": "cam", "pos": pos}


func _on_release(idx):
    if not touches.has(idx):
        return
    var t = touches[idx]
    match t.role:
        "btn":
            t.btn.held = false
            Input.action_release(t.btn.action)
        "joy":
            joy_active = false
            GameState.touch_move = Vector2.ZERO
    touches.erase(idx)
    pinch_last = -1.0


func _cam_touches():
    var res = []
    for k in touches:
        if touches[k].role == "cam":
            res.append(touches[k])
    return res


func _on_drag(idx, pos, rel):
    if not touches.has(idx):
        return
    var t = touches[idx]
    if t.role == "joy":
        joy_pos = pos
        var rad = 110.0 * float(GameState.settings.get("btn_scale", 1.0))
        var v = (pos - joy_center).limit_length(rad) / rad
        GameState.touch_move = v if v.length() > 0.15 else Vector2.ZERO
    elif t.role == "cam":
        t.pos = pos
        var cams = _cam_touches()
        if cams.size() >= 2:
            var d = cams[0].pos.distance_to(cams[1].pos)
            if pinch_last > 0.0:
                GameState.cam_zoom += (d - pinch_last) * 0.03
            pinch_last = d
        else:
            GameState.cam_drag += rel


func _release_all():
    if touches.is_empty() and not rmb:
        return
    for idx in touches.keys():
        _on_release(idx)
    rmb = false
    for a in ["attack", "jump", "special", "dodge", "interact", "pets"]:
        Input.action_release(a)


func _input(event):
    if GameState.in_menu or GameState.windows_open > 0:
        _release_all()
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            _on_press(event.index, event.position)
        else:
            _on_release(event.index)
    elif event is InputEventScreenDrag:
        _on_drag(event.index, event.position, event.relative)
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                var b = _button_at(event.position)
                if b != null and not b.held:
                    _press_btn(99, b)
            else:
                _on_release(99)
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            rmb = event.pressed
        elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            GameState.cam_zoom += 0.8
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            GameState.cam_zoom -= 0.8
    elif event is InputEventMouseMotion and rmb:
        GameState.cam_drag += event.relative
