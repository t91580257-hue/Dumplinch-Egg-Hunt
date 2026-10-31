extends SceneTree
## Проверка проекта без запуска игры: godot --headless --path . --script res://scripts/tools/validate_project.gd
## Загружает все скрипты, сцены и шейдеры; завершается с кодом 1, если что-то не загрузилось.


func _scan(path, out):
    for f in DirAccess.get_files_at(path):
        if f.get_extension() in ["gd", "tscn", "tres", "gdshader"]:
            out.append(path.path_join(f))
    for d in DirAccess.get_directories_at(path):
        if not d.begins_with(".") and d != "build":
            _scan(path.path_join(d), out)


func _init():
    var files = []
    _scan("res://", files)
    var errors = 0
    for f in files:
        var r = load(f)
        if r == null:
            print("ОШИБКА загрузки: ", f)
            errors += 1
        elif r is GDScript and not r.can_instantiate():
            print("ОШИБКА скрипта: ", f)
            errors += 1
    print("Проверено файлов: %d, ошибок: %d" % [files.size(), errors])
    quit(1 if errors > 0 else 0)
