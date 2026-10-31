extends "res://scripts/ui/window_base.gd"
## Результаты открытия нескольких яиц.

var results = []


func _init():
    super("Добыча")


func show_results(list):
    results = list
    open()


func build(box):
    box.add_child(UIF.label("Получено питомцев: %d" % results.size(), 26, Color("ffd24a")))
    for p in results:
        var d = GameData.pet(p.id)
        var v = UIF.card(box, Color(0.14, 0.17, 0.35, 0.95))
        v.add_child(UIF.label("%s  -  %s" % [d.name, GameData.rarity_name(d.rarity)], 24, GameData.rarity_color(d.rarity).lightened(0.25)))
        v.add_child(UIF.label(GameData.ability_text(d.ability, d.rarity), 18, Color(0.8, 0.85, 1.0), true))
