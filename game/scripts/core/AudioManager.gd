extends Node

# Autoload-Singleton für UI- und Battle-Sounds.
# Hält einen kleinen Pool von AudioStreamPlayers, damit überlappende Sounds nicht abgeschnitten werden.

const SFX_POOL_SIZE: int = 14
const UI_BUS: StringName = &"SFX"
const SFX_BUS: StringName = &"SFX"
const MUSIC_BUS: StringName = &"Music"

var _ui_sounds: Dictionary = {}      # name → AudioStream
var _sfx_sounds: Dictionary = {}     # name → AudioStream
var _item_sounds: Dictionary = {}    # item_id → AudioStream
var _impact_sound: AudioStream

var _pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0

var _music_player: AudioStreamPlayer
var _current_music_path: String = ""
var _ambient_player: AudioStreamPlayer
var _ambient_sounds: Dictionary = {}      # key -> AudioStream
var _sting_sounds: Dictionary = {}        # key -> AudioStream
var _current_ambient_key: String = ""

# Drosseln: gleicher Sound darf erst wieder nach throttle_ms gespielt werden
var _last_play_time: Dictionary = {}   # stream_instance_id → ticks_msec
# Speed-bewusste Volume-Anpassung (von BattleView gesetzt)
var _battle_speed: float = 1.0

func _ready() -> void:
	_preload_audio()
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_pool.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	_music_player.volume_db = -6.0
	add_child(_music_player)
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = MUSIC_BUS
	_ambient_player.volume_db = -16.0
	add_child(_ambient_player)

func _preload_audio() -> void:
	# UI-Sounds
	for name in ["click", "select", "drop", "back", "victory", "defeat"]:
		var path: String = "res://assets/audio/ui/%s.ogg" % name
		if ResourceLoader.exists(path):
			_ui_sounds[name] = load(path)
	# Generic SFX
	for name in ["impact_light", "impact_medium", "impact_heavy", "heal", "buff"]:
		var path: String = "res://assets/audio/sfx/%s.ogg" % name
		if ResourceLoader.exists(path):
			_sfx_sounds[name] = load(path)
	_impact_sound = _sfx_sounds.get("impact_medium")
	# Ambient-Loops pro Szene
	for key in ["menu", "map", "battle", "heal", "shop", "workshop", "boss_intro", "event"]:
		var path: String = "res://assets/audio/ambient/ambient_%s.ogg" % key
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			if stream is AudioStreamOggVorbis:
				(stream as AudioStreamOggVorbis).loop = true
			_ambient_sounds[key] = stream
	# Stings (one-shots)
	for key in ["run_start", "victory", "defeat", "node_pick"]:
		var path: String = "res://assets/audio/ambient/oneshots/sting_%s.ogg" % key
		if ResourceLoader.exists(path):
			_sting_sounds[key] = load(path)
	# Combat-Layer (Crit, Impact-Varianten, Tension)
	for key in ["impact_var1", "impact_var2", "crit_ring"]:
		var path: String = "res://assets/audio/ambient/oneshots/combat_%s.ogg" % key
		if ResourceLoader.exists(path):
			_sting_sounds[key] = load(path)
	var tension_path: String = "res://assets/audio/ambient/combat_tension_rise.ogg"
	if ResourceLoader.exists(tension_path):
		var t_stream: AudioStream = load(tension_path)
		if t_stream is AudioStreamOggVorbis:
			(t_stream as AudioStreamOggVorbis).loop = true
		_ambient_sounds["tension"] = t_stream
	# Item-spezifische Sounds - werden lazy geladen, wenn ein Item triggert

func _next_player() -> AudioStreamPlayer:
	var p: AudioStreamPlayer = _pool[_pool_index]
	_pool_index = (_pool_index + 1) % _pool.size()
	return p

func stop_all_sfx() -> void:
	for p in _pool:
		if p.playing:
			p.stop()

func set_battle_speed(speed: float) -> void:
	_battle_speed = speed

func _play_stream(stream: AudioStream, volume_db: float = 0.0, pitch_variance: float = 0.08, throttle_ms: int = 0) -> void:
	if stream == null:
		return
	if throttle_ms > 0:
		var key: int = stream.get_instance_id()
		var now: int = Time.get_ticks_msec()
		var last: int = int(_last_play_time.get(key, -10000))
		if now - last < throttle_ms:
			return
		_last_play_time[key] = now
	# Speed-bewusste Lautstärke: bei ×2+ leiser, ×4 deutlich leiser
	var speed_adjust: float = 0.0
	if _battle_speed >= 4.0:
		speed_adjust = -7.0
	elif _battle_speed >= 2.0:
		speed_adjust = -3.5
	var p := _next_player()
	p.stream = stream
	p.volume_db = volume_db + speed_adjust
	p.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	p.play()

# --- Public API ---

func ui(name: String) -> void:
	# UI-Sounds NICHT speed-skalieren (sind außerhalb Battle)
	var stream: AudioStream = _ui_sounds.get(name)
	if stream == null:
		return
	var p := _next_player()
	p.stream = stream
	p.volume_db = -4.0
	p.pitch_scale = 1.0 + randf_range(-0.05, 0.05)
	p.play()

func sfx(name: String, volume_db: float = -2.0) -> void:
	# 60ms Drossel für identische Impact-Sounds — mehrere Treffer in 1 Tick werden gemerged
	# Impact-Sounds: 33% Chance auf eine Brass/Steam-Variante (mehr Combat-Variety)
	if name.begins_with("impact_") and randf() < 0.33:
		var variant_key: String = "impact_var1" if randf() < 0.5 else "impact_var2"
		var variant: AudioStream = _sting_sounds.get(variant_key)
		if variant != null:
			_play_stream(variant, volume_db, 0.06, 60)
			return
	_play_stream(_sfx_sounds.get(name), volume_db, 0.10, 60)

func play_item_sound(item: Item, volume_db: float = -7.0) -> void:
	if item == null:
		return
	if not SettingsState.item_sounds_enabled:
		return
	var key: String = String(item.id)
	if not _item_sounds.has(key):
		var path: String = "res://assets/audio/items/%s.ogg" % key
		if ResourceLoader.exists(path):
			_item_sounds[key] = load(path)
		else:
			_item_sounds[key] = null
	# Item-Sounds: 120ms Drossel pro Item (verhindert Stacking gleicher Items)
	# und deutlich leiser als Impacts (waren oft zu dominant)
	_play_stream(_item_sounds[key], volume_db, 0.10, 120)

func play_impact() -> void:
	_play_stream(_impact_sound, -6.0, 0.10, 60)

# --- Music ---

func play_music(path: String, volume_db: float = -12.0, pitch: float = 1.0) -> void:
	if _current_music_path == path and _music_player.playing and abs(_music_player.pitch_scale - pitch) < 0.001:
		return
	if not ResourceLoader.exists(path):
		return
	_music_player.stop()
	_music_player.stream = load(path)
	if _music_player.stream is AudioStreamOggVorbis:
		(_music_player.stream as AudioStreamOggVorbis).loop = true
	_music_player.volume_db = volume_db
	_music_player.pitch_scale = pitch
	_music_player.play()
	_current_music_path = path

func stop_music() -> void:
	_music_player.stop()
	_current_music_path = ""

func is_music_playing() -> bool:
	return _music_player.playing

# --- Ambient & Stings ---

func play_ambient(key: String, volume_db: float = -16.0) -> void:
	if _current_ambient_key == key and _ambient_player.playing:
		return
	var stream: AudioStream = _ambient_sounds.get(key)
	if stream == null:
		_ambient_player.stop()
		_current_ambient_key = ""
		return
	_ambient_player.stop()
	_ambient_player.stream = stream
	_ambient_player.volume_db = volume_db
	_ambient_player.play()
	_current_ambient_key = key

func stop_ambient() -> void:
	_ambient_player.stop()
	_current_ambient_key = ""

func sting(key: String, volume_db: float = -6.0) -> void:
	var stream: AudioStream = _sting_sounds.get(key)
	if stream == null:
		return
	var p := _next_player()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0
	p.play()
