extends Control

const STARTER_SETS := [
	{
		"id": "pressure",
		"name": "Druckmeister",
		"description": "Druckhammer wird durch den Druckmesser massiv verstärkt. Funkenspeier liefert konstanten Zusatz-Schaden auf der Spitze.",
		"item_ids": ["pressure_hammer", "pressure_gauge", "spark_spitter"],
	},
	{
		"id": "blunt",
		"name": "Schmiedin",
		"description": "Schwere [blunt]-Items. Langsam, aber treffsicher dank Schmiede-Esse.",
		"item_ids": ["pendulum_strike", "forge_hearth", "pressure_hammer"],
	},
	{
		"id": "fire",
		"name": "Pyrotechniker",
		"description": "Schnelle Funken, durch die Brennkammer auf der Werkstatt-Etage zusätzlich verstärkt. Hohe Tickrate.",
		"item_ids": ["spark_spitter", "spark_spitter", "combustion_chamber"],
	},
	{
		"id": "reactive",
		"name": "Saboteur",
		"description": "Reaktive Items, die einander triggern. Druckventil + Federfalle auf der Spitze, Druckmesser auf der Werkstatt verstärkt beide um +25%.",
		"item_ids": ["relief_valve", "spring_trap", "pressure_gauge"],
	},
	{
		"id": "gunner",
		"name": "Kanonenmeister",
		"description": "Drillingsgeschütz auf der Spitze, Munitionsband auf der Werkstatt sorgt für –30% CD darüber, Panzerung im Fundament gibt +30 Schild. [ranged] +20%, [reactive] +20% CD-Penalty.",
		"item_ids": ["triple_cannon", "ammo_belt", "armor_plate"],
	},
	{
		"id": "mastermind",
		"name": "Mastermind",
		"description": "Kein festes Set: 1 Anker (Druckhammer) + 2 ZUFÄLLIGE Items pro Run. Passive [b]Universalist[/b]: +8% Schaden je einzigartigem Tag im Turm. Plus 1× gratis Reroll pro Item-Belohnung. Adaptiere aus dem Zufall das beste Setup.",
		"item_ids": ["pressure_hammer"],
		"random_pool": true,
		"random_count": 2,
	},
]

@onready var _set_container: HBoxContainer = $Layout/SetsContainer
@onready var _back_button: Button = $Layout/Footer/BackButton
@onready var _heat_label: Label = $Layout/HeatRow/HeatLabel
@onready var _heat_buttons_row: HBoxContainer = $Layout/HeatRow/HeatButtons
@onready var _heat_detail: Label = $Layout/HeatDetailLabel
@onready var _perk_row: HBoxContainer = $Layout/PerkRow
@onready var _perk_slots_container: HBoxContainer = $Layout/PerkRow/PerkSlotsContainer
@onready var _perk_manage_btn: Button = $Layout/PerkRow/PerkManageBtn
@onready var _length_short_btn: Button = $Layout/LengthRow/LengthShortBtn
@onready var _length_normal_btn: Button = $Layout/LengthRow/LengthNormalBtn
@onready var _length_long_btn: Button = $Layout/LengthRow/LengthLongBtn

# Anzahl der Heat-Stufen, die direkt waehlbar sind (auch ohne Boss-Sieg).
const HEAT_LEVELS_AVAILABLE: int = 5

var _selected_length: int = MapGenerator.RunLength.NORMAL
var _heat_buttons: Array[Button] = []

func _ready() -> void:
	MetaState.is_daily_run = false
	_install_hero_background()
	_back_button.pressed.connect(_on_back)
	_length_short_btn.pressed.connect(_on_length_pick.bind(MapGenerator.RunLength.SHORT))
	_length_normal_btn.pressed.connect(_on_length_pick.bind(MapGenerator.RunLength.NORMAL))
	_length_long_btn.pressed.connect(_on_length_pick.bind(MapGenerator.RunLength.LONG))
	_refresh_length_buttons()
	_build_set_cards()
	_setup_heat_buttons()
	_setup_perk_row()
	AudioManager.play_music("res://assets/audio/music/menu_factory.ogg", -14.0)
	AudioManager.play_ambient("menu")

func _install_hero_background() -> void:
	# Optional: bg_runstart.png als Hintergrund einblenden, hinter Atmosphere
	var bg_path: String = "res://assets/backgrounds/bg_runstart.png"
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
	bg.modulate = Color(1, 1, 1, 0.80)   # leicht dimmen damit die Charakter-Karten lesbar bleiben
	add_child(bg)
	# Zwischen Background-ColorRect (0) und Atmosphere (1) einsortieren
	move_child(bg, 1)

func _on_length_pick(length: int) -> void:
	AudioManager.ui("click")
	_selected_length = length
	_refresh_length_buttons()

func _refresh_length_buttons() -> void:
	_length_short_btn.button_pressed = (_selected_length == MapGenerator.RunLength.SHORT)
	_length_normal_btn.button_pressed = (_selected_length == MapGenerator.RunLength.NORMAL)
	_length_long_btn.button_pressed = (_selected_length == MapGenerator.RunLength.LONG)

func _setup_heat_buttons() -> void:
	# Dunkler Backdrop fuer Heat-Label + Detail-Label, damit auf hellem BG lesbar.
	_apply_text_scrim(_heat_label, 10, 4)
	_apply_text_scrim(_heat_detail, 14, 6)
	# Mindestens HEAT_LEVELS_AVAILABLE direkt waehlbar — Boss-Siege schalten weitere Stufen frei.
	var max_heat: int = max(MetaState.max_heat_unlocked, HEAT_LEVELS_AVAILABLE)
	# selected_heat darf nicht ueber max liegen
	if MetaState.selected_heat > max_heat:
		MetaState.set_heat(max_heat)
	for child in _heat_buttons_row.get_children():
		child.queue_free()
	_heat_buttons.clear()
	for level in range(max_heat + 1):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(70, 32)
		btn.toggle_mode = true
		btn.text = "Standard" if level == 0 else "Heat %d" % level
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(_on_heat_pick.bind(level))
		_heat_buttons_row.add_child(btn)
		_heat_buttons.append(btn)
	_refresh_heat_buttons()
	_update_heat_detail()

func _on_heat_pick(level: int) -> void:
	AudioManager.ui("click")
	MetaState.set_heat(level)
	_refresh_heat_buttons()
	_update_heat_detail()

func _refresh_heat_buttons() -> void:
	for i in range(_heat_buttons.size()):
		_heat_buttons[i].button_pressed = (i == MetaState.selected_heat)

func _apply_text_scrim(lbl: Label, pad_h: int, pad_v: int) -> void:
	# Setzt einen halbtransparenten dunklen Hintergrund auf ein Label, damit
	# auf hellem Background-Bild der Text lesbar bleibt.
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.55)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	lbl.add_theme_stylebox_override("normal", sb)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	lbl.add_theme_constant_override("outline_size", 6)

func _setup_perk_row() -> void:
	var slots: int = MetaState.perk_slots_available()
	if slots <= 0:
		_perk_row.visible = false
		return
	_perk_row.visible = true
	# Stelle sicher, dass selected_perks max slots gross ist
	while MetaState.selected_perks.size() > slots:
		MetaState.selected_perks.pop_front()
	MetaState.save_state()
	_refresh_perk_slots()
	_apply_text_scrim(_perk_row.get_node("PerkLabel"), 10, 4)
	_perk_manage_btn.pressed.connect(_open_perk_picker)

func _refresh_perk_slots() -> void:
	for c in _perk_slots_container.get_children():
		c.queue_free()
	var slots: int = MetaState.perk_slots_available()
	for i in range(slots):
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55))
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		lbl.add_theme_constant_override("outline_size", 4)
		if i < MetaState.selected_perks.size():
			var pid: String = MetaState.selected_perks[i]
			var info: Dictionary = MetaState.PERKS.get(pid, {"name": pid})
			lbl.text = "[ %s ]" % info["name"]
		else:
			lbl.text = "[ leer ]"
			lbl.add_theme_color_override("font_color", Color(0.55, 0.50, 0.40))
		_perk_slots_container.add_child(lbl)

func _open_perk_picker() -> void:
	AudioManager.ui("click")
	# Bauwer: ein Overlay-Panel mit Grid aller 13 Perks
	var existing: Node = get_node_or_null("PerkOverlay")
	if existing != null:
		existing.queue_free()
	var overlay := PanelContainer.new()
	overlay.name = "PerkOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.03, 0.02, 0.94)
	sb.set_content_margin_all(40)
	overlay.add_theme_stylebox_override("panel", sb)
	add_child(overlay)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	overlay.add_child(vbox)
	var title := Label.new()
	title.text = "Perk-Auswahl  (%d / %d Slots)" % [MetaState.selected_perks.size(), MetaState.perk_slots_available()]
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var hint := Label.new()
	hint.text = "Klick einen Perk an, um ihn zu aktivieren/deaktivieren. Maximal %d aktiv." % MetaState.perk_slots_available()
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.75, 0.70, 0.58))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	for pid in MetaState.PERKS.keys():
		grid.add_child(_make_perk_card(pid, overlay))
	var close_btn := Button.new()
	close_btn.text = "Schließen"
	close_btn.custom_minimum_size = Vector2(180, 40)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func():
		AudioManager.ui("back")
		overlay.queue_free()
		_refresh_perk_slots()
	)
	vbox.add_child(close_btn)

func _make_perk_card(perk_id: String, overlay: Node) -> PanelContainer:
	var info: Dictionary = MetaState.PERKS[perk_id]
	var is_unlocked: bool = perk_id in MetaState.unlocked_perks
	var is_selected: bool = perk_id in MetaState.selected_perks
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 130)
	var sb := StyleBoxFlat.new()
	if is_selected:
		sb.bg_color = Color(0.20, 0.16, 0.08, 1.0)
		sb.border_color = Color(0.95, 0.82, 0.35, 1.0)
		sb.set_border_width_all(3)
	elif is_unlocked:
		sb.bg_color = Color(0.13, 0.10, 0.07, 1.0)
		sb.border_color = Color(0.55, 0.45, 0.28, 1.0)
		sb.set_border_width_all(1)
	else:
		sb.bg_color = Color(0.08, 0.07, 0.05, 1.0)
		sb.border_color = Color(0.30, 0.25, 0.18, 1.0)
		sb.set_border_width_all(1)
		panel.modulate = Color(0.55, 0.55, 0.55)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)
	var name_lbl := Label.new()
	name_lbl.text = ("✦ " if is_selected else ("" if is_unlocked else "🔒 ")) + info["name"]
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45) if is_selected else (Color(0.85, 0.78, 0.55) if is_unlocked else Color(0.55, 0.50, 0.42)))
	vb.add_child(name_lbl)
	var desc_lbl := Label.new()
	desc_lbl.text = info["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.78, 0.62))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(desc_lbl)
	if not is_unlocked:
		var unlock_lbl := Label.new()
		unlock_lbl.text = "🔒 " + info["unlock_desc"]
		unlock_lbl.add_theme_font_size_override("font_size", 11)
		unlock_lbl.add_theme_color_override("font_color", Color(0.65, 0.55, 0.45))
		unlock_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(unlock_lbl)
	if is_unlocked:
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				AudioManager.ui("select")
				MetaState.toggle_perk(perk_id)
				overlay.queue_free()
				_open_perk_picker()
		)
	return panel

func _update_heat_detail() -> void:
	var h: int = MetaState.selected_heat
	if h == 0:
		_heat_detail.text = "Standard-Schwierigkeit · keine Gegner-Buffs, keine Bonus-Kristalle"
	else:
		_heat_detail.text = "Heat %d  ·  Gegner +%d%% HP  ·  +%d Kristalle pro Boss-Sieg" % [h, h * 12, h * 5]

func _build_set_cards() -> void:
	for child in _set_container.get_children():
		child.queue_free()
	for set_def in STARTER_SETS:
		var is_unlocked: bool = MetaState.is_character_unlocked(set_def["id"])
		var card := _make_set_card(set_def, is_unlocked)
		_set_container.add_child(card)

func _make_set_card(set_def: Dictionary, is_unlocked: bool = true) -> PanelContainer:
	var panel := PanelContainer.new()
	# 280 px statt 360 — sonst passen 5 Klassen-Karten nicht auf 1920er Screens (Bug-Report @xtract94)
	panel.custom_minimum_size = Vector2(280, 380)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	if is_unlocked:
		sb.bg_color = Color(0.15, 0.13, 0.10, 1.0)
		sb.border_color = Color(0.55, 0.45, 0.28, 1.0)
	else:
		sb.bg_color = Color(0.10, 0.09, 0.07, 1.0)
		sb.border_color = Color(0.28, 0.25, 0.20, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", sb)
	if not is_unlocked:
		panel.modulate = Color(0.55, 0.55, 0.55)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Charakter-Portrait wenn vorhanden — als kompaktes Icon (zentriert oben)
	var portrait_path: String = "res://assets/characters/char_%s.png" % String(set_def["id"])
	if ResourceLoader.exists(portrait_path):
		var portrait_tex: Resource = load(portrait_path)
		if portrait_tex is Texture2D:
			var portrait := TextureRect.new()
			portrait.texture = portrait_tex
			portrait.custom_minimum_size = Vector2(120, 120)
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			vbox.add_child(portrait)

	var name_lbl := Label.new()
	name_lbl.text = set_def["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.78, 0.55))
	vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = set_def["description"]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.66, 0.55))
	vbox.add_child(desc_lbl)

	# Item-Icons + Namen
	var item_row := HBoxContainer.new()
	item_row.alignment = BoxContainer.ALIGNMENT_CENTER
	item_row.add_theme_constant_override("separation", 8)
	vbox.add_child(item_row)
	for item_id in set_def["item_ids"]:
		var item: Item = load("res://data/items/%s.tres" % item_id)
		var item_box := VBoxContainer.new()
		item_box.alignment = BoxContainer.ALIGNMENT_CENTER
		item_box.tooltip_text = item.tooltip_text()
		item_box.mouse_filter = Control.MOUSE_FILTER_STOP
		var icon := TextureRect.new()
		icon.texture = item.icon
		icon.custom_minimum_size = Vector2(48, 48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_box.add_child(icon)
		var item_label := Label.new()
		item_label.text = item.display_name
		item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item_label.custom_minimum_size = Vector2(80, 0)
		item_label.add_theme_font_size_override("font_size", 11)
		item_box.add_child(item_label)
		item_row.add_child(item_box)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var choose_btn := Button.new()
	if is_unlocked:
		choose_btn.text = "Wählen"
	else:
		choose_btn.text = "🔒 " + MetaState.ALL_CHARACTERS.get(set_def["id"], {}).get("unlock_condition", "Gesperrt")
		choose_btn.disabled = true
	choose_btn.custom_minimum_size = Vector2(0, 36)
	choose_btn.add_theme_font_size_override("font_size", 14)
	vbox.add_child(choose_btn)
	if is_unlocked:
		choose_btn.pressed.connect(_on_set_chosen.bind(set_def))

	return panel

func _on_set_chosen(set_def: Dictionary) -> void:
	AudioManager.ui("select")
	AudioManager.sting("run_start", -4.0)
	var starter_items: Array[Item] = []
	# Fixe Items (Anker)
	for item_id in set_def["item_ids"]:
		starter_items.append(load("res://data/items/%s.tres" % item_id))
	# Mastermind: zusaetzlich N zufaellige Items aus dem ganzen Pool
	if set_def.get("random_pool", false):
		var count: int = int(set_def.get("random_count", 2))
		var fixed_ids: Array = set_def["item_ids"]
		var pool: Array[String] = _all_item_ids()
		pool.shuffle()
		var added: int = 0
		for id in pool:
			if added >= count:
				break
			if id in fixed_ids:
				continue
			var path: String = "res://data/items/%s.tres" % id
			if ResourceLoader.exists(path):
				starter_items.append(load(path))
				added += 1
	RunState.start_new_run(starter_items, -1, _selected_length, String(set_def["id"]))
	get_tree().change_scene_to_file("res://scenes/MapView.tscn")

func _all_item_ids() -> Array[String]:
	# Scannt data/items/ — funktioniert auch im Export (PCK gemountet).
	var ids: Array[String] = []
	var dir := DirAccess.open("res://data/items/")
	if dir == null:
		return ids
	dir.list_dir_begin()
	var f: String = dir.get_next()
	while f != "":
		if not dir.current_is_dir() and f.ends_with(".tres"):
			ids.append(f.get_basename())
		elif f.ends_with(".tres.remap"):
			# Im Export heissen die Files .tres.remap
			ids.append(f.replace(".tres.remap", ""))
		f = dir.get_next()
	dir.list_dir_end()
	return ids

func _on_back() -> void:
	AudioManager.ui("back")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
