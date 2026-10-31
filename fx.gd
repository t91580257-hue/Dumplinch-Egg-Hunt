extends RefCounted
## Лёгкие визуальные эффекты: частицы, цифры урона, ударные волны, вибрация.


static func burst(parent, pos, color, amount = 16, speed = 4.0, life = 0.6, size = 0.12):
    if parent == null or not is_instance_valid(parent):
        return
    var p = CPUParticles3D.new()
    p.one_shot = true
    p.explosiveness = 1.0
    p.amount = maxi(4, int(amount * GameState.particle_scale()))
    p.lifetime = life
    p.direction = Vector3.UP
    p.spread = 180.0
    p.initial_velocity_min = speed * 0.5
    p.initial_velocity_max = speed
    p.gravity = Vector3(0, -6, 0)
    var m = SphereMesh.new()
    m.radius = size
    m.height = size * 2.0
    m.radial_segments = 6
    m.rings = 3
    var mat = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.emission_enabled = true
    mat.emission = color
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.material = mat
    p.mesh = m
    parent.add_child(p)
    p.global_position = pos
    p.emitting = true
    parent.get_tree().create_timer(life + 0.6).timeout.connect(func():
        if is_instance_valid(p):
            p.queue_free())


static func damage_number(parent, pos, text, color = Color.WHITE, big = false):
    if parent == null or not is_instance_valid(parent):
        return
    var l = Label3D.new()
    l.text = text
    l.modulate = color
    l.outline_size = 12
    l.font_size = 72 if big else 48
    l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    l.no_depth_test = true
    l.pixel_size = 0.01
    parent.add_child(l)
    l.global_position = pos
    var tw = l.create_tween()
    tw.set_parallel(true)
    tw.tween_property(l, "position:y", l.position.y + 1.6, 0.8)
    tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
    tw.chain().tween_callback(l.queue_free)


static func shockwave(parent, pos, color, radius = 6.0, dur = 0.5):
    if parent == null or not is_instance_valid(parent):
        return
    var mi = MeshInstance3D.new()
    var m = CylinderMesh.new()
    m.top_radius = 1.0
    m.bottom_radius = 1.0
    m.height = 0.08
    m.radial_segments = 24
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(color.r, color.g, color.b, 0.6)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.material = mat
    mi.mesh = m
    parent.add_child(mi)
    mi.global_position = pos + Vector3(0, 0.1, 0)
    mi.scale = Vector3(0.3, 1, 0.3)
    var tw = mi.create_tween()
    tw.set_parallel(true)
    tw.tween_property(mi, "scale", Vector3(radius, 1, radius), dur)
    tw.tween_property(mat, "albedo_color:a", 0.0, dur)
    tw.chain().tween_callback(mi.queue_free)


static func shake(tree, amount):
    tree.call_group("camera_rig", "add_shake", amount)


static func vibrate(ms):
    if GameState.settings.get("vibration", true):
        Input.vibrate_handheld(ms)
