extends "res://scripts/ui/window_base.gd"
## Задания: ежедневная награда, ежедневные, сюжетные, побочные и секретные.


func _init():
    super("Задания")


func _claim():
    if GameState.claim_login():
        AudioManager.play_ui("reward")
    refresh_all()


func _quest_row(box, q, hidden = false):
    var done = GameState.claimed.has(q.id)
    var v = UIF.card(box, Color(0.1, 0.25, 0.15, 0.9) if done else Color(0.12, 0.15, 0.3, 0.9))
    var title = "???" if (hidden and not done) else q.title
    v.add_child(UIF.label(title + ("  (выполнено)" if done else ""), 21, Color("9fe8a0") if done else Color.WHITE, true))
    if hidden and not done:
        return
    var cur = mini(GameState.stat_value(q.key), int(q.target))
    var b = UIF.bar(Color("4aa8ff"), 18, 200)
    b.max_value = int(q.target)
    b.value = cur
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    v.add_child(b)
    v.add_child(UIF.label("%d / %d     Награда: %s" % [cur, int(q.target), GameData.reward_text(q.reward)], 17, Color(0.8, 0.85, 1.0), true))


func build(box):
    var v = UIF.card(box, Color(0.2, 0.16, 0.3, 0.95))
    v.add_child(UIF.label("Ежедневная награда (серия: %d)" % GameState.daily.streak, 24, Color("ffd24a")))
    var b = UIF.button("Забрать награду" if not GameState.daily.claimed else "Уже получено сегодня", Vector2(0, 56), 20)
    b.disabled = GameState.daily.claimed
    b.pressed.connect(_claim)
    v.add_child(b)
    box.add_child(UIF.label("Ежедневные", 28, Color("ffd24a")))
    for q in GameState.daily.quests:
        _quest_row(box, q)
    box.add_child(UIF.label("Сюжетные", 28, Color("ffd24a")))
    var act = GameState.active_story()
    for q in GameData.STORY:
        if GameState.claimed.has(q.id) or q == act:
            _quest_row(box, q)
    box.add_child(UIF.label("Побочные", 28, Color("ffd24a")))
    for q in GameData.SIDE:
        _quest_row(box, q)
    box.add_child(UIF.label("Секретные", 28, Color("ffd24a")))
    for q in GameData.SECRET:
        _quest_row(box, q, true)
