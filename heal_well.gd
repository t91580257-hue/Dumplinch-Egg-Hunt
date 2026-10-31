extends Node3D
## Целебный колодец: восстанавливает здоровье (перезарядка 30 секунд).

const Fx = preload("res://scripts/vfx/fx.gd")
var cd = 0.0


func _ready():
    add_to_group("interactables")
    var m = StandardMaterial3D.new()
    m.albedo_color = Color("8a8a96")
    var ring = MeshInstance3D.new()
    var cm = CylinderMesh.new()
    cm.top_radius = 1.2
    cm.bottom_radius = 1.3
    cm.height = 0.9
    ring.mesh = cm
    ring.material_override = m
    ring.position = Vector3(0, 0.45, 0)
    add_child(ring)
    var w = MeshInstance3D.new()
    var wm = CylinderMesh.new()
    wm.top_radius = 1.0
    wm.bottom_radius = 1.0
    wm.height = 0.05
    w.mesh = wm
    var sm = ShaderMaterial.new()
    sm.shader = load("res://shaders/water.gdshader")
    sm.set_shader_parameter("water_color", Color(0.3, 0.9, 1.0, 0.85))
    sm.set_shader_parameter("glow", 1.2)
    w.material_override = sm
    w.position = Vector3(0, 0.9, 0)
    add_child(w)


func _process(delta):
    cd = maxf(0.0, cd - delta)


func interact_prompt():
    return "Колодец: восстановить здоровье" if cd <= 0.0 else "Колодец остывает (%d с)" % int(cd)


func interact(_player):
    if cd > 0.0:
        return
    cd = 30.0
    GameState.heal(9999)
    GameState.message.emit("Здоровье восстановлено")
    AudioManager.play_sfx("reward")
    Fx.burst(get_parent(), global_position + Vector3(0, 1.2, 0), Color("6af0ff"), 20, 4.0, 0.8)
