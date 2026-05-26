extends Control

# Meta-Progression: Spieler kauft permanente Upgrades mit Resonanzkristallen.

@onready var _crystals_label: Label = $Layout/Header/CrystalsLabel
@onready var _grid: HFlowContainer = $Layout/Scroll/UpgradesGrid
@onready var _back_btn: Button = $Layout/Footer/BackButton

func _ready() -> void:
	_install_hero_background()
	_back_btn.pressed.connect(_on_back)
	_refresh()
	MetaState.meta_changed.connect(_refresh)
	AudioManager.play_music("res://assets/audio/music/menu_factory.ogg", -14.0)
	AudioManager.play_ambient("workshop")

func _install_hero_background() -> void:
	var bg_path: String = "res://assets/backgrounds/bg_workshop.png"
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
	bg.modulate = Color(1, 1, 1, 0.80)
	add_child(bg)
	move_child(bg, 1)

func _refresh() -> void:
	_crystals_label.text = "◆ Kristalle: %d" % MetaState.resonance_crystals
	for c in _grid.get_children():
		c.queue_free()
	for id in MetaState.WORKSHOP_UPGRADES.keys():
		_grid.add_child(_make_upgrade_card(String(id)))

func _make_upgrade_card(upgrade_id: String) -> PanelContainer:
	var info: Dictionary = MetaState.WORKSHOP_UPGRADES[upgrade_id]
	var level: int = MetaState.upgrade_level(upgrade_id)
	var max_level: int = MetaState.upgrade_max_level(upgrade_id)
	var cost: int = MetaState.upgrade_cost(upgrade_id)
	var is_max: bool = level >= max_level
	var can_afford: bool = MetaState.can_buy_upgrade(upgrade_id)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 200)
	var sb := StyleBoxFlat.new()
	if is_max:
		sb.bg_color = Color(0.13, 0.16, 0.12, 1.0)
		sb.border_color = Color(0.55, 0.85, 0.50, 1.0)
	elif level > 0:
		sb.bg_color = Color(0.18, 0.16, 0.10, 1.0)
		sb.border_color = Color(0.85, 0.68, 0.32, 1.0)
	else:
		sb.bg_color = Color(0.15, 0.13, 0.10, 1.0)
		sb.border_color = Color(0.40, 0.34, 0.22, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Header-Zeile: Icon + Name
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)
	# Optional: Icon-PNG je Upgrade laden
	var icon_id: String = String(info.get("icon", ""))
	if icon_id != "":
		var icon_path: String = "res://assets/ui/upgrades/upgrade_%s.png" % icon_id
		if ResourceLoader.exists(icon_path):
			var icon_res: Resource = load(icon_path)
			if icon_res is Texture2D:
				var icon := TextureRect.new()
				icon.texture = icon_res
				icon.custom_minimum_size = Vector2(48, 48)
				icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				header.add_child(icon)
	var name_lbl := Label.new()
	name_lbl.text = String(info.get("name", upgrade_id))
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	name_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = String(info.get("desc", ""))
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.80, 0.74, 0.58))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	# Level-Indikator: ●●●○○
	var lvl_row := HBoxContainer.new()
	lvl_row.add_theme_constant_override("separation", 4)
	vbox.add_child(lvl_row)
	var lvl_lbl := Label.new()
	lvl_lbl.text = "Stufe %d / %d  " % [level, max_level]
	lvl_lbl.add_theme_font_size_override("font_size", 12)
	lvl_lbl.add_theme_color_override("font_color", Color(0.70, 0.66, 0.55))
	lvl_row.add_child(lvl_lbl)
	for i in range(max_level):
		var dot := Label.new()
		dot.text = "●" if i < level else "○"
		dot.add_theme_font_size_override("font_size", 14)
		dot.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35) if i < level else Color(0.40, 0.36, 0.28))
		lvl_row.add_child(dot)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 36)
	btn.add_theme_font_size_override("font_size", 14)
	if is_max:
		btn.text = "✦ Maximalstufe erreicht"
		btn.disabled = true
	else:
		btn.text = "Aufrüsten — %d Kristalle" % cost
		btn.disabled = not can_afford
		btn.pressed.connect(_on_buy.bind(upgrade_id))
	vbox.add_child(btn)

	return panel

func _on_buy(upgrade_id: String) -> void:
	if MetaState.buy_upgrade(upgrade_id):
		AudioManager.sfx("buff", -2.0)
		_refresh()
	else:
		AudioManager.ui("back")

func _on_back() -> void:
	AudioManager.ui("back")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
