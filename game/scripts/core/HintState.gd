extends Node

# Verwaltet welche Tutorial-Hints der Spieler schon gesehen hat.
# Persistiert in user://hints.cfg.

const SAVE_PATH: String = "user://hints.cfg"

var _seen: Dictionary = {}

func _ready() -> void:
	load_state()

func load_state() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for key in cfg.get_section_keys("seen") if cfg.has_section("seen") else []:
		_seen[key] = true

func save_state() -> void:
	var cfg := ConfigFile.new()
	for key in _seen.keys():
		cfg.set_value("seen", key, true)
	cfg.save(SAVE_PATH)

func has_seen(hint_id: String) -> bool:
	return _seen.has(hint_id)

func mark_seen(hint_id: String) -> void:
	_seen[hint_id] = true
	save_state()

func reset() -> void:
	_seen.clear()
	save_state()
