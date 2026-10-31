extends Control
## Круглая кнопка действия. Нажатия обрабатывает TouchControls (мультитач).

const Icon = preload("res://scripts/ui/icon.gd")
var action = ""
var radius = 50.0
var held = false
var cd = 0.0
var icon_node


func setup(a, kind, r):
    action = a
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    icon_node = Icon.new(kind, r)
    add_child(icon_node)
    set_radius(r)


func set_radius(r):
    radius = r
    custom_minimum_size = Vector2(r * 2, r * 2)
    size = Vector2(r * 2, r * 2)
    icon_node.custom_minimum_size = Vector2(r * 1.1, r * 1.1)
    icon_node.size = Vector2(r * 1.1, r * 1.1)
    icon_node.position = Vector2(r * 0.45, r * 0.45)


func contains(p):
    return (global_position + Vector2(radius, radius)).distance_to(p) <= radius * 1.15


func _process(_d):
    queue_redraw()


func _draw():
    var c = Vector2(radius, radius)
    draw_circle(c, radius, Color(0.4, 0.55, 1.0, 0.75) if held else Color(0.12, 0.17, 0.4, 0.6))
    draw_arc(c, radius - 2, 0, TAU, 40, Color(0.75, 0.85, 1.0, 0.85), 3.0)
    if cd > 0.01:
        var pts = PackedVector2Array([c])
        for i in 25:
            var a = -PI / 2.0 + TAU * clampf(cd, 0.0, 0.999) * i / 24.0
            pts.append(c + Vector2(cos(a), sin(a)) * radius)
        draw_colored_polygon(pts, Color(0, 0, 0, 0.55))
