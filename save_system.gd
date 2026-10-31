extends Node
## Сохранение в user://dumplinch_save.json (с резервной копией), автосохранение и сохранение при выходе.

const SAVE_PATH = "user://dumplinch_save.json"
const BACKUP_PATH = "user://dumplinch_save.bak"
var _timer = 0.0


func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    load_game()


func has_save():
    return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BACKUP_PATH)


func save_game():
    var data = GameState.to_dict()
    data["version"] = 1
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
    var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f == null:
        push_warning("Не удалось открыть файл сохранения")
        return false
    f.store_string(JSON.stringify(data))
    f.close()
    return true


func load_game():
    for path in [SAVE_PATH, BACKUP_PATH]:
        if FileAccess.file_exists(path):
            var f = FileAccess.open(path, FileAccess.READ)
            if f == null:
                continue
            var parsed = JSON.parse_string(f.get_as_text())
            f.close()
            if typeof(parsed) == TYPE_DICTIONARY:
                GameState.from_dict(parsed)
                return true
    GameState.new_game()
    return false


func _process(delta):
    _timer += delta
    if _timer > 30.0:
        _timer = 0.0
        if not GameState.in_menu:
            save_game()


func _notification(what):
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_GO_BACK_REQUEST:
        if not GameState.in_menu:
            save_game()
