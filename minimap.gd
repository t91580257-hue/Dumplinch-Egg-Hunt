extends Control
## Мини-карта (круглая, вокруг игрока) и полная карта мира (режим full).

var full = false
var range_m = 70.0
var _t = 0.0


func _init(is_full = false):
    full = is_full
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    if not full:
        custom_minimum_size = Vector2(180, 180)


func _process(delta):
    _t += delta
    if _t > 0.15:
        _t = 0.0
        queue_redraw()


func _draw():
    var pl = GameState.player_node
    if pl == null:
        return
    if full:
        _draw_full(pl)
    else:
        _draw_mini(pl)


func _draw_mini(pl):
    var c = size / 2.0
    var r = minf(size.x, size.y) / 2.0
    draw_circle(c, r, Color(0.05, 0.08, 0.16, 0.75))
    var reg = GameData.REGIONS[GameState.current_region]
    draw_circle(c, r - 6, reg.ground.darkened(0.5))
    var k = (r - 8) / range_m
    var pp = pl.global_position
    for grp in [["eggs_world", Color("ffd24a"), 4.0], ["enemies", Color("ff5a5a"), 3.0], ["bosses", Color("c060ff"), 6.0], ["interactables", Color("5ae0ff"), 3.0]]:
        for n in get_tree().get_nodes_in_group(grp[0]):
            if not is_instance_valid(n) or (n.get("dead") == true) or (n.get("active") == false):
                continue
            var d = Vector2(n.global_position.x - pp.x, n.global_position.z - pp.z)
            if d.length() < range_m:
                draw_circle(c + d * k, grp[2], grp[1])
    draw_arc(c, r - 2, 0, TAU, 40, Color(0.7, 0.8, 1.0, 0.9), 3.0)
    var a = -GameState.cam_yaw
    draw_colored_polygon(PackedVector2Array([c + Vector2(0, -10).rotated(a * 0.0), c + Vector2(7, 8), c + Vector2(-7, 8)]), Color.WHITE)


func _draw_full(pl):
    var w = size.x
    var h = minf(size.y, w / 5.0)
    var k = w / (GameData.REGION_SIZE * 5.0)
    var origin = Vector2(0, (size.y - h) / 2.0)
    for i in 5:
        var rd = GameData.REGIONS[i]
        var rect = Rect2(origin + Vector2(i * GameData.REGION_SIZE * k, 0), Vector2(GameData.REGION_SIZE * k, h))
        var col = rd.ground.darkened(0.2) if i < GameState.unlocked_regions else rd.ground.darkened(0.7)
        draw_rect(rect, col)
        draw_rect(rect, Color(1, 1, 1, 0.5), false, 2.0)
        draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, 24), rd.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
    var to_map = func(p):
        return origin + Vector2((p.x + GameData.REGION_HALF) * k, (p.z + GameData.REGION_HALF) * k * (h / (GameData.REGION_SIZE * k)))
    for b in GameData.BOSSES:
        var pos = GameData.region_origin(b.region) + Vector3(b.pos.x, 0, b.pos.y)
        var done = GameState.defeated_bosses.has(b.id)
        draw_circle(to_map.call(pos), 7.0, Color(0.4, 0.4, 0.4) if done else Color("c060ff"))
    for n in get_tree().get_nodes_in_group("eggs_world"):
        if is_instance_valid(n) and n.get("active") == true:
            draw_circle(to_map.call(n.global_position), 3.0, Color("ffd24a"))
    var pp = to_map.call(pl.global_position)
    draw_colored_polygon(PackedVector2Array([pp + Vector2(0, -10), pp + Vector2(8, 8), pp + Vector2(-8, 8)]), Color.WHITE)
