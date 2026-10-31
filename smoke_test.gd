extends SceneTree
## Дымовой тест: godot --headless --path . --script res://scripts/tools/smoke_test.gd
## Запускает главную сцену на ~300 кадров, «нажимает Играть», открывает яйцо. Ошибки видны в логе.

var frames = 0
var main


func _initialize():
    main = load("res://scenes/main.tscn").instantiate()
    root.add_child(main)


func _process(_delta):
    frames += 1
    var gs = root.get_node("GameState")
    if frames == 20:
        gs.in_menu = false
        main.hud.set_in_menu(false)
    if frames == 60:
        gs.request_open_egg.emit("common", 1)
    if frames == 400:
        print("SMOKE_OK pets=", gs.pets.size())
        quit(0)
