extends Node3D
## Мир: 5 регионов (каждый 260x260 м подряд по оси X), декор (MultiMesh), вода, лава,
## день и ночь, погода, облака, птицы, бабочки, враги, боссы, яйца, сундуки, врата.
## Всё строится процедурно из примитивов и процедурных текстур.

const ProcTex = preload("res://scripts/util/proc_tex.gd")
const Fx = preload("res://scripts/vfx/fx.gd")
const EnemyScript = preload("res://scripts/enemies/enemy.gd")
const BossScript = preload("res://scripts/enemies/boss.gd")
const EggPickup = preload("res://scripts/world/egg_pickup.gd")
const Chest = preload("res://scripts/world/chest.gd")
const Gate = preload("res://scripts/world/gate.gd")
const HealWell = preload("res://scripts/world/heal_well.gd")
const Breakable = preload("res://scripts/world/breakable.gd")

const DAY_LENGTH = 420.0

var rng = RandomNumberGenerator.new()
var env
var sky_mat
var sun
var decor = []
var time_of_day = 0.27
var c_top = Color("4f9cf0")
var c_hor = Color("cfe9ff")
var c_fog = Color("cfe6d6")
var water_shader
var grass_shader
var weather
var weather_mat
var weather_kind = ""
var fireflies
var clouds = []
var birds = []
var butterflies = []
var _t = 0.0


func _ready():
    rng.seed = 20261031
    water_shader = load("res://shaders/water.gdshader")
    grass_shader = load("res://shaders/grass.gdshader")
    _make_env()
    for i in 5:
        _make_region(i)
        _spawn_objects(i)
    _spawn_bosses()
    _make_clouds()
    _make_fauna()
    _make_weather()
    GameState.settings_changed.connect(apply_quality)
    apply_quality()


# ---------- Вспомогательные функции ----------
func _mat(color, emit = 0.0, rough = 0.9, alpha = 1.0):
    var m = StandardMaterial3D.new()
    m.albedo_color = Color(color.r, color.g, color.b, alpha)
    m.roughness = rough
    m.vertex_color_use_as_albedo = true
    if emit > 0.0:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = emit
    if alpha < 1.0:
        m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    return m


func _water(col, glow = 0.0, flow = 0.6, wave = 0.04, stripes = 6.0):
    var m = ShaderMaterial.new()
    m.shader = water_shader
    m.set_shader_parameter("water_color", col)
    m.set_shader_parameter("glow", glow)
    m.set_shader_parameter("flow_speed", flow)
    m.set_shader_parameter("wave", wave)
    m.set_shader_parameter("stripes", stripes)
    return m


func _inst(parent, mesh, mat, pos, scl = Vector3.ONE, rot = Vector3.ZERO):
    var mi = MeshInstance3D.new()
    mi.mesh = mesh
    mi.material_override = mat
    mi.position = pos
    mi.scale = scl
    mi.rotation = rot
    parent.add_child(mi)
    return mi


func _sph(r = 0.5, seg = 12):
    var m = SphereMesh.new()
    m.radius = r
    m.height = r * 2.0
    m.radial_segments = seg
    m.rings = seg / 2
    return m


func _cyl(rt, rb, h, seg = 10):
    var m = CylinderMesh.new()
    m.top_radius = rt
    m.bottom_radius = rb
    m.height = h
    m.radial_segments = seg
    return m


func _box(x, y, z):
    var b = BoxMesh.new()
    b.size = Vector3(x, y, z)
    return b


func _body(shape, pos):
    var sb = StaticBody3D.new()
    var cs = CollisionShape3D.new()
    cs.shape = shape
    sb.add_child(cs)
    sb.position = pos
    add_child(sb)
    return sb


func _points(n, origin, rmin, rmax):
    var res = []
    for i in n:
        var a = rng.randf() * TAU
        var r = sqrt(lerpf(rmin * rmin, rmax * rmax, rng.randf()))
        res.append(origin + Vector3(clampf(cos(a) * r, -124.0, 124.0), 0, clampf(sin(a) * r, -124.0, 124.0)))
    return res


func _multi(mesh, mat, pts, scales, yaws, c1, c2, yoff):
    var mm = MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.use_colors = true
    mm.mesh = mesh
    mm.instance_count = pts.size()
    for k in pts.size():
        var s = scales[k]
        var b = Basis(Vector3.UP, yaws[k]).scaled(Vector3(s, s, s))
        mm.set_instance_transform(k, Transform3D(b, pts[k] + Vector3(0, yoff * s, 0)))
        mm.set_instance_color(k, c1.lerp(c2, rng.randf()))
    var mi = MultiMeshInstance3D.new()
    mi.multimesh = mm
    mi.material_override = mat
    add_child(mi)
    decor.append({"inst": mi, "count": pts.size()})
    return mi


func _scales(n, smin, smax):
    var a = []
    for i in n:
        a.append(rng.randf_range(smin, smax))
    return a


func _yaws(n):
    var a = []
    for i in n:
        a.append(rng.randf() * TAU)
    return a


func _scatter(mesh, mat, n, origin, rmin, rmax, smin, smax, c1, c2, yoff):
    var pts = _points(n, origin, rmin, rmax)
    _multi(mesh, mat, pts, _scales(n, smin, smax), _yaws(n), c1, c2, yoff)
    return pts


func _forest(origin, n, trunk_h, trunk_mat, crown_mesh, crown_mat, crown_y, c1, c2, collide_n = 20):
    var pts = _points(n, origin, 24, 118)
    var sc = _scales(n, 0.8, 1.5)
    var yw = _yaws(n)
    _multi(_cyl(0.22, 0.34, trunk_h), trunk_mat, pts, sc, yw, Color.WHITE, Color.WHITE, trunk_h / 2.0)
    if crown_mesh != null:
        _multi(crown_mesh, crown_mat, pts, sc, yw, c1, c2, crown_y)
    var cn = 0
    for k in n:
        if cn >= collide_n:
            break
        if (pts[k] - origin).length() > 75.0:
            cn += 1
            var sh = CylinderShape3D.new()
            sh.radius = 0.5 * sc[k]
            sh.height = 4.0
            _body(sh, pts[k] + Vector3(0, 2.0, 0))


func _hill(pos, r, mat):
    var sh = SphereShape3D.new()
    sh.radius = r
    var p = pos + Vector3(0, -r * 0.72, 0)
    _body(sh, p)
    _inst(self, _sph(r, 24), mat, p)


func _lava_enter(body):
    if body.is_in_group("player"):
        body.in_lava += 1


func _lava_exit(body):
    if body.is_in_group("player"):
        body.in_lava = maxi(0, body.in_lava - 1)


func _lava_pool(pos, w, d):
    _inst(self, PlaneMesh.new(), _water(Color(1.0, 0.35, 0.05, 1.0), 2.2, 0.15, 0.03, 4.0), pos + Vector3(0, 0.06, 0), Vector3(w / 2.0, 1, d / 2.0))
    var a = Area3D.new()
    var cs = CollisionShape3D.new()
    var bs = BoxShape3D.new()
    bs.size = Vector3(w, 3.0, d)
    cs.shape = bs
    a.add_child(cs)
    a.position = pos + Vector3(0, 1.0, 0)
    a.body_entered.connect(_lava_enter)
    a.body_exited.connect(_lava_exit)
    add_child(a)


# ---------- Окружение ----------
func _make_env():
    env = Environment.new()
    var sky = Sky.new()
    sky_mat = ProceduralSkyMaterial.new()
    sky.sky_material = sky_mat
    env.sky = sky
    env.background_mode = Environment.BG_SKY
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.6, 0.65, 0.75)
    env.ambient_light_energy = 0.8
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.fog_enabled = true
    env.fog_density = 0.004
    env.glow_enabled = true
    env.glow_intensity = 0.7
    env.glow_bloom = 0.05
    var we = WorldEnvironment.new()
    we.environment = env
    add_child(we)
    sun = DirectionalLight3D.new()
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 90.0
    sun.rotation_degrees = Vector3(-50, 30, 0)
    add_child(sun)


func apply_quality():
    var q = clampi(int(GameState.settings.get("quality", 1)), 0, 2)
    var vp = get_viewport()
    vp.scaling_3d_scale = [0.6, 0.8, 1.0][q]
    vp.msaa_3d = Viewport.MSAA_2X if q == 2 else Viewport.MSAA_DISABLED
    sun.shadow_enabled = q >= 1
    sun.directional_shadow_max_distance = [30.0, 60.0, 110.0][q]
    env.glow_enabled = q >= 2
    var frac = [0.35, 0.7, 1.0][q]
    for d in decor:
        d.inst.multimesh.visible_instance_count = int(d.count * frac)
    if weather != null:
        weather.amount = maxi(10, int(_weather_amount() * GameState.particle_scale()))


func _weather_amount():
    return {"leaves": 40, "snow": 260, "embers": 90, "sparkles": 70, "motes": 90}.get(weather_kind, 40)


func _make_weather():
    weather = CPUParticles3D.new()
    weather.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
    weather.emission_box_extents = Vector3(30, 1, 30)
    weather.spread = 180.0
    weather.initial_velocity_min = 0.0
    weather.initial_velocity_max = 0.6
    var m = _sph(0.06, 6)
    weather_mat = StandardMaterial3D.new()
    weather_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.material = weather_mat
    weather.mesh = m
    weather.local_coords = false
    add_child(weather)
    fireflies = CPUParticles3D.new()
    fireflies.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
    fireflies.emission_box_extents = Vector3(25, 1.5, 25)
    fireflies.amount = 40
    fireflies.lifetime = 4.0
    fireflies.gravity = Vector3.ZERO
    fireflies.spread = 180.0
    fireflies.initial_velocity_min = 0.2
    fireflies.initial_velocity_max = 0.7
    fireflies.local_coords = false
    var fm = _sph(0.05, 6)
    var fmat = StandardMaterial3D.new()
    fmat.albedo_color = Color("d8ff60")
    fmat.emission_enabled = true
    fmat.emission = Color("d8ff60")
    fmat.emission_energy_multiplier = 3.0
    fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    fm.material = fmat
    fireflies.mesh = fm
    fireflies.emitting = false
    add_child(fireflies)


func _set_weather(kind):
    weather_kind = kind
    weather.lifetime = 6.0
    match kind:
        "leaves":
            weather_mat.albedo_color = Color("e0a040")
            weather.gravity = Vector3(0.5, -1.2, 0.3)
            weather.lifetime = 9.0
        "snow":
            weather_mat.albedo_color = Color.WHITE
            weather.gravity = Vector3(0.6, -3.0, 0)
        "embers":
            weather_mat.albedo_color = Color("ff8a30")
            weather.gravity = Vector3(0, 1.8, 0)
            weather.lifetime = 5.0
        "sparkles":
            weather_mat.albedo_color = Color("fff0ff")
            weather.gravity = Vector3(0, -0.2, 0)
        "motes":
            weather_mat.albedo_color = Color("b070ff")
            weather.gravity = Vector3(0, 0.4, 0)
    weather.amount = maxi(10, int(_weather_amount() * GameState.particle_scale()))


# ---------- Регионы ----------
func _make_region(i):
    var rd = GameData.REGIONS[i]
    var origin = GameData.region_origin(i)
    var gmat = StandardMaterial3D.new()
    gmat.albedo_texture = ProcTex.noise_texture(rd.ground.darkened(0.15), rd.ground.lightened(0.1), 64, 0.06, i + 3)
    gmat.uv1_scale = Vector3(30, 30, 1)
    gmat.roughness = 0.35 if i == 1 else 0.95
    var pm = PlaneMesh.new()
    pm.size = Vector2(GameData.REGION_SIZE, GameData.REGION_SIZE)
    _inst(self, pm, gmat, origin)
    var bs = BoxShape3D.new()
    bs.size = Vector3(GameData.REGION_SIZE, 2.0, GameData.REGION_SIZE)
    _body(bs, origin + Vector3(0, -1.0, 0))
    match i:
        0: _build_green(origin, gmat)
        1: _build_ice(origin, gmat)
        2: _build_fire(origin)
        3: _build_sky(origin)
        4: _build_dark(origin)


func _grass_mat(color):
    var m = ShaderMaterial.new()
    m.shader = grass_shader
    return m


func _build_green(o, gmat):
    var wood = _mat(Color("6b4a2a"))
    _forest(o, 70, 2.4, wood, _sph(1.5, 10), _mat(Color.WHITE, 0.0, 0.9), 3.0, Color("3f8a3a"), Color("8fc84a"), 30)
    _forest(o, 30, 2.0, wood, _cyl(0.0, 1.3, 3.4, 8), _mat(Color.WHITE), 3.4, Color("1f5a38"), Color("2f7a48"), 15)
    _scatter(_sph(0.5, 8), _mat(Color.WHITE), 60, o, 20, 120, 0.6, 1.4, Color("2f7a30"), Color("5aa83a"), 0.3)
    _scatter(_sph(0.12, 6), _mat(Color.WHITE, 0.3), 130, o, 15, 120, 0.7, 1.5, Color("ff6a8a"), Color("ffe05a"), 0.12)
    _scatter(_cyl(0.0, 0.09, 0.9, 4), _grass_mat(Color.WHITE), 480, o, 8, 124, 0.7, 1.5, Color("3f8f2a"), Color("8fd04a"), 0.45)
    var rocks = _scatter(_sph(0.7, 8), _mat(Color.WHITE, 0.0, 1.0), 26, o, 20, 120, 0.6, 2.0, Color("7a7a80"), Color("a8a8b0"), 0.2)
    for k in 6:
        var sh = SphereShape3D.new()
        sh.radius = 0.8
        _body(sh, rocks[k] + Vector3(0, 0.3, 0))
    var hill_mat = StandardMaterial3D.new()
    hill_mat.albedo_texture = gmat.albedo_texture
    hill_mat.uv1_scale = Vector3(8, 8, 1)
    for p in _points(14, o, 100, 120):
        if absf(p.z - o.z) < 28.0 and p.x - o.x > 60.0:
            continue
        _hill(p, rng.randf_range(12.0, 20.0), hill_mat)
    # река, мост, водопад
    _inst(self, PlaneMesh.new(), _water(Color(0.15, 0.5, 0.85, 0.8), 0.0, 0.5, 0.03, 8.0), o + Vector3(0, 0.05, 88), Vector3(130.0, 1, 4.0))
    _inst(self, _box(7.0, 0.3, 11.0), _mat(Color("8a8a92")), o + Vector3(-25, 0.12, 88))
    _inst(self, _box(0.4, 0.8, 11.0), _mat(Color("7a7a82")), o + Vector3(-28.4, 0.5, 88))
    _inst(self, _box(0.4, 0.8, 11.0), _mat(Color("7a7a82")), o + Vector3(-21.6, 0.5, 88))
    _inst(self, _box(6.0, 26.0, 1.6), _water(Color(0.5, 0.8, 1.0, 0.75), 0.3, 1.2, 0.0, 10.0), o + Vector3(112, 13, 84))
    # деревня и колодец
    var wall = _mat(Color("e0c898"))
    var roof = _mat(Color("b04a3a"))
    for hp in [Vector3(-100, 0, -95), Vector3(-82, 0, -100), Vector3(-104, 0, -72), Vector3(-84, 0, -78)]:
        _inst(self, _box(7, 4, 6), wall, o + hp + Vector3(0, 2, 0))
        var pr = PrismMesh.new()
        pr.size = Vector3(8, 3, 7)
        _inst(self, pr, roof, o + hp + Vector3(0, 5.5, 0))
        var bsx = BoxShape3D.new()
        bsx.size = Vector3(7, 4, 6)
        _body(bsx, o + hp + Vector3(0, 2, 0))
    var well = HealWell.new()
    add_child(well)
    well.position = o + Vector3(-92, 0, -86)
    # замок вдалеке
    var stone = _mat(Color("9a9aa8"))
    _inst(self, _box(26, 16, 8), stone, o + Vector3(0, 8, -122))
    var ks = BoxShape3D.new()
    ks.size = Vector3(26, 16, 8)
    _body(ks, o + Vector3(0, 8, -122))
    for tx in [-15, 15]:
        _inst(self, _cyl(3.5, 3.5, 24, 12), stone, o + Vector3(tx, 12, -122))
        _inst(self, _cyl(0.0, 4.5, 8, 12), roof, o + Vector3(tx, 28, -122))
    # пещера
    _hill(o + Vector3(96, 0, 100), 11.0, _mat(Color("6a6a70")))
    _inst(self, _sph(2.5, 10), _mat(Color("0a0a0e")), o + Vector3(88, 1.6, 100), Vector3(1, 1, 0.5))
    var ch = Chest.new()
    ch.setup("c0_cave", 0)
    add_child(ch)
    ch.position = o + Vector3(86, 0, 94)


func _build_ice(o, gmat):
    var snow = _mat(Color("f0f8ff"))
    _forest(o, 55, 2.0, _mat(Color("5a4a3a")), _cyl(0.0, 1.4, 3.6, 8), _mat(Color.WHITE), 3.4, Color("d8ecf8"), Color("ffffff"), 20)
    _scatter(_cyl(0.0, 0.5, 3.0, 5), _mat(Color("7fe0ff"), 2.0, 0.2, 0.9), 45, o, 18, 120, 0.6, 1.8, Color("7fe0ff"), Color("b0f0ff"), 1.4)
    _scatter(_sph(0.18, 6), _mat(Color("4a9aff"), 2.2), 90, o, 15, 120, 0.6, 1.4, Color("3a8aff"), Color("6af0ff"), 0.2)
    _scatter(_sph(0.7, 8), snow, 30, o, 20, 120, 0.7, 2.2, Color("dfeaf5"), Color("ffffff"), 0.2)
    _inst(self, _cyl(26, 26, 0.06, 32), _water(Color(0.65, 0.88, 1.0, 0.92), 0.25, 0.0, 0.0, 3.0), o + Vector3(-60, 0.04, 45))
    var hmat = StandardMaterial3D.new()
    hmat.albedo_color = Color("eef6ff")
    hmat.roughness = 0.5
    for p in _points(14, o, 100, 122):
        if absf(p.z - o.z) < 28.0 and p.x - o.x > 60.0:
            continue
        _hill(p, rng.randf_range(14.0, 24.0), hmat)
    _hill(o + Vector3(-98, 0, -90), 11.0, _mat(Color("b0d0e8")))
    _inst(self, _sph(2.5, 10), _mat(Color("101830")), o + Vector3(-90, 1.6, -90), Vector3(1, 1, 0.5))
    var ch = Chest.new()
    ch.setup("c1_cave", 1)
    add_child(ch)
    ch.position = o + Vector3(-88, 0, -84)


func _build_fire(o):
    var black = _mat(Color("2a2428"), 0.0, 1.0)
    var rocks = _scatter(_sph(0.8, 8), black, 55, o, 20, 120, 0.6, 2.4, Color("1e1a1e"), Color("4a3a3a"), 0.3)
    for k in 10:
        var sh = SphereShape3D.new()
        sh.radius = 1.0
        _body(sh, rocks[k] + Vector3(0, 0.4, 0))
    _forest(o, 28, 3.2, _mat(Color("1a1414")), null, null, 0.0, Color.WHITE, Color.WHITE, 10)
    _scatter(_cyl(0.0, 0.25, 1.4, 5), _mat(Color("ff7a20"), 2.0), 40, o, 18, 120, 0.5, 1.4, Color("ff5a10"), Color("ffc030"), 0.7)
    for pp in [Vector3(0, 0, -50), Vector3(-10, 0, 52), Vector3(-45, 0, 20), Vector3(50, 0, 0), Vector3(90, 0, -95)]:
        _lava_pool(o + pp, 14.0, 10.0)
    _inst(self, _cyl(2.0, 30.0, 46.0, 16), _mat(Color("2a2020")), o + Vector3(-100, 23, -100))
    _inst(self, _sph(5.0, 12), _mat(Color("ff6a10"), 3.0), o + Vector3(-100, 45, -100), Vector3(1, 0.4, 1))
    var smoke = CPUParticles3D.new()
    smoke.amount = maxi(6, int(30 * GameState.particle_scale()))
    smoke.lifetime = 6.0
    smoke.direction = Vector3.UP
    smoke.spread = 15.0
    smoke.initial_velocity_min = 4.0
    smoke.initial_velocity_max = 7.0
    smoke.gravity = Vector3(1, 0, 0)
    var smm = _sph(1.6, 6)
    smm.material = _mat(Color(0.2, 0.18, 0.2), 0.0, 1.0, 0.5)
    smoke.mesh = smm
    smoke.position = o + Vector3(-100, 46, -100)
    add_child(smoke)
    _inst(self, _box(7.0, 26.0, 1.5), _water(Color(1.0, 0.4, 0.05, 0.95), 2.5, 1.0, 0.0, 8.0), o + Vector3(110, 13, -60))
    for k in 8:
        var a = k * TAU / 8.0
        _inst(self, _sph(1.2, 8), black, o + Vector3(85 + cos(a) * 6.0, 0.6, -30 + sin(a) * 6.0), Vector3(1, 0.8, 1))
    _inst(self, _sph(0.4, 10), _mat(Color("ff6a2a"), 1.5), o + Vector3(85, 0.7, -30), Vector3(1, 1.35, 1))
    var ch = Chest.new()
    ch.setup("c2_cave", 2)
    add_child(ch)
    ch.position = o + Vector3(80, 0, -24)


func _build_sky(o):
    var cloud = _mat(Color("ffffff"), 0.35, 1.0)
    _scatter(_sph(1.0, 8), cloud, 70, o, 10, 124, 1.5, 4.5, Color("f0f6ff"), Color("ffffff"), 0.3)
    _forest(o, 40, 2.4, _mat(Color("c8b0e0")), _sph(1.6, 10), _mat(Color("b080ff"), 1.0), 3.0, Color("9a70ff"), Color("ff9ae0"), 12)
    _scatter(_sph(0.5, 4), _mat(Color("7affff"), 2.5), 40, o + Vector3(0, 8, 0), 10, 120, 0.6, 1.6, Color("7affff"), Color("ff9aff"), 1.0)
    var grass_mat = _mat(Color("8ad8a0"))
    for k in 9:
        var p = _points(1, o, 35, 112)[0] + Vector3(0, rng.randf_range(14.0, 34.0), 0)
        var rr = rng.randf_range(7.0, 12.0)
        _inst(self, _cyl(rr, rr, 2.5, 16), grass_mat, p)
        _inst(self, _cyl(rr, 0.5, 9.0, 16), _mat(Color("8a7a6a")), p + Vector3(0, -5.7, 0))
        _inst(self, _cyl(0.2, 0.3, 2.0), _mat(Color("6b4a2a")), p + Vector3(0, 2.2, 0))
        _inst(self, _sph(1.4, 10), _mat(Color("b080ff"), 1.0), p + Vector3(0, 4.2, 0))
    var cols = [Color("ff4a4a"), Color("ff9a3a"), Color("ffe03a"), Color("4adf5a"), Color("3aa8ff"), Color("5a5aff"), Color("b05aff")]
    for a in [[Vector3(-60, 0, -30), 0.0], [Vector3(55, 0, 45), PI / 2.0]]:
        for k in 7:
            var tm = TorusMesh.new()
            var rr2 = 22.0 - k * 0.7
            tm.inner_radius = rr2 - 0.3
            tm.outer_radius = rr2 + 0.3
            tm.rings = 24
            tm.ring_segments = 6
            _inst(self, tm, _mat(cols[k], 1.2), o + a[0], Vector3.ONE, Vector3(PI / 2.0, a[1], 0))
    var ch = Chest.new()
    ch.setup("c3_cave", 3)
    add_child(ch)
    ch.position = o + Vector3(0, 0, -100)


func _build_dark(o):
    _forest(o, 60, 3.8, _mat(Color("1e1626")), null, null, 0.0, Color.WHITE, Color.WHITE, 24)
    var stone = _mat(Color("3a3448"))
    for p in _points(7, o, 40, 110):
        _inst(self, _box(3, 2, 3), stone, p + Vector3(0, 1, 0))
        _inst(self, _box(2, 5, 1.6), stone, p + Vector3(0, 4.5, 0))
        _inst(self, _sph(1.0, 10), stone, p + Vector3(0, 8, 0))
        var sb = BoxShape3D.new()
        sb.size = Vector3(3, 6, 3)
        _body(sb, p + Vector3(0, 3, 0))
    _scatter(_box(0.8, 1.4, 0.3), stone, 45, o, 20, 120, 0.7, 1.6, Color("2a2438"), Color("4a4458"), 0.7)
    _scatter(_sph(0.25, 6), _mat(Color("b060ff"), 3.0), 45, o, 15, 120, 0.7, 1.6, Color("9040ff"), Color("ff60d0"), 3.0)
    var cs = _mat(Color("1a1424"))
    _inst(self, _box(40, 22, 12), cs, o + Vector3(0, 11, -125))
    var cb = BoxShape3D.new()
    cb.size = Vector3(40, 22, 12)
    _body(cb, o + Vector3(0, 11, -125))
    for tx in [-24, 24]:
        _inst(self, _cyl(4.5, 4.5, 34, 12), cs, o + Vector3(tx, 17, -125))
        _inst(self, _cyl(0.0, 5.5, 10, 12), _mat(Color("3a1a5a")), o + Vector3(tx, 39, -125))
    for k in 6:
        _inst(self, _box(1.4, 2.4, 0.3), _mat(Color("ffcf60"), 2.0), o + Vector3(-12 + k * 4.8, 12, -118.8))
    var ch = Chest.new()
    ch.setup("c4_cave", 4)
    add_child(ch)
    ch.position = o + Vector3(100, 0, 100)


# ---------- Объекты ----------
func _spawn_objects(i):
    var rd = GameData.REGIONS[i]
    var o = GameData.region_origin(i)
    var ep = _points(6, o, 30, 100)
    for k in ep.size():
        var e = EggPickup.new()
        e.setup(rd.eggs[k % rd.eggs.size()], i)
        add_child(e)
        e.position = ep[k]
    var cp = _points(3, o, 35, 110)
    for k in cp.size():
        var c = Chest.new()
        c.setup("c%d_%d" % [i, k], i)
        add_child(c)
        c.position = cp[k]
    for k in 6:
        var b = Breakable.new()
        b.setup(i)
        add_child(b)
        b.position = o + Vector3(rng.randf_range(-14, 14), 0, rng.randf_range(16, 30))
    for p in _points(8, o, 25, 75):
        _spawn_enemy(i, p)
    if i < 4 and GameState.unlocked_regions <= i + 1:
        var g = Gate.new()
        g.setup(i)
        add_child(g)
        g.position = o + Vector3(124, 0, 0)


func _spawn_enemy(i, pos):
    var e = EnemyScript.new()
    e.setup(i, pos)
    add_child(e)
    e.died.connect(_on_enemy_died.bind(i, pos))


func _on_enemy_died(_enemy, i, pos):
    get_tree().create_timer(30.0).timeout.connect(_spawn_enemy.bind(i, pos))


func _spawn_bosses():
    for b in GameData.BOSSES:
        if GameState.defeated_bosses.has(b.id):
            continue
        var bo = BossScript.new()
        bo.setup(b, GameData.region_origin(b.region))
        add_child(bo)


# ---------- Живой мир ----------
func _make_clouds():
    var m = _mat(Color.WHITE, 0.4, 1.0, 0.85)
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    for i in 18:
        var c = Node3D.new()
        c.position = Vector3(rng.randf_range(-200, 1400), rng.randf_range(60, 90), rng.randf_range(-170, 170))
        for k in 4:
            _inst(c, _sph(1.0, 8), m, Vector3(k * 7.0 - 10.0, rng.randf_range(-1, 2), rng.randf_range(-3, 3)), Vector3(8, 3.5, 6))
        add_child(c)
        clouds.append(c)


func _make_fauna():
    var bm = _mat(Color("2a2a32"))
    for i in 6:
        var b = Node3D.new()
        _inst(b, _sph(0.3, 6), bm, Vector3.ZERO, Vector3(0.6, 0.5, 1.2))
        for s in [-1, 1]:
            var w = Node3D.new()
            w.name = "w%d" % s
            b.add_child(w)
            _inst(w, _box(1.2, 0.04, 0.5), bm, Vector3(0.6 * s, 0, 0))
        add_child(b)
        birds.append({"n": b, "a": rng.randf() * TAU, "r": rng.randf_range(40, 100), "h": rng.randf_range(25, 40), "s": rng.randf_range(0.1, 0.2)})
    for i in 14:
        var b2 = Node3D.new()
        var bm2 = _mat(Color.from_hsv(rng.randf(), 0.7, 1.0), 0.8)
        for s in [-1, 1]:
            var w2 = Node3D.new()
            w2.name = "w%d" % s
            b2.add_child(w2)
            _inst(w2, _box(0.22, 0.01, 0.16), bm2, Vector3(0.11 * s, 0, 0))
        add_child(b2)
        butterflies.append({"n": b2, "c": Vector3(rng.randf_range(-80, 80), 1.4, rng.randf_range(-80, 80)), "p": rng.randf() * 10.0})


func _process(delta):
    _t += delta
    time_of_day = fposmod(time_of_day + delta / DAY_LENGTH, 1.0)
    var rd = GameData.REGIONS[GameState.current_region]
    var s = sin(time_of_day * TAU)
    var day = smoothstep(-0.12, 0.3, s)
    var k = 1.0 - exp(-1.5 * delta)
    c_top = c_top.lerp(Color(0.02, 0.03, 0.09).lerp(rd.sky_top, day), k)
    c_hor = c_hor.lerp(Color(0.06, 0.07, 0.16).lerp(rd.sky_hor, day), k)
    c_fog = c_fog.lerp(Color(0.03, 0.04, 0.09).lerp(rd.fog, day), k)
    sky_mat.sky_top_color = c_top
    sky_mat.sky_horizon_color = c_hor
    sky_mat.ground_horizon_color = c_hor
    sky_mat.ground_bottom_color = c_fog.darkened(0.3)
    env.fog_light_color = c_fog
    env.fog_density = lerpf(env.fog_density, rd.fog_density, k)
    env.ambient_light_color = c_hor.lerp(Color.WHITE, 0.35)
    env.ambient_light_energy = lerpf(0.3, 0.9, day)
    sun.light_energy = lerpf(0.12, 1.15, day)
    sun.light_color = Color(0.5, 0.6, 1.0).lerp(Color(1.0, 0.96, 0.88), day)
    sun.rotation_degrees = Vector3(-(18.0 + 52.0 * maxf(s, 0.0)) if s > 0.0 else -40.0, time_of_day * 360.0, 0)
    var pl = GameState.player_node
    var pp = pl.global_position if pl != null else Vector3.ZERO
    if weather_kind != rd.weather:
        _set_weather(rd.weather)
    weather.position = pp + Vector3(0, 14.0 if rd.weather != "embers" else 0.5, 0)
    fireflies.position = pp + Vector3(0, 1.5, 0)
    fireflies.emitting = day < 0.5 and GameState.current_region == 0 and GameState.settings.get("quality", 1) > 0
    for c in clouds:
        c.position.x += 1.5 * delta
        if c.position.x > 1400.0:
            c.position.x = -250.0
    for b in birds:
        b.a += b.s * delta
        var p = Vector3(cos(b.a) * b.r, b.h, sin(b.a) * b.r)
        b.n.position = p
        b.n.rotation.y = -b.a
        var f = sin(_t * 9.0 + b.r) * 0.6
        b.n.get_node("w-1").rotation.z = f
        b.n.get_node("w1").rotation.z = -f
    if GameState.current_region == 0:
        for bf in butterflies:
            var t = _t * 0.5 + bf.p
            bf.n.position = bf.c + Vector3(sin(t * 1.3) * 6.0, 0.6 * sin(t * 2.1), cos(t * 0.9) * 6.0)
            bf.n.rotation.y = t
            var fl = sin(_t * 18.0 + bf.p) * 0.9
            bf.n.get_node("w-1").rotation.z = fl
            bf.n.get_node("w1").rotation.z = -fl
