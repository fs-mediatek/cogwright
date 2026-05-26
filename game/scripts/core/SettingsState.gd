extends Node

# Persistente Spieler-Einstellungen.
# Wird beim Spielstart geladen und nach Änderung gespeichert.

const SAVE_PATH: String = "user://settings.cfg"

signal settings_changed

var master_volume: float = 0.9
var music_volume: float = 0.7
var sfx_volume: float = 1.0
var fullscreen: bool = false
var locale: String = "de"
var battle_speed: float = 1.0   # persistente Battle-Geschwindigkeit (×0.5/×1/×2/×4)
var item_sounds_enabled: bool = true   # Per-Item-Trigger-Sounds (auch unabhaengig von SFX-Lautstaerke)
var screen_shake_enabled: bool = true   # Screen-Shake bei schweren Treffern
var telemetry_enabled: bool = true   # Battle-Logs senden (Default an — User kann opt-out)
var telemetry_webhook_url: String = ""   # Optionaler Override; leer = Built-in nutzen
var telemetry_only_on_loss: bool = false   # nur bei Niederlagen senden

func _ready() -> void:
	_ensure_audio_buses()
	load_settings()
	apply_all()

func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index("Music") < 0:
		AudioServer.add_bus()
		var idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index("SFX") < 0:
		AudioServer.add_bus()
		var idx2: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx2, "SFX")
		AudioServer.set_bus_send(idx2, "Master")

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	master_volume = cfg.get_value("audio", "master_volume", 0.9)
	music_volume = cfg.get_value("audio", "music_volume", 0.7)
	sfx_volume = cfg.get_value("audio", "sfx_volume", 1.0)
	fullscreen = cfg.get_value("display", "fullscreen", false)
	locale = cfg.get_value("display", "locale", "de")
	battle_speed = cfg.get_value("gameplay", "battle_speed", 1.0)
	item_sounds_enabled = cfg.get_value("gameplay", "item_sounds_enabled", true)
	screen_shake_enabled = cfg.get_value("gameplay", "screen_shake_enabled", true)
	telemetry_enabled = cfg.get_value("telemetry", "enabled", true)
	telemetry_webhook_url = cfg.get_value("telemetry", "webhook_url", "")
	telemetry_only_on_loss = cfg.get_value("telemetry", "only_on_loss", false)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "locale", locale)
	cfg.set_value("gameplay", "battle_speed", battle_speed)
	cfg.set_value("gameplay", "item_sounds_enabled", item_sounds_enabled)
	cfg.set_value("gameplay", "screen_shake_enabled", screen_shake_enabled)
	cfg.set_value("telemetry", "enabled", telemetry_enabled)
	cfg.set_value("telemetry", "webhook_url", telemetry_webhook_url)
	cfg.set_value("telemetry", "only_on_loss", telemetry_only_on_loss)
	cfg.save(SAVE_PATH)

func apply_all() -> void:
	apply_volumes()
	apply_display()
	apply_locale()

func apply_locale() -> void:
	TranslationServer.set_locale(locale)

func apply_volumes() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)

func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var db: float = -80.0 if linear < 0.001 else linear_to_db(linear)
	AudioServer.set_bus_volume_db(idx, db)

func apply_display() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		# Maximiert statt Windowed: nutzt auf großen Monitoren den verfügbaren Platz.
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

# --- Public API für UI ---

func set_master(v: float) -> void:
	master_volume = clamp(v, 0.0, 1.0)
	apply_volumes()
	save_settings()
	settings_changed.emit()

func set_music(v: float) -> void:
	music_volume = clamp(v, 0.0, 1.0)
	apply_volumes()
	save_settings()
	settings_changed.emit()

func set_sfx(v: float) -> void:
	sfx_volume = clamp(v, 0.0, 1.0)
	apply_volumes()
	save_settings()
	settings_changed.emit()

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	apply_display()
	save_settings()
	settings_changed.emit()

func set_locale(new_locale: String) -> void:
	locale = new_locale
	apply_locale()
	save_settings()
	settings_changed.emit()

func set_telemetry_enabled(v: bool) -> void:
	telemetry_enabled = v
	save_settings()
	settings_changed.emit()

func set_telemetry_webhook_url(url: String) -> void:
	telemetry_webhook_url = url.strip_edges()
	save_settings()
	settings_changed.emit()

func set_telemetry_only_on_loss(v: bool) -> void:
	telemetry_only_on_loss = v
	save_settings()
	settings_changed.emit()
