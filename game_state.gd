extends Node
## Глобальное состояние: валюты, уровень, питомцы, задания, настройки.

signal currency_changed
signal stats_changed
signal pets_changed
signal message(text)
signal boss_bar(boss_name, hp, max_hp, shown)
signal region_changed(index)
signal player_died
signal quest_completed(title)
signal screen_flash(color, duration)
signal prompt_changed(text)
signal settings_changed
signal boss_music(active)
signal request_open_egg(egg_id, count)
signal request_menu
signal reveal_pet(pet)
signal cinematic(pos, dist, pitch, duration)
signal victory

var level = 1
var xp = 0
var coins = 0
var gems = 0
var crystals = 0
var tokens = 0
var hp = 100.0
var unlocked_regions = 1
var pets = []
var next_uid = 1
var eggs = {}
var discovered = []
var defeated_bosses = []
var opened_chests = []
var claimed = []
var stats = {}
var upgrades = {}
var pet_slots = 3
var cosmetic = "default"
var cosmetics_owned = ["default"]
var boosters = {"coins": 0.0, "xp": 0.0}
var settings = {}
var daily = {}

# Временные значения (не сохраняются)
var in_menu = true
var skip_menu = false
var windows_open = 0
var cinematic_busy = false
var player_node = null
var target_enemy = null
var touch_move = Vector2.ZERO
var cam_drag = Vector2.ZERO
var cam_zoom = 0.0
var cam_yaw = 0.0
var boss_fights = 0
var game_won = false
var ui_rects = []
var current_region = 0
var latched = {}
var _in_check = false


func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    _setup_input()
    new_game()


func _setup_input():
    var map = {
        "move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
        "move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
        "jump": [KEY_SPACE], "attack": [KEY_J], "special": [KEY_K], "dodge": [KEY_L],
        "interact": [KEY_F], "pets": [KEY_P], "sprint": [KEY_SHIFT], "dance": [KEY_G],
        "cam_left": [KEY_Q], "cam_right": [KEY_E],
    }
    for a in map:
        if not InputMap.has_action(a):
            InputMap.add_action(a)
        for k in map[a]:
            var ev = InputEventKey.new()
            ev.physical_keycode = k
            InputMap.action_add_event(a, ev)


func default_settings():
    return {"quality": 1, "music": 0.7, "sfx": 0.9, "ui": 0.9, "cam_sens": 1.0, "btn_scale": 1.0,
        "vibration": true, "fast_open": false, "cam_invert": false}


func new_game():
    level = 1
    xp = 0
    coins = 300
    gems = 0
    crystals = 0
    tokens = 0
    unlocked_regions = 1
    pets = []
    next_uid = 1
    eggs = {"common": 2}
    discovered = []
    defeated_bosses = []
    opened_chests = []
    claimed = []
    stats = {"kills": 0, "eggs_opened": 0, "eggs_found": 0, "eggs_found_r0": 0, "chests": 0,
        "evolutions": 0, "merges": 0, "deaths": 0}
    upgrades = {"damage": 0, "hp": 0, "speed": 0, "crit": 0, "luck": 0}
    pet_slots = 3
    cosmetic = "default"
    cosmetics_owned = ["default"]
    boosters = {"coins": 0.0, "xp": 0.0}
    settings = default_settings()
    daily = {"date_num": 0, "streak": 0, "claimed": false, "counts": {}, "quests": []}
    hp = max_hp()
    refresh_daily()


func to_dict():
    return {"level": level, "xp": xp, "coins": coins, "gems": gems, "crystals": crystals, "tokens": tokens,
        "unlocked_regions": unlocked_regions, "pets": pets, "next_uid": next_uid, "eggs": eggs,
        "discovered": discovered, "defeated_bosses": defeated_bosses, "opened_chests": opened_chests,
        "claimed": claimed, "stats": stats, "upgrades": upgrades, "pet_slots": pet_slots,
        "cosmetic": cosmetic, "cosmetics_owned": cosmetics_owned, "boosters": boosters,
        "settings": settings, "daily": daily}


func from_dict(d):
    new_game()
    level = int(d.get("level", 1))
    xp = int(d.get("xp", 0))
    coins = int(d.get("coins", 0))
    gems = int(d.get("gems", 0))
    crystals = int(d.get("crystals", 0))
    tokens = int(d.get("tokens", 0))
    unlocked_regions = clampi(int(d.get("unlocked_regions", 1)), 1, 5)
    next_uid = int(d.get("next_uid", 1))
    pet_slots = int(d.get("pet_slots", 3))
    cosmetic = str(d.get("cosmetic", "default"))
    pets = []
    for p in d.get("pets", []):
        if typeof(p) == TYPE_DICTIONARY and GameData._pet_idx.has(str(p.get("id", ""))):
            pets.append({"uid": int(p.get("uid", 0)), "id": str(p.id), "level": int(p.get("level", 1)),
                "stars": int(p.get("stars", 0)), "form": int(p.get("form", 0)),
                "equipped": bool(p.get("equipped", false)), "fav": bool(p.get("fav", false))})
    eggs = {}
    var e = d.get("eggs", {})
    for k in e:
        eggs[str(k)] = int(e[k])
    discovered = Array(d.get("discovered", []))
    defeated_bosses = Array(d.get("defeated_bosses", []))
    opened_chests = Array(d.get("opened_chests", []))
    claimed = Array(d.get("claimed", []))
    var st = d.get("stats", {})
    for k in st:
        stats[str(k)] = int(st[k])
    var up = d.get("upgrades", {})
    for k in up:
        upgrades[str(k)] = int(up[k])
    cosmetics_owned = Array(d.get("cosmetics_owned", ["default"]))
    var bo = d.get("boosters", {})
    for k in bo:
        boosters[str(k)] = float(bo[k])
    var s = d.get("settings", {})
    for k in s:
        settings[str(k)] = s[k]
    var dl = d.get("daily", {})
    if typeof(dl) == TYPE_DICTIONARY and dl.has("date_num"):
        daily = {"date_num": int(dl.get("date_num", 0)), "streak": int(dl.get("streak", 0)),
            "claimed": bool(dl.get("claimed", false)), "counts": dl.get("counts", {}), "quests": dl.get("quests", [])}
    refresh_daily()
    hp = max_hp()
    settings_changed.emit()
    currency_changed.emit()
    stats_changed.emit()
    pets_changed.emit()


func _process(delta):
    var ch = false
    for k in boosters:
        if boosters[k] > 0.0:
            boosters[k] = maxf(0.0, boosters[k] - delta)
            if boosters[k] == 0.0:
                ch = true
    if ch:
        currency_changed.emit()


# ---------- Валюты ----------
func get_cur(cur):
    match cur:
        "coins": return coins
        "gems": return gems
        "crystals": return crystals
        "tokens": return tokens
    return 0


func spend(cur, amount):
    if get_cur(cur) < amount:
        return false
    match cur:
        "coins": coins -= amount
        "gems": gems -= amount
        "crystals": crystals -= amount
        "tokens": tokens -= amount
    currency_changed.emit()
    return true


func gain_coins(base):
    var n = maxi(1, int(round(base * coin_mult())))
    coins += n
    currency_changed.emit()
    return n


func gain_xp(base):
    var n = maxi(1, int(round(base * xp_mult())))
    xp += n
    while xp >= xp_needed():
        xp -= xp_needed()
        level += 1
        hp = max_hp()
        message.emit("Новый уровень: %d!" % level)
        screen_flash.emit(Color(1, 0.95, 0.5, 0.45), 0.5)
        AudioManager.play_sfx("levelup")
    stats_changed.emit()
    _check_all()
    return n


func xp_needed():
    return int(60 * pow(level, 1.4))


func max_hp():
    return 100.0 + 15.0 * (level - 1) + 20.0 * upgrades.get("hp", 0)


func heal(n):
    hp = minf(max_hp(), hp + n)
    stats_changed.emit()


# ---------- Бонусы ----------
func equipped_pets():
    return pets.filter(func(p): return p.equipped)


func ability_bonus(ab):
    var total = 0.0
    for p in equipped_pets():
        var d = GameData.pet(p.id)
        if d.ability == ab:
            total += GameData.ABILITY_UNIT[ab] * (d.rarity + 1) * (1.0 + 0.2 * p.stars + 0.4 * p.form)
    return total


func attack_damage():
    return (12.0 + 2.0 * level + 3.0 * upgrades.get("damage", 0)) * (1.0 + ability_bonus("power"))


func crit_chance():
    return 0.10 + 0.02 * upgrades.get("crit", 0)


func speed_mult():
    return 1.0 + 0.04 * upgrades.get("speed", 0) + ability_bonus("speed")


func coin_mult():
    var m = 1.0 + ability_bonus("coins")
    if boosters.get("coins", 0.0) > 0.0:
        m *= 2.0
    return m


func xp_mult():
    var m = 1.0 + ability_bonus("xp")
    if boosters.get("xp", 0.0) > 0.0:
        m *= 2.0
    return m


func particle_scale():
    return [0.4, 0.7, 1.0][clampi(int(settings.get("quality", 1)), 0, 2)]


# ---------- Яйца и питомцы ----------
func add_egg(egg_id, n = 1):
    eggs[egg_id] = eggs.get(egg_id, 0) + n
    stats_changed.emit()


func egg_chances(egg_id):
    var pool = GameData.pets_of_egg(egg_id)
    var luck_f = 1.0 + 0.1 * upgrades.get("luck", 0)
    var ws = []
    var total = 0.0
    for i in pool.size():
        var w = float(pool[i].weight) * (luck_f if i > 0 else 1.0)
        ws.append(w)
        total += w
    var res = []
    for i in pool.size():
        res.append([pool[i], ws[i] / total * 100.0])
    return res


func open_egg(egg_id):
    if eggs.get(egg_id, 0) <= 0:
        return null
    eggs[egg_id] -= 1
    var chances = egg_chances(egg_id)
    var r = randf() * 100.0
    var chosen = chances[0][0]
    for c in chances:
        r -= c[1]
        if r <= 0.0:
            chosen = c[0]
            break
    stats.eggs_opened += 1
    var p = add_pet(chosen.id)
    bump_daily("d_eggs")
    return p


func add_pet(pet_id):
    var p = {"uid": next_uid, "id": pet_id, "level": 1, "stars": 0, "form": 0, "equipped": false, "fav": false}
    next_uid += 1
    pets.append(p)
    if not discovered.has(pet_id):
        discovered.append(pet_id)
    if equipped_pets().size() < pet_slots:
        p.equipped = true
    pets_changed.emit()
    _check_all()
    return p


func get_pet(uid):
    for p in pets:
        if p.uid == uid:
            return p
    return null


func pet_power(p):
    var d = GameData.pet(p.id)
    return GameData.RARITIES[d.rarity].power * (1.0 + 0.12 * (p.level - 1)) * (1.0 + 0.25 * p.stars) * pow(1.6, p.form)


func pet_title(p):
    var d = GameData.pet(p.id)
    var s = d.name
    if p.form > 0:
        s += " (форма %d)" % p.form
    if p.stars > 0:
        s += " +%d" % p.stars
    return s


func pet_level_cost(p):
    return int(50 * pow(1.35, p.level - 1) * (GameData.pet(p.id).rarity + 1))


func level_up_pet(uid):
    var p = get_pet(uid)
    if p == null or p.level >= 25:
        return false
    if not spend("coins", pet_level_cost(p)):
        return false
    p.level += 1
    pets_changed.emit()
    return true


func evolve_cost(p):
    return 4 * (p.form + 1)


func can_evolve(p):
    return p.form < 2 and p.level >= 8 * (p.form + 1)


func evolve_pet(uid):
    var p = get_pet(uid)
    if p == null or not can_evolve(p):
        return false
    if not spend("gems", evolve_cost(p)):
        return false
    p.form += 1
    stats.evolutions += 1
    pets_changed.emit()
    _check_all()
    return true


func merge_candidates(p):
    return pets.filter(func(o): return o.uid != p.uid and o.id == p.id and o.stars == p.stars and o.form == p.form and not o.equipped and not o.fav)


func merge_pet(uid):
    var p = get_pet(uid)
    if p == null or p.stars >= 5:
        return false
    var c = merge_candidates(p)
    if c.size() < 2:
        return false
    pets.erase(c[0])
    pets.erase(c[1])
    p.stars += 1
    stats.merges += 1
    pets_changed.emit()
    _check_all()
    return true


func toggle_equip(uid):
    var p = get_pet(uid)
    if p == null:
        return false
    if p.equipped:
        p.equipped = false
    else:
        if equipped_pets().size() >= pet_slots:
            message.emit("Нет свободных слотов питомцев")
            return false
        p.equipped = true
    pets_changed.emit()
    return true


func toggle_fav(uid):
    var p = get_pet(uid)
    if p != null:
        p.fav = not p.fav
        pets_changed.emit()


# ---------- Улучшения героя ----------
func upgrade_cost(u):
    return int(u.base * pow(1.55, upgrades.get(u.key, 0)))


func buy_upgrade(key):
    for u in GameData.UPGRADES:
        if u.key == key:
            if upgrades.get(key, 0) >= u.max:
                return false
            if not spend(u.cur, upgrade_cost(u)):
                return false
            upgrades[key] = upgrades.get(key, 0) + 1
            stats_changed.emit()
            return true
    return false


# ---------- Прогресс ----------
func record_kill():
    stats.kills += 1
    bump_daily("d_kills")


func record_world_egg(region):
    stats.eggs_found += 1
    if region == 0:
        stats.eggs_found_r0 += 1
    bump_daily("d_found")


func record_chest(id):
    opened_chests.append(id)
    stats.chests += 1
    _check_all()


func boss_defeated(id):
    if not defeated_bosses.has(id):
        defeated_bosses.append(id)
    bump_daily("d_boss")
    _check_all()


func unlock_next_region():
    unlocked_regions = mini(5, unlocked_regions + 1)
    _check_all()


func stat_value(key):
    if key.begins_with("boss:"):
        return 1 if defeated_bosses.has(key.substr(5)) else 0
    if key.begins_with("d_"):
        return int(daily.counts.get(key, 0))
    match key:
        "pets": return pets.size()
        "level": return level
        "regions": return unlocked_regions
        "bosses": return defeated_bosses.size()
        "collection": return discovered.size()
    return int(stats.get(key, 0))


func current_title():
    var best = GameData.TITLES[0].name
    for t in GameData.TITLES:
        if stat_value(t.key) >= t.target:
            best = t.name
    return best


func active_story():
    for q in GameData.STORY:
        if not claimed.has(q.id):
            return q
    return null


func give_reward(rw):
    for k in rw:
        match k:
            "coins": coins += int(rw[k])
            "gems": gems += int(rw[k])
            "crystals": crystals += int(rw[k])
            "tokens": tokens += int(rw[k])
            "xp": gain_xp(int(rw[k]))
            "egg": add_egg(str(rw[k]), 1)
    currency_changed.emit()


func _check_all():
    if _in_check:
        return
    _in_check = true
    var changed = true
    var guard = 0
    while changed and guard < 6:
        changed = false
        guard += 1
        for list in [GameData.STORY, GameData.SIDE, GameData.SECRET, GameData.ACHIEVEMENTS, daily.quests]:
            for q in list:
                if not claimed.has(q.id) and stat_value(q.key) >= int(q.target):
                    claimed.append(q.id)
                    give_reward(q.reward)
                    quest_completed.emit(q.title)
                    changed = true
    _in_check = false
    stats_changed.emit()


# ---------- Ежедневные задания и награды ----------
func today_num():
    return int(Time.get_unix_time_from_system() / 86400.0)


func refresh_daily():
    var t = today_num()
    if daily.date_num != t:
        if daily.date_num != t - 1:
            daily.streak = 0
        daily.date_num = t
        daily.claimed = false
        daily.counts = {}
        claimed = claimed.filter(func(id): return not str(id).begins_with("d_"))
        var rng = RandomNumberGenerator.new()
        rng.seed = t
        var idx = [0, 1, 2, 3]
        for i in range(3, 0, -1):
            var j = rng.randi_range(0, i)
            var tmp = idx[i]
            idx[i] = idx[j]
            idx[j] = tmp
        daily.quests = []
        for i in 3:
            var tpl = GameData.DAILY_TEMPLATES[idx[i]]
            daily.quests.append({"id": "%s_%d" % [tpl.key, t], "title": tpl.title % tpl.target, "key": tpl.key,
                "target": tpl.target, "reward": tpl.reward})


func bump_daily(key, n = 1):
    daily.counts[key] = int(daily.counts.get(key, 0)) + n
    _check_all()


func claim_login():
    if daily.claimed:
        return false
    daily.claimed = true
    daily.streak += 1
    var s = daily.streak
    var c = 200 * mini(s, 7)
    coins += c
    var msg = "Ежедневная награда: %d монет" % c
    if s % 3 == 0:
        gems += 3
        msg += ", 3 самоцвета"
    if s % 7 == 0:
        tokens += 2
        crystals += 2
        msg += ", 2 жетона, 2 кристалла"
    currency_changed.emit()
    message.emit(msg)
    return true


# ---------- Окна ----------
func window_opened():
    windows_open += 1
    get_tree().paused = true


func window_closed():
    windows_open = maxi(0, windows_open - 1)
    if windows_open == 0:
        get_tree().paused = false
