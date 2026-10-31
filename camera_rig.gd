extends Node3D
## Камера от третьего лица: свайп, зум, SpringArm (не проходит сквозь стены),
## тряска, кинематографический режим (открытие яиц, победа над боссом), облёт в меню.

var player = null
var spring
var cam
var pitch_node
var yaw = 0.0
var pitch = -0.35
var target_dist = 7.5
var shake = 0.0
var cine_t = 0.0
var cine_pos = Vector3.ZERO
var cine_dist = 5.0
var cine_pitch = -0.2


func _ready():
    add_to_group("camera_rig")
    pitch_node = Node3D.new()
    add_child(pitch_node)
    spring = SpringArm3D.new()
    spring.spring_length = target_dist
    spring.margin = 0.3
    pitch_node.add_child(spring)
    cam = Camera3D.new()
    cam.fov = 70.0
    cam.far = 400.0
    cam.current = true
    spring.add_child(cam)
    GameState.cinematic.connect(_on_cinematic)


func set_player(p):
    player = p
    spring.add_excluded_object(p.get_rid())


func add_shake(a):
    shake = maxf(shake, a)


func _on_cinematic(pos, dist, pitch_v, dur):
    cine_pos = pos
    cine_dist = dist
    cine_pitch = pitch_v
    cine_t = dur


func _process(delta):
    if player == null:
        return
    var sens = float(GameState.settings.get("cam_sens", 1.0))
    var inv = -1.0 if GameState.settings.get("cam_invert", false) else 1.0
    var dragged = GameState.cam_drag
    GameState.cam_drag = Vector2.ZERO
    yaw -= dragged.x * 0.0055 * sens
    pitch = clampf(pitch - dragged.y * 0.0045 * sens * inv, -1.25, 0.25)
    yaw += (Input.get_action_strength("cam_left") - Input.get_action_strength("cam_right")) * 1.8 * delta
    target_dist = clampf(target_dist - GameState.cam_zoom, 3.5, 14.0)
    GameState.cam_zoom = 0.0
    var k = 1.0 - exp(-10.0 * delta)
    if GameState.in_menu:
        yaw += 0.12 * delta
        pitch = lerpf(pitch, -0.25, k)
        global_position = global_position.lerp(Vector3(0, 3, 20), k)
        spring.spring_length = lerpf(spring.spring_length, 16.0, k)
    elif cine_t > 0.0:
        cine_t -= delta
        yaw += 0.25 * delta
        global_position = global_position.lerp(cine_pos, 1.0 - exp(-6.0 * delta))
        pitch = lerpf(pitch, cine_pitch, k)
        spring.spring_length = lerpf(spring.spring_length, cine_dist, k)
    else:
        var tgt = player.global_position + Vector3(0, 1.4, 0)
        global_position = global_position.lerp(tgt, k)
        var extra = 3.0 if GameState.boss_fights > 0 else 0.0
        spring.spring_length = lerpf(spring.spring_length, target_dist + extra, k)
    rotation.y = yaw
    pitch_node.rotation.x = pitch
    GameState.cam_yaw = yaw
    if shake > 0.01:
        cam.h_offset = randf_range(-1, 1) * shake
        cam.v_offset = randf_range(-1, 1) * shake
        shake = lerpf(shake, 0.0, 1.0 - exp(-6.0 * delta))
    else:
        cam.h_offset = 0.0
        cam.v_offset = 0.0
