extends Control

const ALL_ITEM_IDS: Array[String] = [
	"pressure_hammer", "steam_kettle", "gear_sync", "relief_valve",
	"pressure_gauge", "repair_drone", "spark_spitter", "pendulum_strike",
	"cargo_lift", "forge_hearth", "combustion_chamber",
	"pressure_cannon", "boil_burst", "wind_mill", "spring_trap", "copper_coil",
	"storm_lance", "resonance_crystal", "iron_claw",
	"ice_drill", "vacuum_tube", "belt_drive", "shock_absorber", "resonance_hammer",
	"hydro_pump", "spinneret", "spark_magazine", "oil_canister", "head_lamp",
	"rotary_blade", "flintlock_pistol", "clockwork_bird", "piston_engine", "wrench_thrower",
	"gear_grinder", "flame_lance", "steam_whistle", "bellows_lung", "brass_telescope",
	"chronometer", "brass_horn", "siphon_pump", "iron_helm", "alchemist_flask",
	"firebomb", "ice_diffuser", "steel_aegis", "phosphor_lobber", "aegis_pump",
	"triple_cannon", "ammo_belt", "armor_plate", "grappling_hook", "stabilizer_brace", "grenade_launcher",
]

@onready var _grid: HFlowContainer = $Layout/Scroll/GridContainer
@onready var _back_btn: Button = $Layout/Footer/BackButton
@onready var _stats_label: Label = $Layout/Header/StatsLabel

func _ready() -> void:
	_back_btn.pressed.connect(_on_back)
	_stats_label.text = "%d Items im Codex • %d Runs gespielt • %d Boss-Siege • %d Kristalle • %d/%d Achievements" % [
		ALL_ITEM_IDS.size(),
		MetaState.runs_attempted,
		MetaState.bosses_defeated,
		MetaState.resonance_crystals,
		MetaState.achievements.size(),
		MetaState.ALL_ACHIEVEMENTS.size(),
	]
	_build_tag_glossary()
	_build_grid()
	_build_achievements()

func _build_tag_glossary() -> void:
	# Glossar-Sektion oben: erklärt jeden Tag im Spiel
	var glossary_header := PanelContainer.new()
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color(0.13, 0.10, 0.07, 1.0)
	hsb.border_color = Color(0.55, 0.45, 0.28, 1.0)
	hsb.set_border_width_all(2)
	hsb.set_corner_radius_all(8)
	hsb.set_content_margin_all(14)
	glossary_header.add_theme_stylebox_override("panel", hsb)
	glossary_header.custom_minimum_size = Vector2(880, 0)
	var gvbox := VBoxContainer.new()
	gvbox.add_theme_constant_override("separation", 6)
	glossary_header.add_child(gvbox)
	var title := Label.new()
	title.text = "📖 Tag-Glossar — was bedeutet welcher Typ?"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
	gvbox.add_child(title)
	# Tags in fester Reihenfolge auflisten (kategorisiert)
	var tag_order: Array[StringName] = [
		&"fire", &"pressure", &"blunt", &"sharp", &"heavy", &"ranged", &"precision",
		&"mechanical", &"steam", &"sync", &"modifier", &"reactive",
		&"support", &"defensive", &"scout", &"crafting", &"water"
	]
	for tag in tag_order:
		var desc: String = TagPalette.TAG_DESCRIPTIONS.get(tag, "")
		if desc == "":
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		# Chip
		var chip := PanelContainer.new()
		var csb := StyleBoxFlat.new()
		csb.bg_color = TagPalette.bg(tag)
		csb.set_corner_radius_all(8)
		csb.content_margin_left = 10
		csb.content_margin_right = 10
		csb.content_margin_top = 3
		csb.content_margin_bottom = 3
		chip.add_theme_stylebox_override("panel", csb)
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chip.custom_minimum_size = Vector2(100, 0)
		var clbl := Label.new()
		clbl.text = String(tag)
		clbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		clbl.add_theme_font_size_override("font_size", 11)
		clbl.add_theme_color_override("font_color", TagPalette.fg(tag))
		chip.add_child(clbl)
		row.add_child(chip)
		# Description
		var dlbl := Label.new()
		dlbl.text = desc
		dlbl.add_theme_font_size_override("font_size", 12)
		dlbl.add_theme_color_override("font_color", Color(0.80, 0.74, 0.58))
		dlbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dlbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(dlbl)
		gvbox.add_child(row)
	_grid.add_child(glossary_header)

func _build_achievements() -> void:
	# Fügt Achievement-Karten unten ins Grid hinzu, als zusätzlicher Bereich.
	# Pro Achievement eine Karte; gesperrte ausgegraut.
	for ach_id in MetaState.ALL_ACHIEVEMENTS.keys():
		var card := _make_achievement_card(ach_id)
		_grid.add_child(card)

func _make_achievement_card(ach_id: String) -> PanelContainer:
	var info: Dictionary = MetaState.ALL_ACHIEVEMENTS[ach_id]
	var unlocked: bool = MetaState.has_achievement(ach_id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 110)
	var sb := StyleBoxFlat.new()
	if unlocked:
		sb.bg_color = Color(0.18, 0.15, 0.09, 1.0)
		sb.border_color = Color(0.95, 0.78, 0.35, 1.0)
		sb.set_border_width_all(2)
	else:
		sb.bg_color = Color(0.10, 0.08, 0.06, 1.0)
		sb.border_color = Color(0.30, 0.25, 0.18, 1.0)
		sb.set_border_width_all(1)
		panel.modulate = Color(0.55, 0.55, 0.55)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	var name_lbl := Label.new()
	name_lbl.text = ("🏆 " if unlocked else "🔒 ") + info["name"]
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35) if unlocked else Color(0.6, 0.55, 0.45))
	vbox.add_child(name_lbl)
	var desc_lbl := Label.new()
	desc_lbl.text = info["desc"]
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 0.60))
	vbox.add_child(desc_lbl)
	return panel

func _build_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for item_id in ALL_ITEM_IDS:
		var item: Item = load("res://data/items/%s.tres" % item_id)
		var card := _make_item_card(item)
		_grid.add_child(card)

func _make_item_card(item: Item) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 200)
	panel.tooltip_text = item.tooltip_text()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.10, 0.07, 1.0)
	sb.border_color = Color(0.45, 0.36, 0.22, 1.0)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	# Icon links
	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hbox.add_child(icon)

	# Text rechts
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = item.display_name
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.78, 0.55))
	vbox.add_child(name_lbl)

	var chips := TagChips.new()
	chips.chip_font_size = 10
	chips.chip_padding_h = 6
	chips.chip_padding_v = 2
	vbox.add_child(chips)
	chips.set_tags(item.tags, [])

	var stats_lbl := Label.new()
	stats_lbl.text = "CD %.1fs · ↑ %s" % [item.cooldown_seconds, _floor_names(item.floor_affinity)]
	stats_lbl.add_theme_font_size_override("font_size", 11)
	stats_lbl.add_theme_color_override("font_color", Color(0.75, 0.68, 0.55))
	vbox.add_child(stats_lbl)

	var desc_lbl := RichTextLabel.new()
	desc_lbl.bbcode_enabled = true
	desc_lbl.fit_content = true
	desc_lbl.scroll_active = false
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("normal_font_size", 11)
	desc_lbl.text = TagPalette.colorize_tags(item.description)
	var transparent := StyleBoxEmpty.new()
	desc_lbl.add_theme_stylebox_override("normal", transparent)
	desc_lbl.add_theme_stylebox_override("focus", transparent)
	vbox.add_child(desc_lbl)

	return panel

func _floor_names(affinity_tags: Array) -> String:
	if affinity_tags.is_empty():
		return "frei platzierbar"
	var floors: Array[FloorConfig] = []
	floors.append(load("res://data/floors/foundation.tres"))
	floors.append(load("res://data/floors/workshop.tres"))
	floors.append(load("res://data/floors/pinnacle.tres"))
	var names: Array[String] = []
	for tag in affinity_tags:
		for fc in floors:
			if fc.id == tag:
				names.append(fc.display_name)
				break
	return ", ".join(names)

func _on_back() -> void:
	AudioManager.ui("back")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
