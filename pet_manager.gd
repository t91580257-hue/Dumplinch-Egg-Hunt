extends Node3D
## Питомцы-спутники: следуют за игроком (без физики, поэтому не застревают),
## сами атакуют цель, по кнопке «вызов» налетают на врагов.

const PetBuilder = preload("res://scripts/pets/pet_builder.gd")
const Fx = preload("res://scripts/vfx/fx.gd")

var followers = []
var _t = 0.0


func _ready():
    add_to_group("pet_manager")
    GameState.pets_changed.connect(rebuild)
    rebuild()


func rebuild():
    for f in followers:
        if is_instance_valid(f.node):
            f.node.queue_free()
    followers.clear()
    for p in GameState.equipped_pets():
        var d = GameData.pet(p.id)
        var n = PetBuilder.build_pet(d, p.form)
        add_child(n)
        var pl = GameState.player_node
        if pl != null:
            n.global_position = pl.global_position + Vector3(0, 0.2, -1.5)
        followers.append({"node": n, "uid": p.uid, "cd": randf() * 1.2, "lunge": 0.0, "target": null})


func call_pets():
    for f in followers:
        f.cd = 0.0
        f.burst = true


func _nearest_enemy(pos, rng):
    var te = GameState.target_enemy
    if te != null and is_instance_valid(te) and te.get("dead") != true and te.global_position.distance_to(pos) < rng:
        return te
    var best = null
    var bd = rng
    for grp in ["enemies", "bosses"]:
        for n in get_tree().get_nodes_in_group(grp):
            if is_instance_valid(n) and n.get("dead") != true:
                var d = n.global_position.distance_to(pos)
                if d < bd:
                    bd = d
                    best = n
    return best


func _process(delta):
    var pl = GameState.player_node
    if pl == null:
        return
    _t += delta
    var n = followers.size()
    var yaw = pl.vis.rotation.y
    var back = -Vector3(sin(yaw), 0, cos(yaw))
    var right = Vector3(cos(yaw), 0, -sin(yaw))
    for i in n:
        var f = followers[i]
        var node = f.node
        if not is_instance_valid(node):
            continue
        var off = back * (2.0 + 0.3 * (i % 2)) + right * ((i - (n - 1) / 2.0) * 1.4)
        var target = pl.global_position + off
        if node.global_position.distance_to(pl.global_position) > 25.0:
            node.global_position = target
        var cur = node.global_position
        var np = cur.lerp(target, 1.0 - exp(-4.0 * delta))
        var moving = np.distance_to(cur) > 0.01
        np.y = 0.05 + (absf(sin(_t * 8.0 + i)) * 0.18 if moving else sin(_t * 2.0 + i) * 0.04 + 0.04)
        if f.lunge > 0.0 and f.target != null and is_instance_valid(f.target):
            f.lunge -= delta
            var tp = f.target.global_position
            np = np.lerp(Vector3(tp.x, np.y, tp.z), sin((0.35 - f.lunge) / 0.35 * PI) * 0.7)
        node.global_position = np
        var look = (target - cur)
        look.y = 0
        if look.length() > 0.05:
            node.rotation.y = lerp_angle(node.rotation.y, atan2(look.x, look.z), 1.0 - exp(-8.0 * delta))
        f.cd -= delta
        if f.cd <= 0.0 and not pl.dead and not GameState.in_menu:
            var tgt = _nearest_enemy(pl.global_position, 14.0)
            if tgt != null:
                var p = GameState.get_pet(f.uid)
                if p != null:
                    var mult = 3.0 if f.get("burst") == true else 1.0
                    f.burst = false
                    var dmg = GameState.pet_power(p) * 0.7 * mult
                    f.lunge = 0.35
                    f.target = tgt
                    f.cd = 1.4
                    tgt.hit(dmg, false, node.global_position)
                    Fx.burst(get_parent(), tgt.global_position + Vector3(0, 1, 0), GameData.pet(p.id).color, 6, 3.0, 0.4)
            else:
                f.cd = 0.4
