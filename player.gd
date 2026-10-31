extends CharacterBody3D
## Dumplinch: управление, процедурная 3D-модель и анимации, бой.
## Анимации процедурные (без скелета): idle, walk, run, sprint, jump, fall, land,
## attack, special, damage, victory, defeat, open_egg, dance.

const ProcTex = preload("res://scripts/util/proc_tex.gd")
const Fx = preload("res://scripts/vfx/fx.gd")

const SPEEDS = {"walk": 3.5, "run": 6.0, "sprint": 9.0}
const JUMP_V = 8.8
const GRAVITY = 26.0
const ATTACK_DUR = 0.35
const SPECIAL_DUR = 0.7
const LAND_DUR = 0.2
const ACTIONS = ["attack", "jump", "special", "dodge", "interact", "pets", "dance"]

var vis
var body_root
var body_mat
var hat_mat
var foot_l
var foot_r
var arm_l
var arm_r
var anim_state = "idle"
var anim_t = 0.0
var _sy = 1.0
var _sxz = 1.0
var _bob = 0.0
var _tilt = 0.0
var _roll = 0.0
var _foot = 0.0
var _arm = 0.0
var attack_t = 0.0
var attack_cd = 0.0
var attack_hit_done = true
var special_t = 0.0
var special_cd = 0.0
var special_hit_done = true
var dodge_t = 0.0
var dodge_cd = 0.0
var dodge_dir = Vector3.FORWARD
var iframes = 0.0
var hurt_t = 0.0
var landed_t = 0.0
var dead = false
var busy = false
var busy_anim = "open_egg"
var victory_t = 0.0
var idle_time = 0.0
var dance_on = false
var coyote = 0.0
var prev_vy = 0.0
var step_t = 0.0
var in_lava = 0
var lava_tick = 0.0
var pets_cd = 0.0
var interact_target = null
var _scan_t = 0.0
var respawn_pos = Vector3(0, 1.5, 10)
var _block_t = 0.0
var _prev = {}


func _ready():
    add_to_group("player")
    GameState.player_node = self
    var cs = CollisionShape3D.new()
    var cap = CapsuleShape3D.new()
    cap.radius = 0.5
    cap.height = 1.6
    cs.shape = cap
    cs.position = Vector3(0, 0.8, 0)
    add_child(cs)
    _build_model()
    apply_cosmetic()
    GameState.settings_changed.connect(apply_cosmetic)
    GameState.hp = GameState.max_hp()


func _part(parent, mesh, mat, pos, scl = Vector3.ONE):
    var mi = MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = mat
    mi.position = pos
    mi.scale = scl
    parent.add_child(mi)
    return mi


func _sphere(r = 0.5, seg = 20):
    var m = SphereMesh.new()
    m.radius = r
    m.height = r * 2.0
    m.radial_segments = seg
    m.rings = seg / 2
    return m


func _flat(color, rough = 0.8):
    var m = StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = rough
    return m


func _build_model():
    vis = Node3D.new()
    add_child(vis)
    body_root = Node3D.new()
    body_root.position = Vector3(0, 0.62, 0)
    vis.add_child(body_root)
    body_mat = StandardMaterial3D.new()
    body_mat.albedo_color = Color("f6e3c2")
    body_mat.albedo_texture = ProcTex.noise_texture(Color("ebd3a8"), Color("fff1d8"), 64, 0.09, 7)
    body_mat.roughness = 0.85
    body_mat.emission_enabled = true
    body_mat.emission = Color(1, 0.15, 0.15)
    body_mat.emission_energy_multiplier = 0.0
    _part(body_root, _sphere(0.5), body_mat, Vector3.ZERO, Vector3(1.3, 0.9, 1.05))
    var pleat = _flat(Color("e2c898"))
    for i in 7:
        var x = lerpf(-0.5, 0.5, i / 6.0)
        var y = 0.45 * sqrt(maxf(0.0, 1.0 - pow(x / 0.65, 2.0)))
        _part(body_root, _sphere(0.09, 10), pleat, Vector3(x, y, 0.0), Vector3(1.0, 1.5, 1.2))
    var eye = _flat(Color("141414"), 0.2)
    for s in [-1, 1]:
        _part(body_root, _sphere(0.07, 10), eye, Vector3(0.2 * s, 0.1, 0.47), Vector3(1, 1.3, 0.7))
        _part(body_root, _sphere(0.07, 8), _flat(Color("ff9ab0")), Vector3(0.36 * s, -0.05, 0.4), Vector3(1.2, 0.8, 0.5))
    hat_mat = _flat(Color("e04a3a"))
    var cone = CylinderMesh.new()
    cone.top_radius = 0.0
    cone.bottom_radius = 0.3
    cone.height = 0.45
    var hat = _part(body_root, cone, hat_mat, Vector3(0, 0.68, -0.02))
    hat.rotation.x = -0.12
    _part(hat, _sphere(0.07, 8), _flat(Color.WHITE), Vector3(0, 0.25, 0))
    var brim = CylinderMesh.new()
    brim.top_radius = 0.34
    brim.bottom_radius = 0.34
    brim.height = 0.05
    _part(hat, brim, hat_mat, Vector3(0, -0.22, 0))
    var foot_mat = _flat(Color("6b4a2f"))
    foot_l = _part(vis, _sphere(0.13, 10), foot_mat, Vector3(-0.25, 0.1, 0.1), Vector3(1, 0.6, 1.4))
    foot_r = _part(vis, _sphere(0.13, 10), foot_mat, Vector3(0.25, 0.1, 0.1), Vector3(1, 0.6, 1.4))
    arm_l = _part(body_root, _sphere(0.1, 10), body_mat, Vector3(-0.7, 0.0, 0.05))
    arm_r = _part(body_root, _sphere(0.1, 10), body_mat, Vector3(0.7, 0.0, 0.05))


func apply_cosmetic():
    var c = GameData.COSMETICS.get(GameState.cosmetic, GameData.COSMETICS["default"])
    hat_mat.albedo_color = c.color


func cd_frac(action):
    match action:
        "attack": return clampf(attack_cd / 0.45, 0.0, 1.0)
        "special": return clampf(special_cd / 8.0, 0.0, 1.0)
        "dodge": return clampf(dodge_cd / 1.2, 0.0, 1.0)
        "pets": return clampf(pets_cd / 15.0, 0.0, 1.0)
    return 0.0


func _just(a):
    var cur = Input.is_action_pressed(a)
    var was = _prev.get(a, false)
    _prev[a] = cur
    var latched = GameState.latched.get(a, false)
    GameState.latched[a] = false
    return (cur and not was) or latched


func set_busy(b, anim = "open_egg"):
    busy = b
    busy_anim = anim


func play_victory():
    victory_t = 3.2


func _physics_process(delta):
    var j_attack = _just("attack")
    var j_jump = _just("jump")
    var j_special = _just("special")
    var j_dodge = _just("dodge")
    var j_interact = _just("interact")
    var j_pets = _just("pets")
    var j_dance = _just("dance")
    attack_cd = maxf(0.0, attack_cd - delta)
    special_cd = maxf(0.0, special_cd - delta)
    dodge_cd = maxf(0.0, dodge_cd - delta)
    pets_cd = maxf(0.0, pets_cd - delta)
    iframes = maxf(0.0, iframes - delta)
    hurt_t = maxf(0.0, hurt_t - delta)
    landed_t = maxf(0.0, landed_t - delta)
    victory_t = maxf(0.0, victory_t - delta)
    _block_t = maxf(0.0, _block_t - delta)
    attack_t = maxf(0.0, attack_t - delta)
    special_t = maxf(0.0, special_t - delta)
    dodge_t = maxf(0.0, dodge_t - delta)
    var controllable = not (GameState.in_menu or dead or busy)
    var move = Vector2.ZERO
    var touch_used = false
    if controllable:
        move = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
        var tm = GameState.touch_move
        if tm.length() > move.length():
            move = tm
            touch_used = true
        move = move.limit_length(1.0)
    var dir = Vector3(move.x, 0, move.y).rotated(Vector3.UP, GameState.cam_yaw)
    var mag = move.length()
    var mode = "run"
    if touch_used:
        mode = "sprint" if mag > 0.93 else ("run" if mag > 0.45 else "walk")
    elif Input.is_action_pressed("sprint"):
        mode = "sprint"
    var speed = SPEEDS[mode] * GameState.speed_mult()
    if attack_t > 0.0 or special_t > 0.0:
        speed *= 0.45
    if dodge_t > 0.0:
        velocity.x = dodge_dir.x * 16.0
        velocity.z = dodge_dir.z * 16.0
    else:
        var tgt = dir * speed if mag > 0.05 else Vector3.ZERO
        var accel = 32.0 if mag > 0.05 else 45.0
        velocity.x = move_toward(velocity.x, tgt.x, accel * delta)
        velocity.z = move_toward(velocity.z, tgt.z, accel * delta)
    if is_on_floor():
        coyote = 0.12
    else:
        coyote -= delta
        velocity.y -= GRAVITY * delta
    if controllable:
        if j_jump and coyote > 0.0:
            velocity.y = JUMP_V
            coyote = 0.0
            AudioManager.play_sfx("jump")
        if j_attack and attack_cd <= 0.0 and special_t <= 0.0:
            _start_attack()
        if j_special and special_cd <= 0.0:
            _start_special()
        if j_dodge and dodge_cd <= 0.0:
            _start_dodge(dir)
        if j_pets and pets_cd <= 0.0:
            pets_cd = 15.0
            get_tree().call_group("pet_manager", "call_pets")
            AudioManager.play_sfx("pet")
        if j_interact and interact_target != null and is_instance_valid(interact_target):
            interact_target.interact(self)
        if j_dance:
            dance_on = not dance_on
        if mag > 0.05 or j_attack or j_jump:
            dance_on = false
            idle_time = 0.0
    _combat_ticks()
    prev_vy = velocity.y
    var was_floor = is_on_floor()
    move_and_slide()
    if is_on_floor() and not was_floor and prev_vy < -7.0:
        landed_t = LAND_DUR
        AudioManager.play_sfx("step", 0.7)
    _limit_world()
    var hv = Vector2(velocity.x, velocity.z)
    if hv.length() > 0.6 and dodge_t <= 0.0 and controllable:
        vis.rotation.y = lerp_angle(vis.rotation.y, atan2(velocity.x, velocity.z), clampf(14.0 * delta, 0.0, 1.0))
    if is_on_floor() and hv.length() > 1.0:
        step_t -= delta * hv.length() / 6.0
        if step_t <= 0.0:
            step_t = 0.45
            AudioManager.play_sfx("step", randf_range(0.8, 1.2))
    if in_lava > 0 and not dead:
        lava_tick -= delta
        if lava_tick <= 0.0:
            lava_tick = 0.5
            iframes = 0.0
            take_damage(6.0 + GameState.current_region * 3.0, global_position + Vector3(0.2, 0, 0.2))
    _scan_t -= delta
    if _scan_t <= 0.0:
        _scan_t = 0.15
        _scan_interactables()
    var reg = GameData.region_of_x(global_position.x)
    if reg != GameState.current_region:
        GameState.current_region = reg
        respawn_pos = GameData.region_origin(reg) + Vector3(0, 1.5, 10)
        GameState.region_changed.emit(reg)
    if anim_state == "idle" and controllable:
        idle_time += delta
        if idle_time > 10.0:
            dance_on = true
    _pick_state()
    _animate(delta)


func _limit_world():
    var max_x = (GameState.unlocked_regions - 1) * GameData.REGION_SIZE + GameData.REGION_HALF - 2.0
    var p = global_position
    var nx = clampf(p.x, -GameData.REGION_HALF + 2.0, max_x)
    var nz = clampf(p.z, -GameData.REGION_HALF + 2.0, GameData.REGION_HALF - 2.0)
    if p.x > max_x - 0.01 and GameState.unlocked_regions < 5 and _block_t <= 0.0:
        _block_t = 4.0
        GameState.message.emit("Путь закрыт: победите босса региона и откройте врата")
    global_position = Vector3(nx, p.y, nz)


func _scan_interactables():
    var best = null
    var bd = 3.4
    for n in get_tree().get_nodes_in_group("interactables"):
        if not is_instance_valid(n):
            continue
        var d = n.global_position.distance_to(global_position)
        if d < bd and n.interact_prompt() != "":
            best = n
            bd = d
    interact_target = best
    GameState.prompt_changed.emit(best.interact_prompt() if best != null else "")


# ---------- Бой ----------
func _start_attack():
    attack_t = ATTACK_DUR
    attack_cd = 0.45
    attack_hit_done = false
    _auto_face(5.0)
    AudioManager.play_sfx("swing", randf_range(0.9, 1.2))


func _start_special():
    special_t = SPECIAL_DUR
    special_cd = 8.0
    special_hit_done = false
    AudioManager.play_sfx("special")


func _start_dodge(dir):
    dodge_t = 0.25
    dodge_cd = 1.2
    iframes = maxf(iframes, 0.35)
    if dir.length() < 0.1:
        dir = Vector3(sin(vis.rotation.y), 0, cos(vis.rotation.y))
    dodge_dir = dir.normalized()
    vis.rotation.y = atan2(dodge_dir.x, dodge_dir.z)
    AudioManager.play_sfx("swing", 0.7)


func _auto_face(rng):
    var best = null
    var bd = rng
    for grp in ["enemies", "bosses"]:
        for n in get_tree().get_nodes_in_group(grp):
            if is_instance_valid(n) and n.get("dead") != true:
                var d = n.global_position.distance_to(global_position) - float(n.get("hit_radius") if n.get("hit_radius") != null else 0.6)
                if d < bd:
                    bd = d
                    best = n
    if best != null:
        var to = best.global_position - global_position
        vis.rotation.y = atan2(to.x, to.z)


func _combat_ticks():
    if not attack_hit_done and attack_t <= ATTACK_DUR - 0.12:
        attack_hit_done = true
        _apply_attack(false)
    if not special_hit_done and special_t <= SPECIAL_DUR - 0.3:
        special_hit_done = true
        _apply_attack(true)


func _apply_attack(special):
    var reach = 7.0 if special else 3.2
    var fwd = Vector3(sin(vis.rotation.y), 0, cos(vis.rotation.y))
    var hit_any = false
    for grp in ["enemies", "bosses", "breakables"]:
        for n in get_tree().get_nodes_in_group(grp):
            if not is_instance_valid(n) or n.get("dead") == true:
                continue
            var to = n.global_position - global_position
            to.y = 0
            var rad = float(n.get("hit_radius") if n.get("hit_radius") != null else 0.6)
            if to.length() - rad > reach:
                continue
            if not special and to.length() > 0.5 and fwd.dot(to.normalized()) < 0.2:
                continue
            hit_any = true
            if grp == "breakables":
                n.smash()
                continue
            var dmg = GameState.attack_damage() * randf_range(0.9, 1.1) * (3.0 if special else 1.0)
            var crit = randf() < GameState.crit_chance()
            if crit:
                dmg *= 2.0
            n.hit(dmg, crit, global_position)
            GameState.target_enemy = n
    if special:
        Fx.shockwave(get_parent(), global_position, Color("ffd24a"), 7.0, 0.5)
        Fx.burst(get_parent(), global_position + Vector3(0, 1, 0), Color("ffd24a"), 24, 6.0, 0.7)
        Fx.shake(get_tree(), 0.15)
    if hit_any:
        Fx.vibrate(25)


func take_damage(amount, from_pos = Vector3.ZERO):
    if dead or iframes > 0.0 or GameState.in_menu:
        return
    GameState.hp -= amount
    hurt_t = 0.3
    iframes = 0.7
    var kb = global_position - from_pos
    kb.y = 0
    if kb.length() > 0.01:
        velocity += kb.normalized() * 7.0
    Fx.damage_number(get_parent(), global_position + Vector3(0, 2.2, 0), str(int(amount)), Color(1, 0.35, 0.35))
    Fx.burst(get_parent(), global_position + Vector3(0, 1, 0), Color("ff5a5a"), 8, 3.0, 0.4)
    AudioManager.play_sfx("hurt")
    Fx.vibrate(60)
    Fx.shake(get_tree(), 0.08)
    GameState.screen_flash.emit(Color(1, 0, 0, 0.3), 0.25)
    GameState.stats_changed.emit()
    if GameState.hp <= 0.0:
        _die()


func _die():
    dead = true
    GameState.stats.deaths += 1
    GameState.coins -= int(GameState.coins * 0.05)
    GameState.currency_changed.emit()
    GameState.player_died.emit()
    get_tree().create_timer(2.8).timeout.connect(_respawn)


func _respawn():
    dead = false
    GameState.hp = GameState.max_hp()
    global_position = respawn_pos
    velocity = Vector3.ZERO
    iframes = 2.0
    in_lava = 0
    GameState.stats_changed.emit()


# ---------- Анимация ----------
func _pick_state():
    var hv = Vector2(velocity.x, velocity.z).length()
    if dead:
        anim_state = "defeat"
    elif hurt_t > 0.0:
        anim_state = "damage"
    elif special_t > 0.0:
        anim_state = "special"
    elif attack_t > 0.0:
        anim_state = "attack"
    elif busy:
        anim_state = busy_anim
    elif victory_t > 0.0:
        anim_state = "victory"
    elif not is_on_floor():
        anim_state = "jump" if velocity.y > 0.5 else "fall"
    elif landed_t > 0.0:
        anim_state = "land"
    elif hv > 7.2:
        anim_state = "sprint"
    elif hv > 4.6:
        anim_state = "run"
    elif hv > 0.7:
        anim_state = "walk"
    elif dance_on:
        anim_state = "dance"
    else:
        anim_state = "idle"


func _animate(delta):
    anim_t += delta
    var t = anim_t
    var sy = 1.0
    var sxz = 1.0
    var bob = 0.0
    var tilt = 0.0
    var roll = 0.0
    var foot = 0.0
    var arm = 0.0
    var spin = 0.0
    var lunge = 0.0
    match anim_state:
        "idle":
            sy = 1.0 + sin(t * 2.0) * 0.03
            sxz = 1.0 - sin(t * 2.0) * 0.02
            arm = sin(t * 2.0) * 0.1
        "walk":
            var f = t * 8.0
            bob = absf(sin(f)) * 0.08
            roll = sin(f) * 0.06
            foot = sin(f) * 0.5
            arm = sin(f) * 0.6
        "run":
            var f2 = t * 12.0
            bob = absf(sin(f2)) * 0.14
            tilt = 0.18
            foot = sin(f2) * 0.9
            arm = sin(f2) * 0.9
        "sprint":
            var f3 = t * 16.0
            bob = absf(sin(f3)) * 0.18
            tilt = 0.32
            foot = sin(f3) * 1.1
            arm = sin(f3) * 1.2
        "jump":
            sy = 1.15
            sxz = 0.9
            tilt = -0.1
            arm = -1.0
        "fall":
            sy = 1.1
            sxz = 0.92
            arm = -0.8 + sin(t * 25.0) * 0.4
        "land":
            var p = 1.0 - landed_t / LAND_DUR
            sy = 0.72 + 0.28 * p
            sxz = 1.25 - 0.25 * p
        "attack":
            var pa = 1.0 - attack_t / ATTACK_DUR
            tilt = sin(pa * PI) * 0.5
            lunge = sin(pa * PI) * 0.35
            arm = -1.4 * sin(pa * PI)
            sxz = 1.0 + sin(pa * PI) * 0.08
        "special":
            var ps = 1.0 - special_t / SPECIAL_DUR
            spin = ps * TAU * 2.0
            sy = 1.0 + sin(ps * PI) * 0.2
            arm = -1.2
            bob = sin(ps * PI) * 0.3
        "damage":
            roll = sin(t * 45.0) * 0.25
            tilt = -0.3
            sxz = 1.1
            sy = 0.9
        "victory":
            bob = absf(sin(t * 6.0)) * 0.5
            arm = -1.3 + sin(t * 12.0) * 0.3
            spin = sin(t * 3.0) * 0.5
        "defeat":
            tilt = -1.35
            sy = 0.9
            bob = -0.25
        "open_egg":
            roll = sin(t * 6.0) * 0.12
            sxz = 1.0 + sin(t * 8.0) * 0.04
            arm = -0.6 + sin(t * 8.0) * 0.3
        "dance":
            roll = sin(t * 7.0) * 0.3
            bob = absf(sin(t * 7.0)) * 0.15
            spin = sin(t * 3.5) * 0.6
            arm = sin(t * 14.0) * 1.2
    var k = 1.0 - exp(-16.0 * delta)
    _sy = lerpf(_sy, sy, k)
    _sxz = lerpf(_sxz, sxz, k)
    _bob = lerpf(_bob, bob, k)
    _tilt = lerpf(_tilt, tilt, k)
    _roll = lerpf(_roll, roll, k)
    _foot = lerpf(_foot, foot, k)
    _arm = lerpf(_arm, arm, k)
    body_root.scale = Vector3(_sxz, _sy, _sxz)
    body_root.position = Vector3(0, 0.62 + _bob, lunge)
    body_root.rotation.x = _tilt
    body_root.rotation.z = _roll
    if anim_state == "special":
        body_root.rotation.y = spin
    else:
        body_root.rotation.y = lerp_angle(body_root.rotation.y, spin, 1.0 - exp(-20.0 * delta))
    foot_l.position.z = 0.1 + _foot * 0.25
    foot_r.position.z = 0.1 - _foot * 0.25
    foot_l.position.y = 0.1 + maxf(0.0, _foot) * 0.15
    foot_r.position.y = 0.1 + maxf(0.0, -_foot) * 0.15
    arm_l.position = Vector3(-0.7, _arm * -0.12, 0.05 + _arm * 0.2)
    arm_r.position = Vector3(0.7, _arm * -0.12, 0.05 - _arm * 0.2)
    var flash = 0.0
    if hurt_t > 0.0:
        flash = 1.5
    elif iframes > 0.0 and not dead:
        flash = 0.3 if int(anim_t * 20.0) % 2 == 0 else 0.0
    body_mat.emission_energy_multiplier = flash
