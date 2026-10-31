extends Node
## Статические данные игры: регионы, редкости, яйца, питомцы, боссы, задания.
## Баланс можно менять здесь, не трогая игровой код.

const REGION_SIZE = 260.0
const REGION_HALF = 130.0

var RARITIES = [
    {"name": "Обычный", "color": Color("b0b8c4"), "power": 4},
    {"name": "Редкий", "color": Color("4aa8ff"), "power": 9},
    {"name": "Эпический", "color": Color("b05cff"), "power": 20},
    {"name": "Легендарный", "color": Color("ffb62e"), "power": 45},
    {"name": "Мифический", "color": Color("ff4f7b"), "power": 100},
]

var ABILITY_KEYS = ["power", "coins", "xp", "speed"]
var ABILITY_NAMES = {"power": "Сила", "coins": "Монетный магнит", "xp": "Мудрость", "speed": "Быстрые лапки"}
var ABILITY_UNIT = {"power": 0.04, "coins": 0.05, "xp": 0.05, "speed": 0.02}
var ABILITY_DESC = {"power": "урон героя", "coins": "монеты", "xp": "опыт", "speed": "скорость бега"}

var REGIONS = [
    {"id": "green", "name": "Зелёные Холмы", "ground": Color("5fae4a"), "sky_top": Color("4f9cf0"), "sky_hor": Color("cfe9ff"),
     "fog": Color("cfe6d6"), "fog_density": 0.004, "eggs": ["common", "forest", "rare"], "weather": "leaves",
     "gate_boss": "forest_guardian", "gate_cost": 300, "enemy": "Слизень"},
    {"id": "ice", "name": "Ледяная Долина", "ground": Color("d8eefc"), "sky_top": Color("7fb7e6"), "sky_hor": Color("e4f4ff"),
     "fog": Color("dcefff"), "fog_density": 0.012, "eggs": ["ice", "epic"], "weather": "snow",
     "gate_boss": "ice_titan", "gate_cost": 1500, "enemy": "Снежный монстр"},
    {"id": "fire", "name": "Огненные Земли", "ground": Color("3a2c2c"), "sky_top": Color("4a1c14"), "sky_hor": Color("ff7a33"),
     "fog": Color("5a2a1c"), "fog_density": 0.010, "eggs": ["fire", "legendary"], "weather": "embers",
     "gate_boss": "fire_dragon", "gate_cost": 5000, "enemy": "Огненный бес"},
    {"id": "sky", "name": "Небесные Острова", "ground": Color("eef4ff"), "sky_top": Color("3b86ff"), "sky_hor": Color("ffe3f4"),
     "fog": Color("e9f2ff"), "fog_density": 0.003, "eggs": ["sky", "rainbow", "magic"], "weather": "sparkles",
     "gate_boss": "sky_golem", "gate_cost": 12000, "enemy": "Облачный дух"},
    {"id": "dark", "name": "Тёмное Королевство", "ground": Color("2c1f3d"), "sky_top": Color("120a24"), "sky_hor": Color("5b2a86"),
     "fog": Color("3b1f58"), "fog_density": 0.018, "eggs": ["shadow", "mythic"], "weather": "motes",
     "gate_boss": "", "gate_cost": 0, "enemy": "Тёмная тень"},
]

var EGGS = [
    {"id": "common", "name": "Обычное яйцо", "price": 100, "cur": "coins", "color": Color("e8dcc0"), "accent": Color("a58f6a"), "pattern": "plain"},
    {"id": "forest", "name": "Лесное яйцо", "price": 250, "cur": "coins", "color": Color("7bc66a"), "accent": Color("3d7a34"), "pattern": "spots"},
    {"id": "rare", "name": "Редкое яйцо", "price": 600, "cur": "coins", "color": Color("5aa9ff"), "accent": Color("ffffff"), "pattern": "stripes"},
    {"id": "epic", "name": "Эпическое яйцо", "price": 1500, "cur": "coins", "color": Color("b05cff"), "accent": Color("ffd0ff"), "pattern": "zigzag"},
    {"id": "legendary", "name": "Легендарное яйцо", "price": 4000, "cur": "coins", "color": Color("ffb62e"), "accent": Color("fff2b0"), "pattern": "stripes"},
    {"id": "mythic", "name": "Мифическое яйцо", "price": 25, "cur": "gems", "color": Color("ff4f7b"), "accent": Color("ffd1dc"), "pattern": "spots"},
    {"id": "ice", "name": "Ледяное яйцо", "price": 800, "cur": "coins", "color": Color("bfeaff"), "accent": Color("5fb8ff"), "pattern": "zigzag"},
    {"id": "fire", "name": "Огненное яйцо", "price": 1200, "cur": "coins", "color": Color("ff6a2a"), "accent": Color("ffd24a"), "pattern": "zigzag"},
    {"id": "shadow", "name": "Теневое яйцо", "price": 3000, "cur": "coins", "color": Color("3a2a55"), "accent": Color("9b5cff"), "pattern": "spots"},
    {"id": "sky", "name": "Небесное яйцо", "price": 3500, "cur": "coins", "color": Color("9fd8ff"), "accent": Color("ffffff"), "pattern": "stripes"},
    {"id": "rainbow", "name": "Радужное яйцо", "price": 40, "cur": "gems", "color": Color("ffffff"), "accent": Color("ff7fd0"), "pattern": "rainbow"},
    {"id": "magic", "name": "Магическое яйцо", "price": 6000, "cur": "coins", "color": Color("6a5cff"), "accent": Color("ffd0ff"), "pattern": "spots"},
    {"id": "dragon", "name": "Драконье яйцо", "price": 60, "cur": "gems", "color": Color("2f9e5b"), "accent": Color("ffcf3a"), "pattern": "zigzag"},
    {"id": "cosmic", "name": "Космическое яйцо", "price": 100, "cur": "gems", "color": Color("1b1b3a"), "accent": Color("6af0ff"), "pattern": "spots"},
    {"id": "divine", "name": "Божественное яйцо", "price": 250, "cur": "gems", "color": Color("fff3b0"), "accent": Color("ffffff"), "pattern": "rainbow"},
]

var PETS = []
var BOSSES = [
    {"id": "forest_guardian", "name": "Страж Леса", "region": 0, "pos": Vector2(60, -60), "hp": 600, "dmg": 12, "speed": 3.2, "scale": 2.2,
     "color": Color("3f7a3a"), "coins": 400, "gems": 2, "crystals": 3, "xp": 300, "egg": "forest"},
    {"id": "skeleton_king", "name": "Король Скелетов", "region": 0, "pos": Vector2(-60, 70), "hp": 900, "dmg": 15, "speed": 3.6, "scale": 2.0,
     "color": Color("e8e4d0"), "coins": 600, "gems": 3, "crystals": 4, "xp": 450, "egg": "rare"},
    {"id": "ice_titan", "name": "Ледяной Титан", "region": 1, "pos": Vector2(50, -70), "hp": 1800, "dmg": 20, "speed": 3.0, "scale": 3.0,
     "color": Color("9fdcff"), "coins": 1000, "gems": 4, "crystals": 6, "xp": 800, "egg": "ice"},
    {"id": "cursed_dumpling", "name": "Проклятый Пельмень", "region": 1, "pos": Vector2(-60, 60), "hp": 2200, "dmg": 24, "speed": 4.0, "scale": 2.4,
     "color": Color("7a4aa0"), "coins": 1200, "gems": 5, "crystals": 6, "xp": 1000, "egg": "epic"},
    {"id": "fire_dragon", "name": "Огненный Дракон", "region": 2, "pos": Vector2(60, 60), "hp": 3500, "dmg": 30, "speed": 4.2, "scale": 3.2,
     "color": Color("e0402a"), "coins": 2500, "gems": 8, "crystals": 10, "xp": 1800, "egg": "dragon"},
    {"id": "ancient_guard", "name": "Древний Страж", "region": 2, "pos": Vector2(-60, -60), "hp": 4200, "dmg": 34, "speed": 3.4, "scale": 3.0,
     "color": Color("7a6a58"), "coins": 3000, "gems": 8, "crystals": 10, "xp": 2200, "egg": "fire"},
    {"id": "sky_golem", "name": "Небесный Голем", "region": 3, "pos": Vector2(60, -60), "hp": 6000, "dmg": 38, "speed": 3.6, "scale": 3.4,
     "color": Color("cfe0ff"), "coins": 5000, "gems": 12, "crystals": 14, "xp": 3500, "egg": "sky"},
    {"id": "cosmic_beast", "name": "Космический Зверь", "region": 3, "pos": Vector2(-60, 60), "hp": 7500, "dmg": 44, "speed": 4.8, "scale": 3.0,
     "color": Color("3a4cff"), "coins": 6000, "gems": 15, "crystals": 16, "xp": 4500, "egg": "cosmic"},
    {"id": "shadow_lord", "name": "Повелитель Теней", "region": 4, "pos": Vector2(60, 60), "hp": 10000, "dmg": 52, "speed": 5.0, "scale": 3.2,
     "color": Color("2a1a45"), "coins": 9000, "gems": 20, "crystals": 20, "xp": 7000, "egg": "shadow"},
    {"id": "egg_king", "name": "Король Яиц", "region": 4, "pos": Vector2(0, -95), "hp": 20000, "dmg": 65, "speed": 4.6, "scale": 5.0,
     "color": Color("ffd24a"), "coins": 25000, "gems": 60, "crystals": 50, "xp": 20000, "egg": "divine"},
]

var UPGRADES = [
    {"key": "damage", "name": "Сила удара", "desc": "+3 к урону за уровень", "cur": "coins", "base": 150, "max": 20},
    {"key": "hp", "name": "Здоровье", "desc": "+20 к максимуму здоровья", "cur": "coins", "base": 120, "max": 20},
    {"key": "speed", "name": "Скорость", "desc": "+4% к скорости бега", "cur": "coins", "base": 200, "max": 10},
    {"key": "crit", "name": "Меткость", "desc": "+2% к шансу крита", "cur": "crystals", "base": 3, "max": 10},
    {"key": "luck", "name": "Удача", "desc": "+10% к шансу редкого питомца в яйцах", "cur": "crystals", "base": 5, "max": 10},
]

var COSMETICS = {
    "default": {"name": "Красная шапка", "color": Color("e04a3a"), "cur": "coins", "price": 0},
    "blue": {"name": "Синяя шапка", "color": Color("3a7ae0"), "cur": "coins", "price": 500},
    "pink": {"name": "Розовая шапка", "color": Color("ff7fb8"), "cur": "coins", "price": 800},
    "gold": {"name": "Золотая шапка", "color": Color("ffc83a"), "cur": "gems", "price": 5},
    "dark": {"name": "Тёмная шапка", "color": Color("3a3050"), "cur": "gems", "price": 10},
}

var BOOSTERS = [
    {"key": "coins", "name": "x2 монеты на 10 минут", "price": 5, "cur": "gems", "time": 600.0},
    {"key": "xp", "name": "x2 опыт на 10 минут", "price": 5, "cur": "gems", "time": 600.0},
]

var TITLES = [
    {"name": "Новичок", "key": "level", "target": 1},
    {"name": "Охотник за яйцами", "key": "eggs_found", "target": 10},
    {"name": "Укротитель", "key": "pets", "target": 10},
    {"name": "Победитель боссов", "key": "bosses", "target": 3},
    {"name": "Герой", "key": "level", "target": 20},
    {"name": "Коллекционер", "key": "collection", "target": 25},
    {"name": "Король яиц", "key": "boss:egg_king", "target": 1},
]

var DAILY_TEMPLATES = [
    {"key": "d_kills", "title": "Победи врагов: %d", "target": 15, "reward": {"coins": 300, "tokens": 1}},
    {"key": "d_eggs", "title": "Открой яиц: %d", "target": 3, "reward": {"coins": 250, "tokens": 1}},
    {"key": "d_found", "title": "Найди яиц в мире: %d", "target": 3, "reward": {"coins": 250, "tokens": 1}},
    {"key": "d_boss", "title": "Победи боссов: %d", "target": 1, "reward": {"gems": 3, "tokens": 2}},
]

var STORY = []
var SIDE = []
var SECRET = []
var ACHIEVEMENTS = []

var _egg_idx = {}
var _pet_idx = {}
var _boss_idx = {}


func _ready():
    _build_pets()
    _build_quests()
    for e in EGGS:
        _egg_idx[e.id] = e
    for p in PETS:
        _pet_idx[p.id] = p
    for b in BOSSES:
        _boss_idx[b.id] = b


func _build_pets():
    # [яйцо, имя, редкость, цвет, форма]. Первый питомец яйца выпадает с весом 75, второй — 25.
    var raw = [
        ["common", "Зелёный дракончик", 0, "6fcf5a", "dragon"], ["common", "Пельмешек-малыш", 0, "efd9b0", "dumpling"],
        ["forest", "Лесной зайчик", 0, "8fd16a", "bunny"], ["forest", "Грибной гном", 1, "d95a5a", "blob"],
        ["rare", "Синий котик", 1, "5aa9ff", "cat"], ["rare", "Лазурный волк", 1, "3a7bd5", "wolf"],
        ["epic", "Магический кролик", 2, "b05cff", "bunny"], ["epic", "Кристальный голем", 2, "7fe0ff", "golem"],
        ["legendary", "Золотой пельмень", 3, "ffc83a", "dumpling"], ["legendary", "Золотой лев", 3, "ffb62e", "cat"],
        ["mythic", "Алый феникс", 4, "ff4f7b", "dragon"], ["mythic", "Розовый дух", 4, "ff9ec4", "ghost"],
        ["ice", "Ледяной волк", 1, "bfeaff", "wolf"], ["ice", "Снежный лис", 2, "e8f8ff", "fox"],
        ["fire", "Огненная лиса", 2, "ff6a2a", "fox"], ["fire", "Лавовый голем", 2, "ff8a3a", "golem"],
        ["shadow", "Тёмный призрак", 2, "4a3a6a", "ghost"], ["shadow", "Теневой кот", 3, "2a1f45", "cat"],
        ["sky", "Облачный котёнок", 2, "cfe9ff", "cat"], ["sky", "Небесный дракон", 3, "7fb7ff", "dragon"],
        ["rainbow", "Радужный кот", 3, "ff7fd0", "cat"], ["rainbow", "Радужный дракон", 4, "7fffd0", "dragon"],
        ["magic", "Звёздный кролик", 3, "7a6aff", "bunny"], ["magic", "Волшебный монстрик", 3, "b05cff", "monster"],
        ["dragon", "Миниатюрный дракончик", 3, "ff4a3a", "dragon"], ["dragon", "Древний дракон", 4, "2f9e5b", "dragon"],
        ["cosmic", "Космический монстр", 4, "4a5cff", "monster"], ["cosmic", "Звёздный призрак", 4, "6af0ff", "ghost"],
        ["divine", "Божественный пельмень", 4, "fff3b0", "dumpling"], ["divine", "Ангельский феникс", 4, "ffffff", "dragon"],
    ]
    var seen = {}
    var i = 0
    for r in raw:
        var w = 25 if seen.has(r[0]) else 75
        seen[r[0]] = true
        PETS.append({"id": "pet_%d" % i, "egg": r[0], "name": r[1], "rarity": r[2], "color": Color(r[3]),
            "shape": r[4], "weight": w, "ability": ABILITY_KEYS[i % 4], "pitch": 0.8 + 0.03 * i})
        i += 1


func _q(id, title, key, target, reward):
    return {"id": id, "title": title, "key": key, "target": target, "reward": reward}


func _build_quests():
    STORY = [
        _q("st1", "Найди 5 яиц в Зелёных Холмах", "eggs_found_r0", 5, {"coins": 200, "gems": 2}),
        _q("st2", "Собери трёх питомцев", "pets", 3, {"coins": 300}),
        _q("st3", "Победи Стража Леса", "boss:forest_guardian", 1, {"coins": 500, "gems": 3, "egg": "rare"}),
        _q("st4", "Открой путь в Ледяную Долину", "regions", 2, {"coins": 600}),
        _q("st5", "Открой 10 яиц", "eggs_opened", 10, {"gems": 5}),
        _q("st6", "Победи Ледяного Титана", "boss:ice_titan", 1, {"coins": 1200, "gems": 5, "egg": "epic"}),
        _q("st7", "Открой путь в Огненные Земли", "regions", 3, {"coins": 1500}),
        _q("st8", "Достигни 10 уровня", "level", 10, {"gems": 8, "crystals": 5}),
        _q("st9", "Победи Огненного Дракона", "boss:fire_dragon", 1, {"gems": 10, "crystals": 8, "egg": "dragon"}),
        _q("st10", "Открой путь на Небесные Острова", "regions", 4, {"coins": 4000}),
        _q("st11", "Победи Небесного Голема", "boss:sky_golem", 1, {"gems": 15, "crystals": 10}),
        _q("st12", "Открой путь в Тёмное Королевство", "regions", 5, {"coins": 8000}),
        _q("st13", "Победи Повелителя Теней", "boss:shadow_lord", 1, {"gems": 25, "crystals": 15}),
        _q("st14", "Победи Короля Яиц", "boss:egg_king", 1, {"gems": 100, "tokens": 20}),
    ]
    SIDE = [
        _q("sd1", "Победи 25 врагов", "kills", 25, {"coins": 250}),
        _q("sd2", "Победи 100 врагов", "kills", 100, {"coins": 800, "gems": 2}),
        _q("sd3", "Победи 300 врагов", "kills", 300, {"coins": 2500, "gems": 6}),
        _q("sd4", "Найди 15 яиц в мире", "eggs_found", 15, {"coins": 600, "egg": "forest"}),
        _q("sd5", "Объедини питомцев", "merges", 1, {"coins": 400, "gems": 2}),
        _q("sd6", "Эволюционируй питомца", "evolutions", 1, {"gems": 5}),
        _q("sd7", "Собери 10 питомцев", "pets", 10, {"coins": 1000, "gems": 3}),
        _q("sd8", "Открой 5 сундуков", "chests", 5, {"coins": 700, "crystals": 2}),
    ]
    SECRET = [
        _q("sc1", "Охотник за сокровищами (найди 15 сундуков)", "chests", 15, {"gems": 10, "crystals": 5, "tokens": 3}),
        _q("sc2", "Яичный маньяк (открой 100 яиц)", "eggs_opened", 100, {"gems": 20, "tokens": 5}),
        _q("sc3", "Охотник на боссов (победи 5 боссов)", "bosses", 5, {"gems": 15, "crystals": 10}),
    ]
    ACHIEVEMENTS = [
        _q("ac1", "Первый питомец", "pets", 1, {"coins": 100}),
        _q("ac2", "Зверинец (20 питомцев)", "pets", 20, {"gems": 5, "tokens": 1}),
        _q("ac3", "Первая победа над боссом", "bosses", 1, {"gems": 3, "tokens": 1}),
        _q("ac4", "Уровень 20", "level", 20, {"gems": 10, "tokens": 2}),
        _q("ac5", "Открыть 25 яиц", "eggs_opened", 25, {"gems": 5}),
        _q("ac6", "Коллекционер (15 видов питомцев)", "collection", 15, {"gems": 10, "tokens": 2}),
        _q("ac7", "Все регионы открыты", "regions", 5, {"gems": 15, "tokens": 3}),
        _q("ac8", "Победить всех боссов", "bosses", 10, {"gems": 50, "tokens": 10}),
    ]


func egg(id):
    return _egg_idx.get(id, EGGS[0])


func pet(id):
    return _pet_idx.get(id, PETS[0])


func boss(id):
    return _boss_idx.get(id, BOSSES[0])


func pets_of_egg(egg_id):
    var res = []
    for p in PETS:
        if p.egg == egg_id:
            res.append(p)
    return res


func region_of_x(x):
    return clampi(int(floor((x + REGION_HALF) / REGION_SIZE)), 0, REGIONS.size() - 1)


func region_origin(i):
    return Vector3(i * REGION_SIZE, 0.0, 0.0)


func rarity_color(r):
    return RARITIES[clampi(r, 0, RARITIES.size() - 1)].color


func rarity_name(r):
    return RARITIES[clampi(r, 0, RARITIES.size() - 1)].name


func ability_text(ab, rarity):
    var v = ABILITY_UNIT[ab] * (rarity + 1) * 100.0
    return "%s: +%d%% к %s" % [ABILITY_NAMES[ab], int(round(v)), ABILITY_DESC[ab]]


func reward_text(rw):
    var parts = []
    var names = {"coins": "монет", "gems": "самоцв.", "crystals": "кристаллов", "tokens": "жетонов", "xp": "опыта"}
    for k in rw:
        if k == "egg":
            parts.append(egg(rw[k]).name)
        elif names.has(k):
            parts.append("%d %s" % [int(rw[k]), names[k]])
    return ", ".join(parts)
