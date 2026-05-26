extends Control

const ENCOUNTER_PATHS: Array[String] = [
	"res://data/encounters/01_scout.tres",
	"res://data/encounters/02_engineer.tres",
	"res://data/encounters/03_brigand.tres",
	"res://data/encounters/04_artisan.tres",
	"res://data/encounters/05_warlord.tres",
]

# Preload statt class_name-Referenz: vermeidet Cache-Probleme, wenn das Spiel
# direkt (ohne Editor-Pre-Scan) gestartet wird.
const DraggableItemCardLib = preload("res://scripts/view/DraggableItemCard.gd")
const TowerSlotPanelLib = preload("res://scripts/view/TowerSlotPanel.gd")

@onready var _inventory_container: HFlowContainer = $Layout/Body/InventoryPanel/VBox/ItemsFlow
@onready var _tower_floors: VBoxContainer = $Layout/Body/TowerPanel/VBox/FloorsContainer
@onready var _start_button: Button = $Layout/Footer/StartButton
@onready var _hint_label: Label = $Layout/Body/InventoryPanel/VBox/HintLabel
@onready var _encounter_label: Label = $Layout/Header/EncounterLabel
@onready var _hp_label: Label = $Layout/Header/HpLabel
@onready var _selected_label: Label = $Layout/Footer/SelectedLabel
@onready var _tower_title: Label = $Layout/Body/TowerPanel/VBox/TowerTitle
@onready var _werkbank_panel: PanelContainer = $Layout/Body/InventoryPanel/VBox/WerkbankPanel
@onready var _werkbank_row: VBoxContainer = $Layout/Body/InventoryPanel/VBox/WerkbankPanel/WerkbankVBox/WerkbankRow
@onready var _detail_content: RichTextLabel = $Layout/Body/DetailPanel/DetailVBox/DetailContent

const DETAIL_DEFAULT: String = "[i]Hover über ein Item, einen Slot oder einen Tag, um Details zu sehen.[/i]\n\n[b]Etagen-Bonus:[/b]\n• Spitze: +25% Speed\n• Werkstatt: +5% Damage\n• Fundament: +30% HP\n\n[b]Lieblings-Etage:[/b] [color=#ffcc40]+15% Schaden und schnellere Cooldowns[/color] auf der passenden Etage. Goldener Rahmen = optimal."

var _selected_item: Item = null

func _ready() -> void:
	if not RunState.is_run_active:
		# Direkter Aufruf ohne Run-Setup: zurück zum Hauptmenü
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	_inventory_container.alignment = FlowContainer.ALIGNMENT_CENTER
	_start_button.pressed.connect(_on_start_battle)
	_install_hero_background()
	_show_default_detail()
	_rebuild_all()
	_update_start_button()
	AudioManager.play_music("res://assets/audio/music/menu_factory.ogg", -14.0)
	AudioManager.play_ambient("workshop")
	if RunState.is_coop:
		CoopManager.action_applied.connect(_on_coop_action)
		CoopManager.transition_committed.connect(_on_coop_transition)
	HintOverlay.show_if_new(self, "first_tower_builder",
		"Turm aufbauen",
		"Items werden auf 3 Etagen platziert: [b]Spitze[/b] (oben, +25% Speed), [b]Werkstatt[/b] (Mitte, +5% Damage), [b]Fundament[/b] (unten, +30% HP).\n\nKlicke ein Item im Inventar, dann einen Slot. Ein [color=#ffcc40]goldener Rahmen[/color] zeigt an, dass das Item auf seiner Lieblings-Etage steht — +15% Wirkung.")

func _rebuild_all() -> void:
	var encounter_path: String = RunState.pending_encounter_path
	if encounter_path == "":
		encounter_path = ENCOUNTER_PATHS[RunState.current_encounter_idx]
	var encounter: EncounterConfig = load(encounter_path)
	_encounter_label.text = "Nächster Kampf: %s" % encounter.display_name
	_hp_label.text = "Turm-HP: %d / %d" % [RunState.tower_hp, RunState.tower_max_hp]
	_tower_title.text = "Werkstatt-Turm  vs  %s (%d HP)" % [encounter.display_name, encounter.base_hp]
	_build_inventory()
	_build_tower()
	_build_enemy_preview(encounter)
	_refresh_werkbank()
	_update_selected_label()

func _refresh_werkbank() -> void:
	for c in _werkbank_row.get_children():
		c.queue_free()
	var candidates: Array[String] = RunState.find_upgrade_candidates()
	if candidates.is_empty():
		_werkbank_panel.visible = false
		return
	_werkbank_panel.visible = true
	for item_id in candidates:
		_werkbank_row.add_child(_make_upgrade_card(item_id))

func _make_upgrade_card(item_id: String) -> Control:
	var item_path: String = "res://data/items/%s.tres" % item_id
	if not ResourceLoader.exists(item_path):
		return Control.new()
	var item: Item = load(item_path)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.15, 0.09, 1.0)
	sb.border_color = Color(0.95, 0.78, 0.35, 1.0)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", sb)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)
	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(vbox)
	var name_lbl := Label.new()
	name_lbl.text = "3× %s" % item.display_name
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	vbox.add_child(name_lbl)
	var detail_lbl := Label.new()
	detail_lbl.text = "→ Verstärkt: +40%% Wirkung, -15%% CD"
	detail_lbl.add_theme_font_size_override("font_size", 9)
	detail_lbl.add_theme_color_override("font_color", Color(0.70, 0.85, 0.50))
	vbox.add_child(detail_lbl)
	var btn := Button.new()
	btn.text = "Aufrüsten"
	btn.add_theme_font_size_override("font_size", 11)
	btn.custom_minimum_size = Vector2(96, 28)
	btn.pressed.connect(_on_upgrade.bind(item_id))
	hbox.add_child(btn)
	return panel

func _on_upgrade(item_id: String) -> void:
	if RunState.is_coop:
		CoopManager.sync_action("inventory_upgrade", {"item_id": item_id})
	else:
		_apply_upgrade(item_id)

func _apply_upgrade(item_id: String) -> void:
	var result: Item = RunState.upgrade_item(item_id)
	if result == null:
		return
	AudioManager.sfx("buff", -2.0)
	_rebuild_all()
	_update_start_button()

func _build_enemy_preview(encounter: EncounterConfig) -> void:
	var unplaced_count: int = RunState.unplaced_items().size()
	var control_hint: String
	if unplaced_count == 0:
		control_hint = "Alle Items platziert. Klick auf einen Slot, um ein Item zurückzunehmen."
	else:
		control_hint = "Ziehe ein Item per Drag-and-Drop in einen Slot — oder klick erst Item, dann Slot."
	var affinity_hint: String = "✦ Tipp: Platziere Items auf ihrer Lieblings-Etage (↑-Pfeil) für +15% Schaden und schnellere Cooldowns. Goldener Rahmen = optimal."
	_hint_label.text = "%s\n%s\n\n%s\n\n%s" % [
		encounter.description,
		"Gegnerische Items: " + _format_enemy_items(encounter),
		affinity_hint,
		control_hint,
	]

func _format_enemy_items(encounter: EncounterConfig) -> String:
	var names: Array[String] = []
	for id in encounter.item_ids:
		var path: String = "res://data/items/%s.tres" % String(id)
		var it: Item = load(path)
		if it != null:
			names.append(it.display_name)
	return ", ".join(names)

func _build_inventory() -> void:
	for child in _inventory_container.get_children():
		child.queue_free()
	var unplaced := RunState.unplaced_items()
	for item in unplaced:
		var card := _make_item_card(item, true)
		_inventory_container.add_child(card)

func _build_tower() -> void:
	for child in _tower_floors.get_children():
		child.queue_free()
	# Pinnacle oben, Foundation unten
	for floor_idx in range(2, -1, -1):
		var fc: FloorConfig = RunState.floors[floor_idx]
		var floor_box := VBoxContainer.new()
		floor_box.add_theme_constant_override("separation", 4)
		var label := Label.new()
		label.text = "%d · %s" % [floor_idx, fc.display_name]
		label.add_theme_font_size_override("font_size", 12)
		label.modulate = Color(0.72, 0.66, 0.55)
		floor_box.add_child(label)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		floor_box.add_child(row)
		for slot_idx in range(3):
			var idx: int = floor_idx * 3 + slot_idx
			var slot_node := _make_slot(idx, fc)
			row.add_child(slot_node)
		_tower_floors.add_child(floor_box)

func _make_item_card(item: Item, from_inventory: bool) -> PanelContainer:
	var panel: PanelContainer
	if from_inventory:
		var card: PanelContainer = DraggableItemCardLib.new()
		card.item = item
		card.inv_idx = RunState.inventory.find(item)
		panel = card
	else:
		panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 190)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.13, 0.10, 1.0)
	sb.border_color = Color(0.85, 0.68, 0.32, 1.0) if _selected_item == item else Color(0.30, 0.27, 0.23, 1.0)
	sb.set_border_width_all(2 if _selected_item == item else 1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.tooltip_text = item.tooltip_text()

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	var name_lbl := Label.new()
	name_lbl.text = item.display_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(name_lbl)

	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon)

	var cd_lbl := Label.new()
	cd_lbl.text = "CD %.1fs" % item.cooldown_seconds
	cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_lbl.add_theme_font_size_override("font_size", 10)
	cd_lbl.modulate = Color(0.7, 0.66, 0.55)
	vbox.add_child(cd_lbl)
	var effect_text: String = item.primary_effect_label()
	if effect_text != "":
		var effect_lbl := Label.new()
		effect_lbl.text = effect_text
		effect_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect_lbl.add_theme_font_size_override("font_size", 11)
		effect_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55))
		vbox.add_child(effect_lbl)

	# „Beste Etage"-Hinweis — der wichtigste Tipp für Spieler
	if item.floor_affinity.size() > 0:
		var affinity_lbl := Label.new()
		affinity_lbl.text = "↑ " + _floor_names(item.floor_affinity)
		affinity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		affinity_lbl.add_theme_font_size_override("font_size", 10)
		affinity_lbl.add_theme_color_override("font_color", Color(0.85, 0.68, 0.32))
		vbox.add_child(affinity_lbl)

	# Tag-Chips
	var chips := TagChips.new()
	chips.alignment = FlowContainer.ALIGNMENT_CENTER
	chips.chip_font_size = 9
	chips.chip_padding_h = 5
	chips.chip_padding_v = 1
	vbox.add_child(chips)
	chips.set_tags(item.tags, SynergyHelper.tags_boosted_for_candidate(item))

	panel.gui_input.connect(_on_item_card_clicked.bind(item, from_inventory))
	panel.mouse_entered.connect(_show_item_detail.bind(item, null))
	panel.mouse_exited.connect(_show_default_detail)
	return panel

func _floor_names(affinity_tags: Array) -> String:
	# Quelle der Wahrheit: FloorConfig.display_name aus RunState.floors
	var names: Array[String] = []
	for tag in affinity_tags:
		for fc in RunState.floors:
			if fc.id == tag:
				names.append(fc.display_name)
				break
	return ", ".join(names)

func _make_slot(slot_idx: int, floor_config: FloorConfig) -> Control:
	var current: Item = RunState.tower_layout[slot_idx]
	var panel: PanelContainer = TowerSlotPanelLib.new()
	panel.slot_idx = slot_idx
	panel.accepts_drop = (current == null)
	panel.item_dropped.connect(_on_item_dropped_on_slot)
	panel.custom_minimum_size = Vector2(200, 190)
	var sb := StyleBoxFlat.new()
	if current != null:
		var has_affinity: bool = current.floor_affinity.has(floor_config.id)
		sb.bg_color = Color(0.18, 0.15, 0.11, 1.0)
		sb.border_color = Color(0.78, 0.62, 0.36, 1.0) if has_affinity else Color(0.40, 0.36, 0.30, 1.0)
		sb.set_border_width_all(2 if has_affinity else 1)
	else:
		sb.bg_color = Color(0.10, 0.09, 0.07, 1.0)
		sb.border_color = Color(0.35, 0.30, 0.24, 0.8) if _selected_item != null else Color(0.22, 0.20, 0.17, 1.0)
		sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.gui_input.connect(_on_slot_clicked.bind(slot_idx))
	if current != null:
		panel.tooltip_text = current.tooltip_text()
		panel.mouse_entered.connect(_show_item_detail.bind(current, floor_config))
		panel.mouse_exited.connect(_show_default_detail)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	if current != null:
		var name_lbl := Label.new()
		name_lbl.text = current.display_name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.add_theme_font_size_override("font_size", 11)
		vbox.add_child(name_lbl)
		var icon := TextureRect.new()
		icon.texture = current.icon
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(icon)
		var cd_lbl := Label.new()
		if current.cooldown_seconds >= 90.0:
			cd_lbl.text = "reaktiv"
		else:
			cd_lbl.text = "CD %.1fs" % current.cooldown_seconds
		cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd_lbl.add_theme_font_size_override("font_size", 10)
		cd_lbl.modulate = Color(0.7, 0.66, 0.55)
		vbox.add_child(cd_lbl)
		var slot_effect: String = current.primary_effect_label()
		if slot_effect != "":
			var slot_effect_lbl := Label.new()
			slot_effect_lbl.text = slot_effect
			slot_effect_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			slot_effect_lbl.add_theme_font_size_override("font_size", 11)
			slot_effect_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55))
			vbox.add_child(slot_effect_lbl)
		# Affinity-Status: passt das Item zur Etage?
		var has_affinity_for_this_floor: bool = current.floor_affinity.has(floor_config.id)
		var has_any_affinity: bool = current.floor_affinity.size() > 0
		if has_any_affinity:
			var aff_lbl := Label.new()
			if has_affinity_for_this_floor:
				aff_lbl.text = "✦ Optimal +15%"
				aff_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
			else:
				aff_lbl.text = "↑ %s wäre besser" % _floor_names(current.floor_affinity)
				aff_lbl.add_theme_color_override("font_color", Color(0.88, 0.55, 0.40))
			aff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			aff_lbl.add_theme_font_size_override("font_size", 10)
			vbox.add_child(aff_lbl)
		var chips := TagChips.new()
		chips.alignment = FlowContainer.ALIGNMENT_CENTER
		chips.chip_font_size = 9
		chips.chip_padding_h = 5
		chips.chip_padding_v = 1
		vbox.add_child(chips)
		chips.set_tags(current.tags, SynergyHelper.tags_boosted_for_candidate(current))
	else:
		var empty_lbl := Label.new()
		empty_lbl.text = "(leer)"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 11)
		empty_lbl.modulate = Color(0.45, 0.40, 0.35)
		empty_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		vbox.add_child(empty_lbl)

	return panel

func _on_item_card_clicked(event: InputEvent, item: Item, from_inventory: bool) -> void:
	# Wichtig: Auf RELEASE triggern, nicht auf Press. Sonst zerstört _rebuild_all
	# die Quell-Karte, bevor Godots Drag-System _get_drag_data aufrufen kann.
	# Bei tatsächlichem Drag bekommt das Drop-Target den Release-Event, nicht diese Karte.
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if from_inventory:
			_selected_item = item if _selected_item != item else null
			AudioManager.ui("select")
			_rebuild_all()

func _on_slot_clicked(event: InputEvent, slot_idx: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var current: Item = RunState.tower_layout[slot_idx]
	if current != null:
		if RunState.is_coop:
			CoopManager.sync_action("tower_remove", {"slot": slot_idx})
		else:
			_apply_remove_from_slot(slot_idx)
	elif _selected_item != null:
		var inv_idx: int = RunState.inventory.find(_selected_item)
		if inv_idx < 0:
			return
		_selected_item = null  # lokale Auswahl sofort löschen
		if RunState.is_coop:
			CoopManager.sync_action("tower_place", {"inv_idx": inv_idx, "slot": slot_idx})
		else:
			_apply_place_into_slot(inv_idx, slot_idx)

func _apply_place_into_slot(inv_idx: int, slot_idx: int) -> void:
	if inv_idx < 0 or inv_idx >= RunState.inventory.size():
		return
	var item: Item = RunState.inventory[inv_idx]
	if item == null:
		return
	RunState.place_in_slot(slot_idx, item)
	MetaState.track_item_placement(String(item.id))
	AudioManager.ui("drop")
	_rebuild_all()
	_update_start_button()

func _apply_remove_from_slot(slot_idx: int) -> void:
	RunState.remove_from_slot(slot_idx)
	AudioManager.ui("back")
	_rebuild_all()
	_update_start_button()

func _on_item_dropped_on_slot(inv_idx: int, slot_idx: int) -> void:
	# Drag-and-Drop-Pfad: identisch zur Click-Pfad-Logik, aber mit explizitem inv_idx.
	if inv_idx < 0 or inv_idx >= RunState.inventory.size():
		return
	if RunState.tower_layout[slot_idx] != null:
		return
	_selected_item = null
	if RunState.is_coop:
		CoopManager.sync_action("tower_place", {"inv_idx": inv_idx, "slot": slot_idx})
	else:
		_apply_place_into_slot(inv_idx, slot_idx)

func _on_coop_action(action: String, payload: Dictionary) -> void:
	match action:
		"tower_place":
			_apply_place_into_slot(int(payload.get("inv_idx", -1)), int(payload.get("slot", -1)))
		"tower_remove":
			_apply_remove_from_slot(int(payload.get("slot", -1)))
		"inventory_upgrade":
			_apply_upgrade(String(payload.get("item_id", "")))

func _on_coop_transition(key: String) -> void:
	if key == "tower:start_battle":
		_do_start_battle()

func _install_hero_background() -> void:
	var bg_path: String = "res://assets/backgrounds/bg_tower_builder.png"
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
	bg.modulate = Color(1, 1, 1, 0.70)
	add_child(bg)
	move_child(bg, 1)

func _show_default_detail() -> void:
	if _detail_content == null:
		return
	_detail_content.text = DETAIL_DEFAULT

func _show_item_detail(item: Item, floor_config: FloorConfig) -> void:
	if _detail_content == null or item == null:
		return
	var rarity_label: Dictionary = {
		0: "Gewöhnlich", 1: "Ungewöhnlich", 2: "Selten", 3: "Legendär",
	}
	var rarity_color: Dictionary = {
		0: "#c0b8a8", 1: "#7fc97a", 2: "#5fa8e0", 3: "#d8a04a",
	}
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[b][color=#ffe0a0]%s[/color][/b]   [color=%s]%s[/color]" % [
		item.display_name,
		rarity_color.get(int(item.rarity), "#c0b8a8"),
		rarity_label.get(int(item.rarity), "?"),
	])
	if item.tags.size() > 0:
		var tag_parts: PackedStringArray = PackedStringArray()
		for t in item.tags:
			tag_parts.append("[bgcolor=#3d2c1e][color=#ffd28a] %s [/color][/bgcolor]" % String(t))
		lines.append(" ".join(tag_parts))
	lines.append("")
	if item.cooldown_seconds >= 90.0:
		lines.append("[color=#aab8c0]reaktiv (kein eigener Trigger)[/color]")
	else:
		lines.append("[color=#aab8c0]Cooldown:[/color] %.1f s" % item.cooldown_seconds)
	if item.floor_affinity.size() > 0:
		var aff_names: Array[String] = []
		for tag in item.floor_affinity:
			for fc in RunState.floors:
				if fc.id == tag:
					aff_names.append(fc.display_name)
					break
		lines.append("[color=#aab8c0]Lieblings-Etage:[/color] [color=#ffcc40]%s[/color]" % ", ".join(aff_names))
		if floor_config != null:
			if item.floor_affinity.has(floor_config.id):
				lines.append("[color=#8fcf6a]✦ Optimal platziert (+15%%)[/color]")
			else:
				lines.append("[color=#dd8055]↑ Aktuell suboptimal — auf %s wäre besser[/color]" % ", ".join(aff_names))
	lines.append("")
	lines.append(TagPalette.colorize_tags(item.description))
	if item.flavor_text != "":
		lines.append("")
		lines.append("[i][color=#888070]%s[/color][/i]" % item.flavor_text)
	_detail_content.text = "\n".join(lines)

func _update_selected_label() -> void:
	if _selected_item != null:
		_selected_label.text = "Ausgewählt: %s" % _selected_item.display_name
	else:
		_selected_label.text = "Kein Item ausgewählt"

func _update_start_button() -> void:
	var placed_count: int = RunState.placed_items().size()
	_start_button.disabled = placed_count == 0
	_start_button.text = "Battle starten (%d/9 platziert)" % placed_count

func _on_start_battle() -> void:
	AudioManager.ui("click")
	if RunState.is_coop:
		CoopManager.propose_transition("tower:start_battle")
		_start_button.text = "Warte auf Mitspieler…"
		_start_button.disabled = true
	else:
		_do_start_battle()

func _do_start_battle() -> void:
	# Bei Boss: erst Intro-Standbild, dann Battle.
	if RunState.current_map != null:
		var cn: MapNode = RunState.current_map.current_node()
		if cn != null and cn.type == MapNode.NodeType.BOSS:
			get_tree().change_scene_to_file("res://scenes/BossIntro.tscn")
			return
	get_tree().change_scene_to_file("res://scenes/BattleView.tscn")
