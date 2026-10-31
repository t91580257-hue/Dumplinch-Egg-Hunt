extends RefCounted
## Процедурные 3D-модели питомцев (10 форм, цвет и свечение зависят от редкости).


static func _mat(color, emit = 0.0, alpha = 1.0):
    var m = StandardMaterial3D.new()
    m.albedo_color = Color(color.r, color.g, color.b, alpha)
    m.roughness = 0.6
    if emit > 0.0:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = emit
    if alpha < 1.0:
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    return m


static func _add(parent, mesh, mat, pos, scl = Vector3.ONE, rot = Vector3.ZERO):
    var mi = MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = mat
    mi.position = pos
    mi.scale = scl
    mi.rotation = rot
    parent.add_child(mi)
    return mi


static func _sph(r):
    var m = SphereMesh.new()
    m.radius = r
    m.height = r * 2.0
    m.radial_segments = 14
    m.rings = 7
    return m


static func _cone(r, h):
    var m = CylinderMesh.new()
    m.top_radius = 0.0
    m.bottom_radius = r
    m.height = h
    m.radial_segments = 8
    return m


static func build_pet(d, form = 0):
    var root = Node3D.new()
    var body = Node3D.new()
    body.name = "Body"
    root.add_child(body)
    var c = d.color
    var emit = [0.0, 0.0, 0.25, 0.5, 0.9][d.rarity]
    var m = _mat(c, emit, 0.8 if d.shape == "ghost" else 1.0)
    var dark = _mat(c.darkened(0.35), emit * 0.5)
    var eye = _mat(Color("101010"))
    var white = _mat(Color.WHITE)
    match d.shape:
        "cat", "fox", "wolf":
            _add(body, _sph(0.4), m, Vector3(0, 0.45, 0), Vector3(1, 0.9, 1.15))
            var head = _add(body, _sph(0.28), m, Vector3(0, 0.78, 0.3))
            for s in [-1, 1]:
                _add(head, _cone(0.1, 0.25), dark, Vector3(0.16 * s, 0.26, 0), Vector3.ONE, Vector3(0, 0, -0.2 * s))
                _add(head, _sph(0.04), eye, Vector3(0.1 * s, 0.05, 0.24))
            if d.shape != "cat":
                _add(head, _sph(0.12), dark, Vector3(0, -0.05, 0.27), Vector3(1, 0.8, 1.3))
            _add(body, _sph(0.14 if d.shape != "fox" else 0.2), dark, Vector3(0, 0.55, -0.5), Vector3(0.8, 0.8, 1.8))
        "bunny":
            _add(body, _sph(0.38), m, Vector3(0, 0.4, 0))
            var hb = _add(body, _sph(0.26), m, Vector3(0, 0.78, 0.15))
            for s in [-1, 1]:
                _add(hb, _sph(0.09), dark, Vector3(0.1 * s, 0.4, 0), Vector3(0.7, 2.6, 0.7))
                _add(hb, _sph(0.04), eye, Vector3(0.1 * s, 0.05, 0.22))
            _add(body, _sph(0.1), white, Vector3(0, 0.35, -0.4))
        "dragon":
            _add(body, _sph(0.38), m, Vector3(0, 0.42, 0), Vector3(1, 0.9, 1.2))
            var hd = _add(body, _sph(0.24), m, Vector3(0, 0.78, 0.3))
            for s in [-1, 1]:
                _add(hd, _cone(0.06, 0.2), white, Vector3(0.12 * s, 0.22, -0.05))
                _add(hd, _sph(0.04), eye, Vector3(0.1 * s, 0.05, 0.2))
                _add(body, _sph(0.3), dark, Vector3(0.4 * s, 0.65, -0.1), Vector3(0.9, 0.12, 0.7), Vector3(0, 0, 0.5 * s))
            _add(body, _cone(0.12, 0.6), dark, Vector3(0, 0.3, -0.55), Vector3.ONE, Vector3(1.9, 0, 0))
        "ghost":
            _add(body, _sph(0.4), m, Vector3(0, 0.6, 0), Vector3(1, 1.2, 1))
            _add(body, _cone(0.4, 0.4), m, Vector3(0, 0.2, 0), Vector3.ONE, Vector3(PI, 0, 0))
            for s in [-1, 1]:
                _add(body, _sph(0.07), eye, Vector3(0.14 * s, 0.7, 0.34), Vector3(1, 1.4, 0.6))
        "golem":
            var bm = BoxMesh.new()
            bm.size = Vector3(0.7, 0.7, 0.55)
            _add(body, bm, m, Vector3(0, 0.45, 0))
            var hm = BoxMesh.new()
            hm.size = Vector3(0.4, 0.35, 0.35)
            _add(body, hm, dark, Vector3(0, 0.98, 0.05))
            for s in [-1, 1]:
                _add(body, _sph(0.06), _mat(Color("ffe070"), 2.0), Vector3(0.1 * s, 1.0, 0.24))
                var am = BoxMesh.new()
                am.size = Vector3(0.18, 0.5, 0.18)
                _add(body, am, dark, Vector3(0.46 * s, 0.45, 0))
        "dumpling":
            _add(body, _sph(0.4), m, Vector3(0, 0.38, 0), Vector3(1.25, 0.85, 1.0))
            for i in 5:
                _add(body, _sph(0.07), dark, Vector3(lerpf(-0.4, 0.4, i / 4.0), 0.65 - absf(lerpf(-0.4, 0.4, i / 4.0)) * 0.35, 0), Vector3(1, 1.4, 1))
            for s in [-1, 1]:
                _add(body, _sph(0.05), eye, Vector3(0.16 * s, 0.4, 0.36))
        "monster":
            _add(body, _sph(0.42), m, Vector3(0, 0.5, 0))
            _add(body, _sph(0.17), white, Vector3(0, 0.6, 0.32))
            _add(body, _sph(0.08), eye, Vector3(0, 0.6, 0.45))
            for s in [-1, 1]:
                _add(body, _cone(0.08, 0.3), dark, Vector3(0.22 * s, 0.95, 0), Vector3.ONE, Vector3(0, 0, -0.3 * s))
        _:
            _add(body, _sph(0.4), m, Vector3(0, 0.4, 0))
            for s in [-1, 1]:
                _add(body, _sph(0.06), eye, Vector3(0.14 * s, 0.5, 0.34))
    if d.rarity >= 3:
        var p = CPUParticles3D.new()
        p.amount = maxi(3, int(8 * GameState.particle_scale()))
        p.lifetime = 1.2
        p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
        p.emission_sphere_radius = 0.5
        p.direction = Vector3.UP
        p.spread = 20.0
        p.initial_velocity_min = 0.3
        p.initial_velocity_max = 0.8
        p.gravity = Vector3.ZERO
        var sm = _sph(0.04)
        sm.material = _mat(d.color.lightened(0.4), 3.0)
        p.mesh = sm
        p.position = Vector3(0, 0.5, 0)
        root.add_child(p)
    root.scale = Vector3.ONE * (0.9 + 0.25 * form)
    return root
