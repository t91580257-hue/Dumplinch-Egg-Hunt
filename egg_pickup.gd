extends Node3D
## Яйцо на каменной платформе: подойдите и нажмите «действие». Появляется снова через 90 секунд.

const EggBuilder = preload("res://scripts/pets/egg_builder.gd")
const Fx = preload("res://scripts/vfx/fx.gd")
var egg_id = "common"
var region = 0
var active = true
var t = 0.0
var egg_node


func setup(id, r):
    egg_id = id
    region = r


func _ready():
    add_to_group("interactables")
    add_to_group("eggs_world")
    var plat = MeshInstance3D.new()
    var cm = CylinderMesh.new()
    cm.top_radius = 1.0
    cm.bottom_radius = 1.2
    cm.height = 0.3
    cm.radial_segments = 16
    plat.mesh = cm
    var pm = StandardMaterial3D.new()
    pm.albedo_color = Color("8a8a96")
    pm.roughness = 0.9
    plat.material_override = pm
    plat.position = Vector3(0, 0.15, 0)
    add_child(plat)
    egg_node = EggBuilder.build_egg(GameData.egg(egg_id), 0.8)
    egg_node.position = Vector3(0, 1.1, 0)
    add_child(egg_node)


func _process(delta):
    if active:
        t += delta
        egg_node.rotation.y += delta
        egg_node.position.y = 1.1 + sin(t * 2.0) * 0.12


func interact_prompt():
    if not active:
        return ""
    return "Взять яйцо: " + GameData.egg(egg_id).name


func interact(_player):
    if not active:
        return
    active = false
    egg_node.visible = false
    GameState.add_egg(egg_id, 1)
    GameState.record_world_egg(region)
    GameState.message.emit("Найдено: " + GameData.egg(egg_id).name)
    AudioManager.play_sfx("reward")
    Fx.burst(get_parent(), global_position + Vector3(0, 1.2, 0), GameData.egg(egg_id).accent, 20, 5.0, 0.8)
    get_tree().create_timer(90.0).timeout.connect(_respawn)


func _respawn():
    active = true
    egg_node.visible = true
