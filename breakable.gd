extends StaticBody3D
## Разрушаемый ящик: монеты за разбитие, появляется снова через минуту.

const Fx = preload("res://scripts/vfx/fx.gd")
var region = 0
var dead = false
var hit_radius = 0.7
var mesh
var cs


func setup(r):
    region = r


func _ready():
    add_to_group("breakables")
    mesh = MeshInstance3D.new()
    var b = BoxMesh.new()
    b.size = Vector3(1, 1, 1)
    mesh.mesh = b
    var m = StandardMaterial3D.new()
    m.albedo_color = Color("a87838")
    m.roughness = 0.9
    mesh.material_override = m
    mesh.position = Vector3(0, 0.5, 0)
    add_child(mesh)
    cs = CollisionShape3D.new()
    var sh = BoxShape3D.new()
    sh.size = Vector3(1, 1, 1)
    cs.shape = sh
    cs.position = Vector3(0, 0.5, 0)
    add_child(cs)


func smash():
    if dead:
        return
    dead = true
    mesh.visible = false
    cs.set_deferred("disabled", true)
    GameState.gain_coins(5 + region * 6)
    Fx.burst(get_parent(), global_position + Vector3(0, 0.5, 0), Color("c89050"), 12, 4.0, 0.5)
    AudioManager.play_sfx("hit", 0.7)
    get_tree().create_timer(60.0).timeout.connect(_respawn)


func _respawn():
    dead = false
    mesh.visible = true
    cs.set_deferred("disabled", false)
