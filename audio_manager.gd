extends Node
## Звук без внешних файлов: все эффекты и музыка синтезируются кодом (свободны от лицензий).
## Шины: Music, SFX, UI (громкость настраивается в меню).

const RATE = 22050
var _sfx = {}
var _music_cache = {}
var _music_player
var _ui_player
var _pool = []
var _pool_i = 0
var _current = ""

var MUSIC = {
    "0": {"root": 220.0, "scale": [0, 2, 4, 7, 9], "bpm": 108, "kind": "sine"},
    "1": {"root": 261.6, "scale": [0, 3, 5, 7, 10], "bpm": 78, "kind": "sine"},
    "2": {"root": 146.8, "scale": [0, 1, 5, 7, 8], "bpm": 126, "kind": "saw"},
    "3": {"root": 329.6, "scale": [0, 2, 4, 7, 9], "bpm": 98, "kind": "sine"},
    "4": {"root": 123.5, "scale": [0, 2, 3, 7, 8], "bpm": 88, "kind": "saw"},
    "menu": {"root": 261.6, "scale": [0, 2, 4, 7, 9], "bpm": 94, "kind": "sine"},
    "boss": {"root": 110.0, "scale": [0, 1, 3, 6, 7], "bpm": 150, "kind": "square"},
}


func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    for n in ["Music", "SFX", "UI"]:
        if AudioServer.get_bus_index(n) == -1:
            AudioServer.add_bus()
            var idx = AudioServer.bus_count - 1
            AudioServer.set_bus_name(idx, n)
            AudioServer.set_bus_send(idx, "Master")
    _music_player = AudioStreamPlayer.new()
    _music_player.bus = "Music"
    add_child(_music_player)
    _ui_player = AudioStreamPlayer.new()
    _ui_player.bus = "UI"
    add_child(_ui_player)
    for i in 10:
        var p = AudioStreamPlayer.new()
        p.bus = "SFX"
        add_child(p)
        _pool.append(p)
    _build_sfx()
    apply_volumes()


func apply_volumes():
    var map = {"Music": "music", "SFX": "sfx", "UI": "ui"}
    for bus in map:
        var i = AudioServer.get_bus_index(bus)
        var v = float(GameState.settings.get(map[bus], 0.8))
        AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0001)))
        AudioServer.set_bus_mute(i, v <= 0.001)


func _wave(samples):
    var bytes = PackedByteArray()
    bytes.resize(samples.size() * 2)
    for i in samples.size():
        bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
    var w = AudioStreamWAV.new()
    w.format = AudioStreamWAV.FORMAT_16_BITS
    w.mix_rate = RATE
    w.stereo = false
    w.data = bytes
    return w


func _tone(freq, dur, kind = "sine", decay = 4.0, vol = 0.5, slide = 0.0):
    var n = int(RATE * dur)
    var out = PackedFloat32Array()
    out.resize(n)
    var phase = 0.0
    for i in n:
        var t = float(i) / RATE
        phase += TAU * (freq + slide * t) / RATE
        var s = 0.0
        match kind:
            "sine": s = sin(phase)
            "square": s = 1.0 if sin(phase) > 0.0 else -1.0
            "saw": s = fposmod(phase / TAU, 1.0) * 2.0 - 1.0
            "noise": s = randf() * 2.0 - 1.0
        var env = minf(1.0, t * 200.0) * exp(-decay * t / dur) * minf(1.0, (dur - t) * 80.0)
        out[i] = s * env * vol
    return out


func _cat(arr):
    var out = PackedFloat32Array()
    for a in arr:
        out.append_array(a)
    return out


func _arp(freqs, dur = 0.09, kind = "square", vol = 0.3):
    var parts = []
    for f in freqs:
        parts.append(_tone(f, dur, kind, 3.0, vol))
    return _cat(parts)


func _build_sfx():
    _sfx["click"] = _wave(_tone(900, 0.05, "square", 6.0, 0.22))
    _sfx["jump"] = _wave(_tone(300, 0.18, "sine", 3.0, 0.45, 900.0))
    _sfx["hit"] = _wave(_tone(180, 0.12, "noise", 6.0, 0.5))
    _sfx["crit"] = _wave(_cat([_tone(180, 0.1, "noise", 6.0, 0.5), _tone(1200, 0.12, "square", 5.0, 0.3)]))
    _sfx["coin"] = _wave(_arp([988.0, 1319.0], 0.08))
    _sfx["shake"] = _wave(_tone(120, 0.15, "saw", 3.0, 0.4))
    _sfx["crack"] = _wave(_tone(80, 0.3, "noise", 4.0, 0.6))
    _sfx["pop"] = _wave(_tone(400, 0.35, "sine", 3.0, 0.6, 1200.0))
    _sfx["reward"] = _wave(_arp([523.0, 659.0, 784.0, 1047.0], 0.1))
    _sfx["levelup"] = _wave(_arp([523.0, 659.0, 784.0, 1047.0, 1319.0], 0.09))
    _sfx["roar"] = _wave(_tone(70, 0.9, "saw", 2.0, 0.6, -25.0))
    _sfx["step"] = _wave(_tone(100, 0.05, "noise", 8.0, 0.2))
    _sfx["pet"] = _wave(_arp([784.0, 988.0, 1175.0, 1568.0], 0.08, "sine", 0.4))
    _sfx["hurt"] = _wave(_tone(220, 0.2, "saw", 4.0, 0.5, -120.0))
    _sfx["swing"] = _wave(_tone(500, 0.12, "noise", 5.0, 0.18))
    _sfx["special"] = _wave(_tone(200, 0.4, "saw", 2.0, 0.5, 600.0))
    _sfx["error"] = _wave(_tone(150, 0.16, "square", 3.0, 0.3))
    _sfx["boom"] = _wave(_tone(60, 0.4, "noise", 3.0, 0.7))


func play_sfx(sfx_name, pitch = 1.0):
    if not _sfx.has(sfx_name):
        return
    var p = _pool[_pool_i]
    _pool_i = (_pool_i + 1) % _pool.size()
    p.stream = _sfx[sfx_name]
    p.pitch_scale = pitch
    p.play()


func play_ui(sfx_name):
    if not _sfx.has(sfx_name):
        return
    _ui_player.stream = _sfx[sfx_name]
    _ui_player.play()


func play_music(key):
    var k = str(key)
    if k == _current:
        return
    _current = k
    if not MUSIC.has(k):
        _music_player.stop()
        return
    if not _music_cache.has(k):
        _music_cache[k] = _make_music(k)
    _music_player.stream = _music_cache[k]
    _music_player.play()


func _make_music(k):
    var m = MUSIC[k]
    var step = 60.0 / m.bpm / 2.0
    var rng = RandomNumberGenerator.new()
    rng.seed = hash(k)
    var total = int(RATE * step * 16)
    var mix = PackedFloat32Array()
    mix.resize(total)
    var deg = 2
    for s in 16:
        deg = clampi(deg + rng.randi_range(-2, 2), 0, 9)
        var semis = m.scale[deg % 5] + 12 * int(deg / 5)
        var f = m.root * pow(2.0, semis / 12.0)
        var note = _tone(f, step * 1.6, m.kind, 2.5, 0.16)
        var off = int(RATE * step * s)
        for i in note.size():
            if off + i < total:
                mix[off + i] += note[i]
        if s % 4 == 0:
            var bass = _tone(m.root * 0.5 * pow(2.0, m.scale[(s / 4 * 2) % 5] / 12.0), step * 3.5, "sine", 1.5, 0.3)
            for i in bass.size():
                if off + i < total:
                    mix[off + i] += bass[i]
    var w = _wave(mix)
    w.loop_mode = AudioStreamWAV.LOOP_FORWARD
    w.loop_begin = 0
    w.loop_end = total
    return w
