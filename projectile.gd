extends Node3D
## Снаряд босса: летит по прямой, проверяет расстояние до игрока (без физики).

var dir = Vector3.FORWARD
var speed = 14.0
var dmg = 10.0
var life = 4.0
var color = Color("c060ff")


func _ready():
    var mi = MeshInstance3D.new()
    var m = SphereMesh.new()
    m.radius = 0.35
    m.height = 0.7
    m.radial_segments = 10
    m.rings = 5
    var mat = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = 2.5
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.material = mat
    mi.mesh = m
    add_child(mi)


func _process(delta):
    life -= delta
    global_position += dir * speed * delta
    var pl = GameState.player_node
    if pl != null and not pl.dead and global_position.distance_to(pl.global_position + Vector3(0, 0.9, 0)) < 1.1:
        pl.take_damage(dmg, global_position - dir)
        queue_free()
        return
    if life <= 0.0 or global_position.y < 0.0:
        queue_free()
