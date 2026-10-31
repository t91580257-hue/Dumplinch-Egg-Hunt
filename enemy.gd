extends CharacterBody3D
## Обычный враг региона: бродит, преследует, бьёт по таймингу, возвращается домой.

const Fx = preload("res://scripts/vfx/fx.gd")
signal died(enemy)

var region = 0
var home = Vector3.ZERO
var max_hp = 50.0
var hp = 50.0
var dmg = 6.0
var dead = false
var hit_radius = 0.7
var state = "idle"
var st_t = 0.0
var wander_t = 0.0
var wander_dir = Vector3.ZERO
var speed = 3.5
var mesh_root
var mat
var bar_fill
var flash = 0.0
var _far = false
var _far_t = 0.0


func setup(r, h):
    region = r
    home = h
    max_hp = 45.0 * (1.0 + 1.1 * r)
    hp = max_hp
    dmg = 6.0 + 5.0 * r
    speed = 3.4 + 0.3 * r
    position = h + Vector3(0, 1.0, 0)


func _ready():
    add_to_group("enemies")
    var cs = CollisionShape3D.new()
    var sh = SphereShape3D.new()
    sh.radius = 0.6
    cs.shape = sh
    cs.position = Vector3(0, 0.6, 0)
    add_child(cs)
    mesh_root = Node3D.new()
    add_child(mesh_root)
    var cols = [Color("5acb58"), Color("e8f4ff"), Color("ff6a2a"), Color("e8f0ff"), Color("7a40c0")]
    var c = cols[region]
    mat = StandardMaterial3D.new()
    mat.albedo_color = c
    mat.roughness = 0.5
    mat.emission_enabled = true
    mat.emission = Color(1, 0.2, 0.2)
    mat.emission_energy_multiplier = 0.0
    if region == 4 or region == 2:
        mat.emission = c
        mat.emission_energy_multiplier = 0.0
    var body = MeshInstance3D.new()
    var sm = SphereMesh.new()
    sm.radius = 0.6
    sm.height = 1.2
    sm.radial_segments = 16
    sm.rings = 8
    body.mesh = sm
    body.material_override = mat
    body.position = Vector3(0, 0.6, 0)
    body.scale = Vector3(1.0, 0.85 if region == 0 else 1.0, 1.0)
    mesh_root.add_child(body)
    if region == 1:
        var head = MeshInstance3D.new()
        var hm = SphereMesh.new()
        hm.radius = 0.38
        hm.height = 0.76
        head.mesh = hm
        head.material_override = mat
        head.position = Vector3(0, 1.4, 0)
        mesh_root.add_child(head)
    if region == 2 or region == 4:
        for s in [-1, 1]:
            var horn = MeshInstance3D.new()
            var cm = CylinderMesh.new()
            cm.top_radius = 0.0
            cm.bottom_radius = 0.1
            cm.height = 0.4
            horn.mesh = cm
            horn.material_override = mat
            horn.position = Vector3(0.3 * s, 1.15, 0)
            horn.rotation.z = -0.4 * s
            mesh_root.add_child(horn)
    var eye_mat = StandardMaterial3D.new()
    eye_mat.albedo_color = Color("ffee66") if region >= 2 else Color("151515")
    eye_mat.emission_enabled = region >= 2
    eye_mat.emission = Color("ffee66")
    for s in [-1, 1]:
        var e = MeshInstance3D.new()
        var em = SphereMesh.new()
        em.radius = 0.08
        em.height = 0.16
        e.mesh = em
        e.material_override = eye_mat
        e.position = Vector3(0.2 * s, 0.75, 0.5)
        mesh_root.add_child(e)
    var bg = MeshInstance3D.new()
    var q = QuadMesh.new()
    q.size = Vector2(1.2, 0.14)
    bg.mesh = q
    var bgm = StandardMaterial3D.new()
    bgm.albedo_color = Color(0, 0, 0, 0.7)
    bgm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    bgm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    bgm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    bg.material_override = bgm
    bg.position = Vector3(0, 1.7, 0)
    add_child(bg)
    bar_fill = MeshInstance3D.new()
    var q2 = QuadMesh.new()
    q2.size = Vector2(1.16, 0.1)
    bar_fill.mesh = q2
    var fm = StandardMaterial3D.new()
    fm.albedo_color = Color("ff4a4a")
    fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    fm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    fm.no_depth_test = false
    bar_fill.material_override = fm
    bar_fill.position = Vector3(0, 1.7, 0.01)
    add_child(bar_fill)
    bar_fill.visible = false
    bg.visible = false
    bar_fill.set_meta("bg", bg)


func hit(amount, crit, from):
    if dead:
        return
    hp -= amount
    flash = 0.2
    var dir = global_position - from
    dir.y = 0
    if dir.length() > 0.01:
        velocity += dir.normalized() * 5.0
    Fx.damage_number(get_parent(), global_position + Vector3(0, 2.0, 0), str(int(amount)) + ("!" if crit else ""), Color("ffd24a") if crit else Color.WHITE, crit)
    Fx.burst(get_parent(), global_position + Vector3(0, 0.8, 0), Color("ffe9a0"), 8, 3.5, 0.35)
    AudioManager.play_sfx("crit" if crit else "hit", randf_range(0.9, 1.1))
    bar_fill.visible = true
    bar_fill.get_meta("bg").visible = true
    var ratio = clampf(hp / max_hp, 0.0, 1.0)
    bar_fill.scale.x = maxf(ratio, 0.001)
    bar_fill.position.x = -0.58 * (1.0 - ratio)
    if state == "idle":
        state = "chase"
    if hp <= 0.0:
        _die()


func _die():
    dead = true
    remove_from_group("enemies")
    GameState.record_kill()
    var coins = GameState.gain_coins(int(8 * (1 + region * 1.5)))
    GameState.gain_xp(int(12 * (1 + region)))
    if randf() < 0.05:
        var eid = GameData.REGIONS[region].eggs[0]
        GameState.add_egg(eid, 1)
        GameState.message.emit("Враг уронил яйцо: " + GameData.egg(eid).name)
    Fx.damage_number(get_parent(), global_position + Vector3(0, 2.4, 0), "+%d" % coins, Color("ffd24a"))
    Fx.burst(get_parent(), global_position + Vector3(0, 0.8, 0), Color("ffd24a"), 14, 5.0, 0.6)
    AudioManager.play_sfx("coin")
    died.emit(self)
    var tw = create_tween()
    tw.tween_property(mesh_root, "scale", Vector3.ZERO, 0.3)
    tw.tween_callback(queue_free)


func _physics_process(delta):
    if dead:
        return
    var pl = GameState.player_node
    if pl == null:
        return
    _far_t -= delta
    if _far_t <= 0.0:
        _far_t = 0.5
        _far = pl.global_position.distance_to(global_position) > 110.0
    if _far:
        return
    if not is_on_floor():
        velocity.y -= 25.0 * delta
    flash = maxf(0.0, flash - delta)
    mat.emission_energy_multiplier = flash * 6.0
    var to = pl.global_position - global_position
    to.y = 0
    var dist = to.length()
    var want = Vector3.ZERO
    match state:
        "idle":
            wander_t -= delta
            if wander_t <= 0.0:
                wander_t = randf_range(1.5, 4.0)
                wander_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() if randf() < 0.6 else Vector3.ZERO
            var back = home - global_position
            back.y = 0
            want = (back.normalized() if back.length() > 30.0 else wander_dir) * speed * 0.4
            if hp < max_hp:
                hp = minf(max_hp, hp + max_hp * 0.05 * delta)
            if dist < 14.0 and not pl.dead and not GameState.in_menu:
                state = "chase"
        "chase":
            want = to.normalized() * speed
            var hd = global_position - home
            hd.y = 0
            if dist < 1.9:
                state = "windup"
                st_t = 0.45
            elif dist > 32.0 or pl.dead or hd.length() > 55.0:
                state = "idle"
        "windup":
            st_t -= delta
            mesh_root.scale = Vector3.ONE * (1.0 + 0.2 * sin(st_t * 30.0))
            if st_t <= 0.0:
                mesh_root.scale = Vector3.ONE
                if dist < 2.5:
                    pl.take_damage(dmg, global_position)
                state = "recover"
                st_t = 1.0
        "recover":
            st_t -= delta
            if st_t <= 0.0:
                state = "chase"
    velocity.x = lerpf(velocity.x, want.x, 1.0 - exp(-8.0 * delta))
    velocity.z = lerpf(velocity.z, want.z, 1.0 - exp(-8.0 * delta))
    if Vector2(velocity.x, velocity.z).length() > 0.3:
        mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, atan2(velocity.x, velocity.z), 1.0 - exp(-10.0 * delta))
    move_and_slide()
