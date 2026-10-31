extends Control
## Векторные иконки, нарисованные кодом (без внешних картинок).

var kind = "coin"


func _init(k = "coin", sz = 32):
    kind = k
    custom_minimum_size = Vector2(sz, sz)
    size = Vector2(sz, sz)
    mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ngon(c, r, n, rot = 0.0, squash = 1.0):
    var pts = PackedVector2Array()
    for i in n:
        var a = rot + TAU * i / n
        pts.append(c + Vector2(cos(a) * r, sin(a) * r * squash))
    return pts


func _star(c, r1, r2, n):
    var pts = PackedVector2Array()
    for i in n * 2:
        var a = -PI / 2.0 + PI * i / n
        var r = r1 if i % 2 == 0 else r2
        pts.append(c + Vector2(cos(a), sin(a)) * r)
    return pts


func _draw():
    var c = size / 2.0
    var r = minf(size.x, size.y) * 0.45
    match kind:
        "coin":
            draw_circle(c, r, Color("c98a14"))
            draw_circle(c, r * 0.85, Color("ffc83a"))
            draw_circle(c, r * 0.5, Color("ffe27a"))
        "gem":
            draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, -r * 0.2), c + Vector2(0, r), c + Vector2(-r, -r * 0.2)]), Color("35d0ff"))
            draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.4, -r * 0.2), c + Vector2(0, r * 0.6), c + Vector2(-r * 0.4, -r * 0.2)]), Color("a5f2ff"))
        "crystal":
            draw_colored_polygon(_ngon(c, r, 6, PI / 6.0), Color("a050f0"))
            draw_colored_polygon(_ngon(c, r * 0.55, 6, PI / 6.0), Color("e0b0ff"))
        "token":
            draw_colored_polygon(_star(c, r, r * 0.5, 5), Color("ff6fb5"))
        "heart":
            var red = Color("ff4a5a")
            draw_circle(c + Vector2(-r * 0.45, -r * 0.25), r * 0.55, red)
            draw_circle(c + Vector2(r * 0.45, -r * 0.25), r * 0.55, red)
            draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.95, -r * 0.05), c + Vector2(r * 0.95, -r * 0.05), c + Vector2(0, r)]), red)
        "egg":
            draw_colored_polygon(_ngon(c + Vector2(0, r * 0.1), r * 0.75, 24, 0.0, 1.3), Color("f5e8c8"))
            draw_circle(c + Vector2(-r * 0.2, r * 0.1), r * 0.12, Color("e0a050"))
            draw_circle(c + Vector2(r * 0.25, r * 0.4), r * 0.1, Color("e0a050"))
        "paw":
            var col = Color("ffd0a0")
            draw_circle(c + Vector2(0, r * 0.35), r * 0.5, col)
            for p in [Vector2(-0.75, -0.1), Vector2(-0.28, -0.55), Vector2(0.28, -0.55), Vector2(0.75, -0.1)]:
                draw_circle(c + p * r, r * 0.22, col)
        "bag":
            draw_rect(Rect2(c + Vector2(-r * 0.8, -r * 0.3), Vector2(r * 1.6, r * 1.2)), Color("b0763a"))
            draw_arc(c + Vector2(0, -r * 0.3), r * 0.45, PI, TAU, 12, Color("8a5a28"), 4.0)
            draw_rect(Rect2(c + Vector2(-r * 0.15, 0), Vector2(r * 0.3, r * 0.3)), Color("ffd24a"))
        "map":
            draw_colored_polygon(PackedVector2Array([c + Vector2(-r, -r * 0.7), c + Vector2(-r * 0.33, -r * 0.9), c + Vector2(r * 0.33, -r * 0.7), c + Vector2(r, -r * 0.9), c + Vector2(r, r * 0.7), c + Vector2(r * 0.33, r * 0.9), c + Vector2(-r * 0.33, r * 0.7), c + Vector2(-r, r * 0.9)]), Color("e8d8a0"))
            draw_line(c + Vector2(-r * 0.33, -r * 0.9), c + Vector2(-r * 0.33, r * 0.7), Color("a08850"), 2.0)
            draw_line(c + Vector2(r * 0.33, -r * 0.7), c + Vector2(r * 0.33, r * 0.9), Color("a08850"), 2.0)
            draw_circle(c + Vector2(r * 0.5, 0), r * 0.15, Color("e04a3a"))
        "gear":
            draw_colored_polygon(_star(c, r, r * 0.78, 8), Color("b8c0d0"))
            draw_circle(c, r * 0.35, Color("2b3766"))
        "shop":
            draw_rect(Rect2(c + Vector2(-r * 0.8, -r * 0.1), Vector2(r * 1.6, r * 1.0)), Color("c89050"))
            draw_colored_polygon(PackedVector2Array([c + Vector2(-r, -r * 0.1), c + Vector2(-r * 0.75, -r * 0.8), c + Vector2(r * 0.75, -r * 0.8), c + Vector2(r, -r * 0.1)]), Color("e04a3a"))
            draw_rect(Rect2(c + Vector2(-r * 0.2, r * 0.3), Vector2(r * 0.4, r * 0.6)), Color("6a4020"))
        "scroll":
            draw_rect(Rect2(c + Vector2(-r * 0.7, -r * 0.8), Vector2(r * 1.4, r * 1.6)), Color("f0e2b8"))
            for i in 4:
                draw_line(c + Vector2(-r * 0.45, -r * 0.5 + i * r * 0.35), c + Vector2(r * 0.45, -r * 0.5 + i * r * 0.35), Color("8a7a50"), 2.0)
        "trophy":
            draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.7, -r * 0.8), c + Vector2(r * 0.7, -r * 0.8), c + Vector2(r * 0.4, r * 0.1), c + Vector2(-r * 0.4, r * 0.1)]), Color("ffc83a"))
            draw_rect(Rect2(c + Vector2(-r * 0.12, r * 0.1), Vector2(r * 0.24, r * 0.4)), Color("ffc83a"))
            draw_rect(Rect2(c + Vector2(-r * 0.5, r * 0.5), Vector2(r, r * 0.3)), Color("c98a14"))
        "sword":
            draw_line(c + Vector2(-r * 0.7, r * 0.7), c + Vector2(r * 0.7, -r * 0.7), Color("e8eef8"), 7.0)
            draw_line(c + Vector2(-r * 0.55, r * 0.15), c + Vector2(-r * 0.15, r * 0.55), Color("ffc83a"), 5.0)
            draw_line(c + Vector2(-r * 0.85, r * 0.85), c + Vector2(-r * 0.55, r * 0.55), Color("8a5a28"), 6.0)
        "arrow_up":
            draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.8, 0), c + Vector2(-r * 0.8, 0)]), Color.WHITE)
            draw_rect(Rect2(c + Vector2(-r * 0.3, 0), Vector2(r * 0.6, r * 0.9)), Color.WHITE)
        "star":
            draw_colored_polygon(_star(c, r, r * 0.45, 5), Color("ffd24a"))
        "dash":
            for o in [-0.5, 0.3]:
                draw_polyline(PackedVector2Array([c + Vector2((o - 0.3) * r, -r * 0.7), c + Vector2((o + 0.3) * r, 0), c + Vector2((o - 0.3) * r, r * 0.7)]), Color.WHITE, 6.0)
        "hand":
            draw_rect(Rect2(c + Vector2(-r * 0.15, -r * 0.8), Vector2(r * 0.3, r * 1.0)), Color.WHITE)
            draw_circle(c + Vector2(0, r * 0.6), r * 0.2, Color.WHITE)
        _:
            draw_circle(c, r, Color.WHITE)
