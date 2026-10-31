extends CharacterBody3D
## Босс: пробуждение, 3 фазы, атаки (удар по площади, рывок, залп, нова), награды.
## Удары по площади не задевают игрока, который в прыжке или в рывке-уклонении.

const Fx = preload("res://scripts/vfx/fx.gd")
const Projectile = preload("res://scripts/enemies/projectile.gd")

var data = {}
var hp = 100.0
var max_hp = 100.0
var dead = false
var hit_radius = 2.0
var state = "dormant"
var st_t = 0.0
var atk_cd = 2.0
var phase = 1
var phase_speed = 1.0
var home = Vector3.ZERO
var mesh_root
var mat
var tele
var charge_dir = Vector3.ZERO
var charge_hit = false
var flash = 0.0
var orbit = []
var _t = 0.0


func setup(d, origin):
    data = d
    max_hp = float(d.hp)
    hp = max_hp
    hit_radius = d.scale * 0.9
    home = origin + Vector3(d.pos.x, 0, d.pos.y)
    position = home + Vector3(0, 1.0, 0)


func _ready():
    add_to_group("bosses")
    var cs = CollisionShape3D.new()
    var sh = CapsuleShape3D.new()
    sh.radius = data.scale * 0.7
    sh.height = data.scale * 2.0
    cs.shape = sh
    cs.position = Vector3(0, data.scale, 0)
    add_child(cs)
    mesh_root = Node3D.new()
    add_child(mesh_root)
    _build_visual()
    mesh_root.scale = Vector3.ONE * data.scale
    tele = MeshInstance3D.new()
    var cm = CylinderMesh.new()
    cm.top_radius = 1.0
    cm.bottom_radius = 1.0
    cm.height = 0.05
    cm.radial_segments = 32
    var tm = StandardMaterial3D.new()
    tm.albedo_color = Color(1, 0.1, 0.1, 0.35)
    tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    cm.material = tm
    tele.mesh = cm
    tele.top_level = true
    tele.visible = false
    add_child(tele)


func _m(color, emit = 0.0):
    var m = StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.6
    if emit > 0.0:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = emit
    return m


func _p(mesh, material, pos, scl = Vector3.ONE, rot = Vector3.ZERO):
    var mi = MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = material
    mi.position = pos
    mi.scale = scl
    mi.rotation = rot
    mesh_root.add_child(mi)
    return mi


func _sph(r = 0.5):
    var s = SphereMesh.new()
    s.radius = r
    s.height = r * 2.0
    s.radial_segments = 16
    s.rings = 8
    return s


func _box(x, y, z):
    var b = BoxMesh.new()
    b.size = Vector3(x, y, z)
    return b


func _cone(r, h):
    var c = CylinderMesh.new()
    c.top_radius = 0.0
    c.bottom_radius = r
    c.height = h
    c.radial_segments = 8
    return c


func _cyl(r, h):
    var c = CylinderMesh.new()
    c.top_radius = r
    c.bottom_radius = r
    c.height = h
    c.radial_segments = 12
    return c


func _build_visual():
    var col = data.color
    mat = _m(col, 0.15)
    mat.emission = Color(1, 0.2, 0.2)
    mat.emission_energy_multiplier = 0.0
    var dark = _m(col.darkened(0.4))
    var glow = _m(Color("ffee66"), 3.0)
    var gold = _m(Color("ffd24a"), 0.8)
    var eye_pos = [Vector3(-0.2, 1.1, 0.45), Vector3(0.2, 1.1, 0.45)]
    match data.id:
        "forest_guardian":
            _p(_cyl(0.45, 1.8), dark, Vector3(0, 0.9, 0))
            for i in 6:
                var a = i * 1.05
                _p(_sph(0.45), mat, Vector3(cos(a) * 0.5, 1.9 + (i % 2) * 0.3, sin(a) * 0.5))
            _p(_cyl(0.12, 1.4), dark, Vector3(0.65, 1.0, 0), Vector3.ONE, Vector3(0, 0, -0.5))
            _p(_cyl(0.12, 1.4), dark, Vector3(-0.65, 1.0, 0), Vector3.ONE, Vector3(0, 0, 0.5))
        "skeleton_king":
            _p(_sph(0.4), mat, Vector3(0, 1.8, 0))
            for i in 4:
                _p(_box(0.9 - i * 0.12, 0.1, 0.35), mat, Vector3(0, 1.1 - i * 0.2, 0))
            _p(_cyl(0.06, 1.4), mat, Vector3(0, 0.6, 0))
            for s in [-1, 1]:
                _p(_cyl(0.07, 1.0), mat, Vector3(0.55 * s, 1.0, 0))
                _p(_cone(0.12, 0.35), gold, Vector3(0.18 * s, 2.35, 0))
            _p(_cone(0.12, 0.35), gold, Vector3(0, 2.4, 0))
            eye_pos = [Vector3(-0.15, 1.85, 0.34), Vector3(0.15, 1.85, 0.34)]
        "ice_titan":
            _p(_box(1.2, 1.1, 0.9), mat, Vector3(0, 0.6, 0))
            _p(_box(1.0, 0.9, 0.8), mat, Vector3(0, 1.6, 0))
            _p(_box(0.6, 0.6, 0.6), mat, Vector3(0, 2.3, 0))
            for s in [-1, 1]:
                _p(_cone(0.15, 0.8), dark, Vector3(0.35 * s, 2.8, 0))
                _p(_box(0.4, 1.2, 0.4), mat, Vector3(0.85 * s, 1.5, 0))
            eye_pos = [Vector3(-0.15, 2.35, 0.32), Vector3(0.15, 2.35, 0.32)]
        "cursed_dumpling":
            _p(_sph(1.0), mat, Vector3(0, 1.0, 0), Vector3(1.3, 0.9, 1.0))
            for i in 7:
                var x = lerpf(-0.95, 0.95, i / 6.0)
                _p(_sph(0.18), dark, Vector3(x, 1.0 + 0.9 * sqrt(maxf(0.0, 1.0 - pow(x / 1.3, 2.0))), 0), Vector3(1, 1.5, 1.2))
            eye_pos = [Vector3(-0.35, 1.1, 0.8), Vector3(0.35, 1.1, 0.8)]
        "fire_dragon":
            _p(_sph(0.8), mat, Vector3(0, 1.0, 0), Vector3(1, 0.9, 1.4))
            _p(_sph(0.45), mat, Vector3(0, 1.6, 0.9))
            for s in [-1, 1]:
                _p(_sph(1.0), dark, Vector3(1.0 * s, 1.5, -0.2), Vector3(1.2, 0.08, 0.8), Vector3(0, 0, 0.4 * s))
                _p(_cone(0.12, 0.5), gold, Vector3(0.22 * s, 2.1, 0.8))
            _p(_cone(0.3, 1.6), mat, Vector3(0, 0.8, -1.4), Vector3.ONE, Vector3(1.9, 0, 0))
            eye_pos = [Vector3(-0.2, 1.7, 1.25), Vector3(0.2, 1.7, 1.25)]
        "ancient_guard":
            _p(_box(1.1, 1.4, 0.8), mat, Vector3(0, 1.0, 0))
            _p(_box(0.7, 0.6, 0.6), dark, Vector3(0, 2.0, 0))
            for s in [-1, 1]:
                _p(_box(0.35, 1.2, 0.35), dark, Vector3(0.8 * s, 1.1, 0))
            for i in 3:
                _p(_box(0.5, 0.06, 0.02), glow, Vector3(0, 0.7 + i * 0.35, 0.41))
            eye_pos = [Vector3(-0.15, 2.05, 0.31), Vector3(0.15, 2.05, 0.31)]
        "sky_golem":
            _p(_sph(0.8), mat, Vector3(0, 1.2, 0))
            _p(_sph(0.4), dark, Vector3(0, 2.2, 0))
            for i in 4:
                var o = _p(_sph(0.3), dark, Vector3(1.6, 1.2, 0))
                orbit.append({"n": o, "a": i * TAU / 4.0})
            eye_pos = [Vector3(-0.15, 2.25, 0.35), Vector3(0.15, 2.25, 0.35)]
        "cosmic_beast":
            _p(_sph(0.9), mat, Vector3(0, 1.0, 0), Vector3(1, 0.9, 1.3))
            for i in 7:
                var a2 = i * TAU / 7.0
                _p(_cone(0.12, 0.6), glow, Vector3(cos(a2) * 0.7, 1.7, sin(a2) * 0.7 - 0.2), Vector3.ONE, Vector3(sin(a2) * 0.5, 0, -cos(a2) * 0.5))
            for i in 5:
                _p(_sph(0.09), glow, Vector3(-0.4 + i * 0.2, 1.3 + (i % 2) * 0.15, 1.1))
            eye_pos = [Vector3(-0.25, 1.1, 1.1), Vector3(0.25, 1.1, 1.1)]
        "shadow_lord":
            _p(_cone(1.1, 2.4), mat, Vector3(0, 1.2, 0))
            _p(_sph(0.4), dark, Vector3(0, 2.6, 0))
            for s in [-1, 1]:
                _p(_cone(0.1, 0.7), dark, Vector3(0.28 * s, 3.1, 0), Vector3.ONE, Vector3(0, 0, -0.3 * s))
            eye_pos = [Vector3(-0.15, 2.65, 0.34), Vector3(0.15, 2.65, 0.34)]
        "egg_king":
            _p(_sph(1.0), mat, Vector3(0, 1.4, 0), Vector3(1, 1.35, 1))
            for i in 7:
                var a3 = i * TAU / 7.0
                _p(_cone(0.14, 0.55), gold, Vector3(cos(a3) * 0.5, 2.9, sin(a3) * 0.5))
            for i in 4:
                var o2 = _p(_sph(0.28), _m(Color("ff9ed0"), 1.0), Vector3(1.8, 1.4, 0), Vector3(1, 1.3, 1))
                orbit.append({"n": o2, "a": i * TAU / 4.0})
            eye_pos = [Vector3(-0.3, 1.6, 0.9), Vector3(0.3, 1.6, 0.9)]
        _:
            _p(_sph(0.9), mat, Vector3(0, 1.0, 0))
    for ep in eye_pos:
        _p(_sph(0.09), glow, ep)


func _engage():
    state = "intro"
    st_t = 2.0
    atk_cd = 1.5
    GameState.boss_fights += 1
    GameState.boss_music.emit(true)
    GameState.boss_bar.emit(data.name, hp, max_hp, true)
    GameState.message.emit("%s пробуждается!" % data.name)
    AudioManager.play_sfx("roar")
    Fx.shake(get_tree(), 0.3)
    Fx.vibrate(150)
    mesh_root.scale = Vector3.ONE * data.scale * 0.3
    var tw = create_tween()
    tw.tween_property(mesh_root, "scale", Vector3.ONE * data.scale, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _reset():
    if state != "dormant":
        GameState.boss_fights = maxi(0, GameState.boss_fights - 1)
        if GameState.boss_fights == 0:
            GameState.boss_music.emit(false)
        GameState.boss_bar.emit(data.name, hp, max_hp, false)
    state = "dormant"
    hp = max_hp
    phase = 1
    phase_speed = 1.0
    tele.visible = false
    position = home + Vector3(0, 1.0, 0)
    velocity = Vector3.ZERO


func hit(amount, crit, from):
    if dead:
        return
    if state == "dormant":
        _engage()
    hp -= amount
    flash = 0.15
    Fx.damage_number(get_parent(), global_position + Vector3(0, data.scale * 2.2, 0), str(int(amount)) + ("!" if crit else ""), Color("ffd24a") if crit else Color.WHITE, crit)
    Fx.burst(get_parent(), global_position + Vector3(0, data.scale, 0), Color("ffe9a0"), 8, 4.0, 0.4)
    AudioManager.play_sfx("crit" if crit else "hit", 0.7)
    GameState.boss_bar.emit(data.name, hp, max_hp, true)
    var r = hp / max_hp
    if phase == 1 and r < 0.66:
        _next_phase(2)
    elif phase == 2 and r < 0.33:
        _next_phase(3)
    if hp <= 0.0:
        _die()


func _next_phase(n):
    phase = n
    phase_speed = 1.0 + 0.25 * (n - 1)
    GameState.message.emit("%s: фаза %d!" % [data.name, n])
    GameState.screen_flash.emit(Color(1, 0.3, 0.3, 0.4), 0.4)
    AudioManager.play_sfx("roar", 1.2)
    Fx.shake(get_tree(), 0.25)
    Fx.shockwave(get_parent(), global_position, Color("ff5a5a"), 10.0, 0.6)


func _die():
    dead = true
    state = "dead"
    remove_from_group("bosses")
    tele.visible = false
    GameState.boss_fights = maxi(0, GameState.boss_fights - 1)
    if GameState.boss_fights == 0:
        GameState.boss_music.emit(false)
    GameState.boss_bar.emit(data.name, 0, max_hp, false)
    GameState.boss_defeated(data.id)
    GameState.gain_coins(data.coins)
    GameState.gain_xp(data.xp)
    GameState.gems += data.gems
    GameState.crystals += data.crystals
    GameState.add_egg(data.egg, 1)
    GameState.currency_changed.emit()
    GameState.message.emit("%s повержен! +%d монет, +%d самоцв., +%d кристаллов" % [data.name, data.coins, data.gems, data.crystals])
    AudioManager.play_sfx("boom")
    AudioManager.play_sfx("reward")
    GameState.screen_flash.emit(Color(1, 1, 1, 0.8), 0.8)
    Fx.shake(get_tree(), 0.4)
    Fx.vibrate(200)
    GameState.cinematic.emit(global_position + Vector3(0, data.scale, 0), data.scale * 4.0 + 4.0, -0.2, 3.0)
    var pl = GameState.player_node
    if pl != null:
        pl.play_victory()
    for i in 6:
        get_tree().create_timer(i * 0.35).timeout.connect(_death_burst)
    var tw = create_tween()
    tw.set_parallel(true)
    tw.tween_property(mesh_root, "scale", Vector3.ZERO, 2.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tw.tween_property(mesh_root, "rotation:y", TAU * 2, 2.4)
    tw.chain().tween_callback(queue_free)
    if data.id == "egg_king":
        GameState.game_won = true
        GameState.victory.emit()


func _death_burst():
    if is_instance_valid(self) and is_inside_tree():
        var p = global_position + Vector3(randf_range(-1, 1), randf_range(0.5, data.scale * 2.0), randf_range(-1, 1)) * data.scale * 0.6
        Fx.burst(get_parent(), p, Color("ffd24a"), 24, 8.0, 0.9, 0.15)
        AudioManager.play_sfx("boom", randf_range(0.8, 1.3))


func _tele_show(pos, radius):
    tele.visible = true
    tele.global_position = Vector3(pos.x, 0.12, pos.z)
    tele.scale = Vector3(radius, 1, radius)


func _pick_attack():
    var opts = ["slam", "charge"]
    if phase >= 2:
        opts.append("volley")
    if phase >= 3:
        opts.append("nova")
    var a = opts[randi() % opts.size()]
    match a:
        "slam":
            state = "slam"
            st_t = 1.0 / phase_speed
        "charge":
            state = "charge_wind"
            st_t = 0.7 / phase_speed
        "volley":
            state = "volley"
            st_t = 0.6 / phase_speed
        "nova":
            state = "nova"
            st_t = 1.5 / phase_speed


func _slam_radius():
    return 4.0 + data.scale * 1.3


func _hurt_if_grounded(radius, mult):
    var pl = GameState.player_node
    if pl == null or pl.dead:
        return
    var d = Vector2(pl.global_position.x - global_position.x, pl.global_position.z - global_position.z).length()
    if d < radius and pl.global_position.y < 1.4:
        pl.take_damage(data.dmg * mult, global_position)


func _physics_process(delta):
    if dead:
        return
    _t += delta
    for o in orbit:
        o.a += delta * 1.5
        o.n.position = Vector3(cos(o.a) * 1.7, 1.3 + sin(o.a * 2.0) * 0.3, sin(o.a) * 1.7)
    var pl = GameState.player_node
    if pl == null:
        return
    var to = pl.global_position - global_position
    to.y = 0
    var dist = to.length()
    if state == "dormant":
        if dist < 36.0 and not pl.dead and not GameState.in_menu:
            _engage()
        return
    if not is_on_floor():
        velocity.y -= 25.0 * delta
    flash = maxf(0.0, flash - delta)
    mat.emission_energy_multiplier = flash * 8.0
    if pl.dead or dist > 95.0:
        _reset()
        return
    atk_cd -= delta
    var want = Vector3.ZERO
    var face = to
    match state:
        "intro":
            st_t -= delta
            if st_t <= 0.0:
                state = "chase"
        "chase":
            want = to.normalized() * data.speed * phase_speed * (0.4 if dist < data.scale * 1.5 else 1.0)
            if atk_cd <= 0.0:
                _pick_attack()
        "slam":
            st_t -= delta
            var r = _slam_radius()
            _tele_show(global_position, r * (1.0 - clampf(st_t * phase_speed, 0.0, 1.0) * 0.6))
            if st_t <= 0.0:
                tele.visible = false
                _hurt_if_grounded(r, 1.0)
                Fx.shockwave(get_parent(), global_position, Color("ff8a3a"), r, 0.5)
                Fx.shake(get_tree(), 0.2)
                AudioManager.play_sfx("boom")
                state = "chase"
                atk_cd = 2.2 / phase_speed
        "charge_wind":
            st_t -= delta
            mesh_root.position.x = sin(_t * 60.0) * 0.08
            if st_t <= 0.0:
                mesh_root.position.x = 0.0
                charge_dir = to.normalized()
                charge_hit = false
                state = "charging"
                st_t = 0.9
                AudioManager.play_sfx("roar", 1.4)
        "charging":
            st_t -= delta
            want = charge_dir * data.speed * 3.6
            face = charge_dir
            if not charge_hit and dist < data.scale + 1.2:
                charge_hit = true
                pl.take_damage(data.dmg * 1.2, global_position)
            if st_t <= 0.0:
                state = "stunned"
                st_t = 1.0
        "stunned":
            st_t -= delta
            if st_t <= 0.0:
                state = "chase"
                atk_cd = 1.5 / phase_speed
        "volley":
            st_t -= delta
            if st_t <= 0.0:
                var n = 5 if phase == 2 else 9
                for i in n:
                    var ang = lerpf(-0.6, 0.6, i / float(n - 1)) if n > 1 else 0.0
                    var pj = Projectile.new()
                    pj.dir = to.normalized().rotated(Vector3.UP, ang)
                    pj.dmg = data.dmg * 0.6
                    pj.color = data.color.lightened(0.3)
                    get_parent().add_child(pj)
                    pj.global_position = global_position + Vector3(0, data.scale * 1.2, 0)
                AudioManager.play_sfx("special", 0.6)
                state = "chase"
                atk_cd = 2.0 / phase_speed
        "nova":
            st_t -= delta
            var nr = 16.0
            _tele_show(global_position, nr * (1.0 - clampf(st_t * phase_speed / 1.5, 0.0, 1.0) * 0.7))
            if st_t <= 0.0:
                tele.visible = false
                _hurt_if_grounded(nr, 1.5)
                Fx.shockwave(get_parent(), global_position, Color("c060ff"), nr, 0.8)
                Fx.shake(get_tree(), 0.35)
                GameState.screen_flash.emit(Color(0.8, 0.4, 1, 0.3), 0.4)
                AudioManager.play_sfx("boom", 0.6)
                state = "chase"
                atk_cd = 2.5 / phase_speed
    velocity.x = lerpf(velocity.x, want.x, 1.0 - exp(-6.0 * delta))
    velocity.z = lerpf(velocity.z, want.z, 1.0 - exp(-6.0 * delta))
    if face.length() > 0.1 and state != "stunned":
        mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, atan2(face.x, face.z), 1.0 - exp(-5.0 * delta))
    move_and_slide()
