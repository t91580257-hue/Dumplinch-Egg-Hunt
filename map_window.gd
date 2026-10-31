extends "res://scripts/ui/window_base.gd"
## Карта мира.

const MiniMap = preload("res://scripts/ui/minimap.gd")


func _init():
    super("Карта мира")


func build(box):
    box.add_child(UIF.label("Регион: %s     Открыто регионов: %d / 5" % [GameData.REGIONS[GameState.current_region].name, GameState.unlocked_regions], 22, Color("ffd24a")))
    var m = MiniMap.new(true)
    m.custom_minimum_size = Vector2(0, 380)
    m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    m.process_mode = Node.PROCESS_MODE_ALWAYS
    box.add_child(m)
    box.add_child(UIF.label("Белый треугольник - вы. Фиолетовые точки - боссы (серые - побеждены). Жёлтые - яйца. Тёмные области закрыты: победите босса региона и откройте врата.", 18, Color(0.8, 0.85, 1.0), true))
