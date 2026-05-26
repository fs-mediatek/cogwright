extends Control

const REQUIRED_PICKS: int = 5

const FLOOR_LABEL: Dictionary = {
	&"foundation": "Fundament",
	&"workshop": "Werkstatt",
	&"pinnacle": "Observatorium",
}

@onready var _selected_slots: HBoxContainer = $Layout/SelectedPanel/SelectedRow/SelectedSlots
@onready var _items_grid: HFlowContainer = $Layout/Scroll/ItemsGrid
@onready var _back_btn: Button = $Layout/Footer/BackButton
@onready var _start_btn: Button = $Layout/Footer/StartButton

var _picked: Array[String] = []

func _ready() -> void:
	MetaState.is_daily_run = false
	_back_btn.pressed.connect(_on_back)
	_start_btn.pressed.connect(_on_start)
	_build_items_grid()
	_refresh_selected()
	_refresh_start_button()
	AudioManager.play_music("res://assets/audio/music/menu_factory.ogg", -14.0)
	AudioManager.play_ambient("workshop")

func _build_items_grid() -> void:
	for child in _items_grid.get_children():
		child.queue_free()
	# Nur entdeckte Items (Codex-Progression) — Sandbox belohnt Spielzeit
	var ids: Array[String] = []
	for id in MetaState.discovered_items:
		ids.append(String(id))
	ids.sort()
	if ids.is_empty():
		var hint := Label.new()
		hint.text = "Noch keine Items entdeckt. Spiele Runs, um den Codex zu füllen — dann kannst du hier daraus wählen."
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_font_size_override("font_size", 14)
		hint.add_theme_color_override("font_color", Color(0.75, 0.70, 0.55))
		hint.custom_minimum_size = Vector2(600, 0)
		_items_grid.add_child(hint)
		return
	for item_id in ids:
		var item_path: String = "res://data/items/%s.tres" % item_id
		if not ResourceLoader.exists(item_path):
			continue
		var item: Item = load(item_path)
		_items_grid.add_child(_make_item_card(item))

func _make_item_card(item: Item) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 170)
	var is_picked: bool = String(item.id) in _picked
	var sb := StyleBoxFlat.new()
	if is_picked:
		sb.bg_color = Color(0.20, 0.16, 0.08, 1.0)
		sb.border_color = Color(0.95, 0.82, 0.35, 1.0)
		sb.set_border_width_all(3)
	else:
		sb.bg_color = Color(0.13, 0.10, 0.07, 1.0)
		sb.border_color = Color(0.45, 0.36, 0.22, 1.0)
		sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	panel.tooltip_text = item.tooltip_text()
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)
	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.custom_minimum_size = Vector2(44, 44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vb)
	var name_lbl := Label.new()
	name_lbl.text = item.display_name
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55))
	vb.add_child(name_lbl)
	var cd_lbl := Label.new()
	cd_lbl.text = "CD %.1fs" % item.cooldown_seconds
	cd_lbl.add_theme_font_size_override("font_size", 10)
	cd_lbl.modulate = Color(0.7, 0.66, 0.55)
	vb.add_child(cd_lbl)
	var effect: String = item.primary_effect_label()
	if effect != "":
		var eff_lbl := Label.new()
		eff_lbl.text = effect
		eff_lbl.add_theme_font_size_override("font_size", 11)
		eff_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.45))
		vb.add_child(eff_lbl)
	if item.floor_affinity.size() > 0:
		var aff_lbl := Label.new()
		var names: Array[String] = []
		for tag in item.floor_affinity:
			names.append(String(FLOOR_LABEL.get(tag, String(tag))))
		aff_lbl.text = "↑ " + ", ".join(names)
		aff_lbl.add_theme_font_size_override("font_size", 10)
		aff_lbl.add_theme_color_override("font_color", Color(0.85, 0.68, 0.32))
		vb.add_child(aff_lbl)
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_item_clicked(String(item.id))
	)
	return panel

func _on_item_clicked(item_id: String) -> void:
	if item_id in _picked:
		_picked.erase(item_id)
		AudioManager.ui("back")
	else:
		if _picked.size() >= REQUIRED_PICKS:
			AudioManager.ui("back")
			return
		_picked.append(item_id)
		AudioManager.ui("select")
	_build_items_grid()
	_refresh_selected()
	_refresh_start_button()

func _refresh_selected() -> void:
	for c in _selected_slots.get_children():
		c.queue_free()
	for i in range(REQUIRED_PICKS):
		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(180, 60)
		var sb := StyleBoxFlat.new()
		if i < _picked.size():
			sb.bg_color = Color(0.18, 0.15, 0.09, 1.0)
			sb.border_color = Color(0.95, 0.82, 0.45, 1.0)
			sb.set_border_width_all(2)
		else:
			sb.bg_color = Color(0.10, 0.09, 0.07, 1.0)
			sb.border_color = Color(0.35, 0.30, 0.24, 1.0)
			sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		sb.set_content_margin_all(8)
		slot_panel.add_theme_stylebox_override("panel", sb)
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		slot_panel.add_child(hbox)
		if i < _picked.size():
			var item: Item = load("res://data/items/%s.tres" % _picked[i])
			var icon := TextureRect.new()
			icon.texture = item.icon
			icon.custom_minimum_size = Vector2(36, 36)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hbox.add_child(icon)
			var lbl := Label.new()
			lbl.text = item.display_name
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55))
			lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hbox.add_child(lbl)
		else:
			var lbl := Label.new()
			lbl.text = "Slot %d (leer)" % (i + 1)
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.add_theme_color_override("font_color", Color(0.55, 0.50, 0.40))
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hbox.add_child(lbl)
		_selected_slots.add_child(slot_panel)

func _refresh_start_button() -> void:
	_start_btn.disabled = _picked.size() != REQUIRED_PICKS
	_start_btn.text = "Start (%d/%d gewählt)" % [_picked.size(), REQUIRED_PICKS]

func _on_back() -> void:
	AudioManager.ui("back")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_start() -> void:
	AudioManager.ui("select")
	var starter_items: Array[Item] = []
	for item_id in _picked:
		starter_items.append(load("res://data/items/%s.tres" % item_id))
	# Sandbox-Run startet als "fire"-Char (Default-Passive), keine Char-Wahl noetig.
	# Length = LONG (12 Encounter) fuer ausgedehnte Wiederspielwert-Sessions.
	RunState.start_new_run(starter_items, -1, MapGenerator.RunLength.LONG, "fire")
	get_tree().change_scene_to_file("res://scenes/MapView.tscn")
