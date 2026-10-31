extends Node3D
## Точка входа: собирает мир, героя, камеру, питомцев, интерфейс и связывает системы.

const WorldScript = preload("res://scripts/world/world.gd")
const PlayerScript = preload("res://scripts/player/player.gd")
const CameraRig = preload("res://scripts/player/camera_rig.gd")
const PetManager = preload("res://scripts/pets/pet_manager.gd")
const EggOpening = preload("res://scripts/pets/egg_opening.gd")
const HudScript = preload("res://scripts/ui/hud.gd")

var world
var player
var rig
var hud


func _ready():
    randomize()
    world = WorldScript.new()
    add_child(world)
    player = PlayerScript.new()
    add_child(player)
    player.position = Vector3(0, 1.5, 10)
    rig = CameraRig.new()
    add_child(rig)
    rig.global_position = Vector3(0, 3, 20)
    rig.set_player(player)
    add_child(PetManager.new())
    var eo = EggOpening.new()
    add_child(eo)
    var layer = CanvasLayer.new()
    add_child(layer)
    hud = HudScript.new()
    layer.add_child(hud)
    eo.hud = hud
    hud.menu_play.connect(_on_menu_play)
    GameState.request_menu.connect(_show_menu)
    GameState.boss_music.connect(_on_boss_music)
    GameState.region_changed.connect(_on_region)
    GameState.settings_changed.connect(AudioManager.apply_volumes)
    if GameState.skip_menu:
        GameState.skip_menu = false
        _start_game()
    else:
        _show_menu()


func _show_menu():
    GameState.in_menu = true
    GameState.boss_fights = 0
    hud.set_in_menu(true)
    AudioManager.play_music("menu")


func _start_game():
    GameState.in_menu = false
    GameState.hp = GameState.max_hp()
    GameState.refresh_daily()
    hud.set_in_menu(false)
    hud.refresh()
    AudioManager.play_music(GameState.current_region)
    if not GameState.daily.claimed:
        GameState.message.emit("Доступна ежедневная награда (окно «Задания»)")
    var q = GameState.active_story()
    if q != null:
        GameState.message.emit("Задание: " + q.title)
    SaveSystem.save_game()


func _on_menu_play(new_game):
    if new_game:
        GameState.new_game()
        GameState.skip_menu = true
        SaveSystem.save_game()
        get_tree().reload_current_scene()
        return
    _start_game()


func _on_boss_music(active):
    if GameState.in_menu:
        return
    if active:
        AudioManager.play_music("boss")
    else:
        AudioManager.play_music(GameState.current_region)


func _on_region(i):
    if GameState.in_menu or GameState.boss_fights > 0:
        return
    AudioManager.play_music(i)
