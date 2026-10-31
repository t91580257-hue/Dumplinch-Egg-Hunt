extends Node3D
## Открытие яиц: кинематографическая камера, вращение, свечение, тряска, трещины, вспышка, питомец.
## Быстрое открытие и открытие пачкой показывают короткую анимацию и список результатов.

const EggBuilder = preload("res://scripts/pets/egg_builder.gd")
const PetBuilder = preload("res://scripts/pets/pet_builder.gd")
const Fx = preload("res://scripts/vfx/fx.gd")

var busy = false
var hud = null


func _ready():
    GameState.request_open_egg.connect(begin)


func _wait(sec):
    await get_tree().create_timer(sec).timeout


func begin(egg_id, count):
    if busy or GameState.eggs.get(egg_id, 0) < count:
        return
    var pl = GameState.player_node
    if pl == null or pl.dead:
        return
    if hud != null:
        hud.close_all()
    busy = true
    GameState.cinematic_busy = true
    var results = []
    for i in count:
        var p = GameState.open_egg(egg_id)
        if p != null:
            results.append(p)
    var e = GameData.egg(egg_id)
    var fast = bool(GameState.settings.get("fast_open", false)) or count > 1
    await _play(e, results, fast, pl)
    if fast and hud != null:
        hud.reveal_window.show_results(results)
    elif results.size() == 1:
        GameState.reveal_pet.emit(results[0])
    SaveSystem.save_game()
    GameState.cinematic_busy = false
    busy = false


func _play(e, results, fast, pl):
    pl.set_busy(true, "open_egg")
    var fwd = Vector3(sin(pl.vis.rotation.y), 0, cos(pl.vis.rotation.y))
    var pos = pl.global_position + fwd * 3.0 + Vector3(0, 1.5, 0)
    GameState.cinematic.emit(pos, 4.5, -0.12, 1.2 if fast else 7.0)
    var egg = EggBuilder.build_egg(e, 1.5)
    add_child(egg)
    egg.global_position = pos
    egg.scale = Vector3.ONE * 0.05
    var tw = create_tween()
    tw.tween_property(egg, "scale", Vector3.ONE * 1.5, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    AudioManager.play_sfx("pop", 0.8)
    await tw.finished
    var shakes = 2 if fast else 7
    var mat = EggBuilder.glow_material(egg)
    var spin = create_tween()
    spin.tween_property(egg, "rotation:y", TAU * (1 if fast else 3), 0.6 if fast else 1.3)
    if not fast:
        spin.parallel().tween_property(mat, "emission_energy_multiplier", 2.5, 1.3)
    await spin.finished
    var crack_mat = StandardMaterial3D.new()
    crack_mat.albedo_color = Color(0.05, 0.03, 0.02)
    crack_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    for i in shakes:
        AudioManager.play_sfx("shake", 0.8 + i * 0.07)
        Fx.vibrate(30)
        var sh = create_tween()
        var dir = 1.0 if i % 2 == 0 else -1.0
        sh.tween_property(egg, "rotation:z", 0.3 * dir, 0.09)
        sh.tween_property(egg, "rotation:z", -0.3 * dir, 0.09)
        sh.tween_property(egg, "rotation:z", 0.0, 0.07)
        if not fast and i % 2 == 1:
            _add_crack(egg, crack_mat)
        mat.emission_energy_multiplier += 0.5
        await sh.finished
    GameState.screen_flash.emit(Color(1, 1, 1, 0.95), 0.6)
    AudioManager.play_sfx("crack")
    Fx.shake(get_tree(), 0.3)
    Fx.vibrate(120)
    Fx.burst(self, pos, e.accent, 30, 7.0, 0.9, 0.1)
    Fx.shockwave(self, pos - Vector3(0, 1.4, 0), e.accent, 4.0, 0.5)
    egg.queue_free()
    if results.size() == 1 and not fast:
        var d = GameData.pet(results[0].id)
        var pet = PetBuilder.build_pet(d, 0)
        add_child(pet)
        pet.global_position = pos - Vector3(0, 0.6, 0)
        pet.scale = Vector3.ONE * 0.05
        var pt = create_tween()
        pt.tween_property(pet, "scale", Vector3.ONE * 1.4, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        AudioManager.play_sfx("pet", d.pitch)
        Fx.burst(self, pos, GameData.rarity_color(d.rarity), 36, 6.0, 1.0, 0.1)
        GameState.reveal_pet.emit(results[0])
        await _wait(3.0)
        pet.queue_free()
    else:
        await _wait(0.5)
    GameState.cinematic.emit(pl.global_position, 7.5, -0.35, 0.01)
    pl.set_busy(false)


func _add_crack(egg, mat):
    var mi = MeshInstance3D.new()
    var bm = BoxMesh.new()
    bm.size = Vector3(0.025, 0.3, 0.025)
    mi.mesh = bm
    mi.material_override = mat
    var a = randf() * TAU
    var h = randf_range(-0.3, 0.4)
    var r = 0.5 * sqrt(maxf(0.05, 1.0 - pow(h / 0.675, 2.0))) + 0.01
    mi.position = Vector3(cos(a) * r, h, sin(a) * r)
    mi.rotation = Vector3(0, -a + PI / 2.0, randf_range(-0.6, 0.6))
    egg.add_child(mi)
