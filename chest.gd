extends Node3D
## Секретный сундук: даёт монеты, иногда самоцветы, кристаллы или яйцо. Открытые сундуки сохраняются.

const Fx = preload("res://scripts/vfx/fx.gd")
var chest_id = ""
var region = 0
var opened = false
var lid


func setup(id, r):
    chest_id = id
    region = r
    opened = GameState.opened_chests.has(id)


func _mat(c, emit = 0.0):
    var m = StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 0.7
    if emit > 0.0:
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = emit
    return m


func _box(parent, size, mat, pos):
    var mi = MeshInstance3D.new()
    var b = BoxMesh.new()
    b.size = size
    mi.mesh = b
    mi.material_override = mat
    mi.position = pos
    parent.add_child(mi)
    return mi


func _ready():
    var wood = _mat(Color("8a5a2a"))
    var gold = _mat(Color("ffd24a"), 0.6)
    _box(self, Vector3(1.0, 0.6, 0.7), wood, Vector3(0, 0.3, 0))
    _box(self, Vector3(1.04, 0.1, 0.74), gold, Vector3(0, 0.45, 0))
    lid = Node3D.new()
    lid.position = Vector3(0, 0.6, -0.35)
    add_child(lid)
    _box(lid, Vector3(1.0, 0.25, 0.7), wood, Vector3(0, 0.12, 0.35))
    _box(lid, Vector3(0.12, 0.28, 0.74), gold, Vector3(0, 0.12, 0.35))
    if opened:
        lid.rotation.x = -1.8
    else:
        add_to_group("interactables")


func interact_prompt():
    return "" if opened else "Открыть сундук"


func interact(_player):
    if opened:
        return
    opened = true
    remove_from_group("interactables")
    GameState.record_chest(chest_id)
    var coins = GameState.gain_coins(60 * (region + 1) + randi() % 80)
    var msg = "Сундук: +%d монет" % coins
    if randf() < 0.4:
        var g = randi_range(1, 3)
        GameState.gems += g
        msg += ", +%d самоцв." % g
    if randf() < 0.2:
        GameState.crystals += 1
        msg += ", +1 кристалл"
    if randf() < 0.12:
        var eid = GameData.REGIONS[region].eggs[0]
        GameState.add_egg(eid, 1)
        msg += ", яйцо: " + GameData.egg(eid).name
    GameState.currency_changed.emit()
    GameState.message.emit(msg)
    AudioManager.play_sfx("reward")
    Fx.burst(get_parent(), global_position + Vector3(0, 0.8, 0), Color("ffd24a"), 24, 5.0, 0.9)
    create_tween().tween_property(lid, "rotation:x", -1.8, 0.4)
