extends Control

# Gesamt-Statistiken über alle Runs hinweg. Lifetime-Tracking aus MetaState.

@onready var _container: VBoxContainer = $Layout/Scroll/StatsContainer
@onready var _back_btn: Button = $Layout/BackButton

func _ready() -> void:
	_install_hero_background()
	_back_btn.pressed.connect(_on_back)
	_build_stats()
	AudioManager.play_music("res://assets/audio/music/menu_factory.ogg", -14.0)
	AudioManager.play_ambient("menu")

func _install_hero_background() -> void:
	var bg_path: String = "res://assets/backgrounds/bg_stats.png"
	if not ResourceLoader.exists(bg_path):
		return
	var res: Resource = load(bg_path)
	if not (res is Texture2D):
		return
	var bg := TextureRect.new()
	bg.texture = res
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.modulate = Color(1, 1, 1, 0.75)
	add_child(bg)
	move_child(bg, 1)

func _build_stats() -> void:
	for c in _container.get_children():
		c.queue_free()
	# Run-Stats
	_container.add_child(_make_section("Run-Statistiken"))
	var win_rate: float = 0.0
	if MetaState.runs_attempted > 0:
		win_rate = float(MetaState.runs_won) / float(MetaState.runs_attempted) * 100.0
	_container.add_child(_make_stat("Runs gespielt", "%d" % MetaState.runs_attempted))
	_container.add_child(_make_stat("Runs gewonnen", "%d (%.0f%% Win-Rate)" % [MetaState.runs_won, win_rate]))
	_container.add_child(_make_stat("Bosse besiegt", "%d" % MetaState.bosses_defeated))
	_container.add_child(_make_stat("Encounter gewonnen (gesamt)", "%d" % MetaState.encounters_won_total))
	# Damage
	_container.add_child(_make_section("Kampf-Statistiken"))
	_container.add_child(_make_stat("Gesamt-Schaden ausgeteilt", "%d" % MetaState.total_damage_dealt))
	_container.add_child(_make_stat("Gesamt-Schaden erlitten", "%d" % MetaState.total_damage_taken))
	# Charaktere
	_container.add_child(_make_section("Charaktere"))
	for char_id in MetaState.ALL_CHARACTERS.keys():
		var char_info: Dictionary = MetaState.ALL_CHARACTERS[char_id]
		var attempts: int = int(MetaState.character_attempts.get(char_id, 0))
		var wins: int = int(MetaState.character_wins.get(char_id, 0))
		if attempts == 0:
			continue
		var rate: float = 0.0 if attempts == 0 else float(wins) / float(attempts) * 100.0
		_container.add_child(_make_stat(String(char_info["name"]), "%d Runs · %d Siege (%.0f%%)" % [attempts, wins, rate]))
	# Items
	_container.add_child(_make_section("Items"))
	_container.add_child(_make_stat("Items entdeckt", "%d" % MetaState.discovered_items.size()))
	var fav: String = MetaState.most_placed_item()
	if fav != "":
		var path: String = "res://data/items/%s.tres" % fav
		var name: String = fav
		if ResourceLoader.exists(path):
			var it: Item = load(path)
			name = it.display_name
		_container.add_child(_make_stat("Meistplatziertes Item", "%s (%dx)" % [name, int(MetaState.item_placements.get(fav, 0))]))
	# Meta
	_container.add_child(_make_section("Meta"))
	_container.add_child(_make_stat("Resonanzkristalle", "%d" % MetaState.resonance_crystals))
	_container.add_child(_make_stat("Achievements freigeschaltet", "%d / %d" % [MetaState.achievements.size(), MetaState.ALL_ACHIEVEMENTS.size()]))
	_container.add_child(_make_stat("Heat freigeschaltet", "max. %d" % MetaState.max_heat_unlocked))

func _make_section(title: String) -> Control:
	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
	return lbl

func _make_stat(label: String, value: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.13, 0.10, 1.0)
	sb.border_color = Color(0.40, 0.32, 0.20, 1.0)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	var hbox := HBoxContainer.new()
	panel.add_child(hbox)
	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.78, 0.70, 0.55))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)
	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 14)
	val.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	hbox.add_child(val)
	return panel

func _on_back() -> void:
	AudioManager.ui("back")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
