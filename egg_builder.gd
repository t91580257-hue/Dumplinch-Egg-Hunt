extends RefCounted
## Процедурные яйца: уникальный цвет, узор-текстура, свечение и частицы для каждого вида.

const ProcTex = preload("res://scripts/util/proc_tex.gd")


static func build_egg(e, scl = 1.0):
    var root = Node3D.new()
    var mi = MeshInstance3D.new()
    mi.name = "Mesh"
    var sm = SphereMesh.new()
    sm.radius = 0.5
    sm.height = 1.0
    sm.radial_segments = 24
    sm.rings = 12
    mi.mesh = sm
    mi.scale = Vector3(1.0, 1.35, 1.0)
    var mat = StandardMaterial3D.new()
    mat.albedo_texture = ProcTex.egg_texture(e.color, e.accent, e.pattern, 128)
    mat.roughness = 0.35
    mat.metallic = 0.2
    mat.emission_enabled = true
    mat.emission = e.accent
    mat.emission_energy_multiplier = 0.25
    mi.material_override = mat
    root.add_child(mi)
    var idx = GameData.EGGS.find(e)
    if idx >= 3:
        var p = CPUParticles3D.new()
        p.amount = maxi(3, int((6 + idx) * GameState.particle_scale()))
        p.lifetime = 1.6
        p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
        p.emission_sphere_radius = 0.7
        p.direction = Vector3.UP
        p.spread = 30.0
        p.initial_velocity_min = 0.2
        p.initial_velocity_max = 0.6
        p.gravity = Vector3.ZERO
        var pm = SphereMesh.new()
        pm.radius = 0.035
        pm.height = 0.07
        pm.radial_segments = 6
        pm.rings = 3
        var pmat = StandardMaterial3D.new()
        pmat.albedo_color = e.accent
        pmat.emission_enabled = true
        pmat.emission = e.accent
        pmat.emission_energy_multiplier = 3.0
        pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        pm.material = pmat
        p.mesh = pm
        root.add_child(p)
    root.scale = Vector3.ONE * scl
    return root


static func glow_material(egg_node):
    return egg_node.get_node("Mesh").material_override
