extends Node3D
## Врата региона: открываются после победы над боссом региона за плату монетами.

const Fx = preload("res://scripts/vfx/fx.gd")
var region = 0
var barrier


func setup(r):
    region = r


func _mat(c, emit = 0.0, alpha = 1.0):
    var m = StandardMaterial3D.new()
    m.albedo_color = Color(c.r, c.g, c.b, alpha)
    if emit > 0.0:
        m.emission_enabled = true
        m.emission = c
        m.emission_energy_multiplier = emit
    if alpha < 1.0:
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    return m


func _box(size, mat, pos):
    var mi = MeshInstance3D.new()
    var b = BoxMesh.new()
    b.size = size
    mi.mesh = b
    mi.material_override = mat
    mi.position = pos
    add_child(mi)
    return mi


func _ready():
    add_to_group("interactables")
    var stone = _mat(Color("6a6a78"))
    _box(Vector3(1.2, 7, 1.2), stone, Vector3(0, 3.5, -4))
    _box(Vector3(1.2, 7, 1.2), stone, Vector3(0, 3.5, 4))
    _box(Vector3(1.4, 1.0, 9.6), stone, Vector3(0, 7.2, 0))
    barrier = _box(Vector3(0.2, 6.5, 7), _mat(Color("8a60ff"), 1.5, 0.45), Vector3(0, 3.3, 0))
    var l = Label3D.new()
    l.text = "Врата: %d монет" % GameData.REGIONS[region].gate_cost
    l.font_size = 64
    l.pixel_size = 0.012
    l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    l.position = Vector3(0, 8.6, 0)
    add_child(l)


func interact_prompt():
    var rd = GameData.REGIONS[region]
    if not GameState.defeated_bosses.has(rd.gate_boss):
        return "Врата закрыты: победите босса - " + GameData.boss(rd.gate_boss).name
    return "Открыть врата (%d монет)" % rd.gate_cost


func interact(_player):
    var rd = GameData.REGIONS[region]
    if not GameState.defeated_bosses.has(rd.gate_boss):
        GameState.message.emit("Сначала победите: " + GameData.boss(rd.gate_boss).name)
        AudioManager.play_sfx("error")
        return
    if not GameState.spend("coins", rd.gate_cost):
        GameState.message.emit("Нужно %d монет" % rd.gate_cost)
        AudioManager.play_sfx("error")
        return
    GameState.unlock_next_region()
    GameState.message.emit("Путь открыт: " + GameData.REGIONS[region + 1].name)
    AudioManager.play_sfx("levelup")
    GameState.screen_flash.emit(Color(0.8, 0.6, 1, 0.5), 0.6)
    Fx.burst(get_parent(), global_position + Vector3(0, 3, 0), Color("b080ff"), 40, 8.0, 1.0)
    remove_from_group("interactables")
    var tw = create_tween()
    tw.tween_property(self, "scale", Vector3(1, 0.01, 1), 1.0)
    tw.tween_callback(queue_free)
