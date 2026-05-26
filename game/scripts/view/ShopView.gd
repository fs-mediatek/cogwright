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
	"gear_jammer", "target_painter", "chain_igniter",
]

const REROLL_COST: int = 5

@onready var _items_container: HBoxContainer = $Layout/ItemsContainer
@onready var _gold_label: Label = $Layout/Header/GoldLabel
@onready var _hp_label: Label = $Layout/Header/HpLabel
@onready var _continue_btn: Button = $Layout/Footer/ContinueButton
@onready var _reroll_btn: Button = $Layout/Footer/RerollButton
@onready var _inventory_strip: HBoxContainer = $Layout/InventoryPanel/InventoryScroll/InventoryStrip
@onready var _tower_status: Label = $Layout/StatusBar/TowerStatusLabel
@onready var _tags_container: HBoxContainer = $Layout/StatusBar/TagsContainer
@onready var _werkbank_panel: PanelContainer = $Layout/WerkbankPanel
@onready var _werkbank_row: HBoxContainer = $Layout/WerkbankPanel/WerkbankVBox/WerkbankRow

var _shop_items: Array[Dictionary] = []  # {id, price, sold}
var _reroll_count: int = 0

func _ready() -> void:
	if not RunState.is_run_active:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	_continue_btn.pressed.connect(_on_continue)
	_reroll_btn.pressed.connect(_on_reroll)
	_roll_shop()
	_refresh_header()
	_build_grid()
	AudioManager.play_music("res://assets/audio/music/menu_factory.ogg", -14.0)
	AudioManager.play_ambient("shop")
	if RunState.is_coop:
		CoopManager.action_applied.connect(_on_coop_action)
		CoopManager.transition_committed.connect(_on_coop_transition)
	HintOverlay.show_if_new(self, "first_shop",
		"Werkstatt-Markt",
		"Hier kaufst du neue Items mit [color=#f0c860]Gold[/color]. Du verdienst Gold pro Encounter-Sieg (+15) und Boss (+60).\n\nDer [b]Reroll-Knopf[/b] (5 Gold) gibt dir 4 neue Items zur Auswahl, falls keines passt.")

func _roll_shop() -> void:
	var rng := RandomNumberGenerator.new()
	# Reroll-Zaehler statt _shop_items.size() (war nach 1. Reroll konstant -> identische Rolls)
	rng.seed = RunState.run_seed + RunState.current_encounter_idx * 11119 + _reroll_count * 104729
	_shop_items.clear()
	# Smart-Pool wie ItemReward
	var scored: Array[Dictionary] = []
	for item_id in ALL_ITEM_IDS:
		var item: Item = load("res://data/items/%s.tres" % item_id)
		var score: float = SynergyHelper.score_for_build(item) + rng.randf()
		scored.append({"id": item_id, "score": score})
	scored.sort_custom(func(a, b): return a["score"] > b["score"])
	var num_items: int = 4 + MetaState.upgrade_level("shop_extra_item")
	for i in range(min(num_items, scored.size())):
		var item_id: String = scored[i]["id"]
		var item: Item = load("res://data/items/%s.tres" % item_id)
		var base_price: int = 12 + int(item.rarity) * 4
		# Synergie-Bonus (negative price boost wenn dead) — preise so dass dead items billig sind
		if SynergyHelper.is_dead_for_build(item):
			base_price = max(6, base_price - 6)
		# Perk Marktkenner: -30% Shop-Preise
		if MetaState.has_perk("marktkenner"):
			base_price = max(4, int(round(float(base_price) * 0.70)))
		_shop_items.append({"id": item_id, "price": base_price, "sold": false})

func _refresh_header() -> void:
	_gold_label.text = "Gold: %d" % RunState.gold
	_hp_label.text = "HP: %d / %d" % [RunState.tower_hp, RunState.tower_max_hp]
	var rcost: int = _reroll_cost()
	_reroll_btn.text = "Reroll (%d Gold)" % rcost
	_reroll_btn.disabled = RunState.gold < rcost
	_refresh_inventory_strip()
	_refresh_status_bar()
	_refresh_werkbank()

func _reroll_cost() -> int:
	return max(2, REROLL_COST - MetaState.upgrade_level("reroll_discount"))

func _refresh_inventory_strip() -> void:
	for c in _inventory_strip.get_children():
		c.queue_free()
	var header := Label.new()
	header.text = "Inventar (%d):" % RunState.inventory.size()
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.75, 0.65, 0.45))
	header.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_inventory_strip.add_child(header)
	if RunState.inventory.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "— leer —"
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", Color(0.55, 0.48, 0.35))
		_inventory_strip.add_child(empty_lbl)
		return
	var placed: Array[Item] = RunState.placed_items()
	for item in RunState.inventory:
		_inventory_strip.add_child(_make_inventory_chip(item, item in placed))

func _make_inventory_chip(item: Item, is_placed: bool) -> Control:
	var chip := PanelContainer.new()
	chip.tooltip_text = item.tooltip_text() + ("\n\n(im Turm platziert)" if is_placed else "")
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.13, 0.10, 1.0) if not is_placed else Color(0.13, 0.16, 0.12, 1.0)
	sb.border_color = Color(0.40, 0.32, 0.20, 1.0) if not is_placed else Color(0.55, 0.78, 0.45, 1.0)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(6)
	chip.add_theme_stylebox_override("panel", sb)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	chip.add_child(hbox)
	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(vbox)
	var name_lbl := Label.new()
	name_lbl.text = item.display_name + ("  ●" if is_placed else "")
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0.55, 0.95, 0.55) if is_placed else Color(0.85, 0.75, 0.55))
	vbox.add_child(name_lbl)
	var chips := TagChips.new()
	chips.chip_font_size = 9
	chips.chip_padding_h = 4
	chips.chip_padding_v = 1
	vbox.add_child(chips)
	chips.set_tags(item.tags, [])
	# Verkaufen-Button
	var sell_price: int = RunState.sell_price(item)
	var sell_btn := Button.new()
	sell_btn.text = "Verkaufen: %d G" % sell_price
	sell_btn.add_theme_font_size_override("font_size", 9)
	sell_btn.custom_minimum_size = Vector2(0, 20)
	sell_btn.tooltip_text = "Item für %d Gold verkaufen" % sell_price
	sell_btn.pressed.connect(_on_sell_item.bind(item))
	hbox.add_child(sell_btn)
	return chip

func _on_sell_item(item: Item) -> void:
	var inv_idx: int = RunState.inventory.find(item)
	if inv_idx < 0:
		return
	if RunState.is_coop:
		CoopManager.sync_action("inventory_sell", {"inv_idx": inv_idx})
	else:
		_apply_sell(inv_idx)

func _apply_sell(inv_idx: int) -> void:
	var price: int = RunState.sell_item_at(inv_idx)
	if price <= 0:
		return
	AudioManager.ui("select")
	_refresh_header()
	_build_grid()

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
	panel.tooltip_text = item.tooltip_text()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.15, 0.09, 1.0)
	sb.border_color = Color(0.95, 0.78, 0.35, 1.0)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)
	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(vbox)
	var name_lbl := Label.new()
	name_lbl.text = "3× %s" % item.display_name
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	vbox.add_child(name_lbl)
	var detail_lbl := Label.new()
	detail_lbl.text = "→ Verstärkt: +40% Wirkung, -15% Cooldown"
	detail_lbl.add_theme_font_size_override("font_size", 10)
	detail_lbl.add_theme_color_override("font_color", Color(0.70, 0.85, 0.50))
	vbox.add_child(detail_lbl)
	var btn := Button.new()
	btn.text = "Aufrüsten"
	btn.add_theme_font_size_override("font_size", 12)
	btn.custom_minimum_size = Vector2(110, 32)
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
	_refresh_header()
	_build_grid()

func _refresh_status_bar() -> void:
	var placed_count: int = RunState.placed_items().size()
	_tower_status.text = "Slots besetzt: %d / 9" % placed_count
	for c in _tags_container.get_children():
		c.queue_free()
	# Tag-Counts aus Inventar+Tower zusammenführen
	var tag_counts: Dictionary = {}
	for item in RunState.inventory:
		for tag in item.tags:
			var key: String = String(tag)
			tag_counts[key] = int(tag_counts.get(key, 0)) + 1
	if tag_counts.is_empty():
		return
	var prefix := Label.new()
	prefix.text = "  Tags im Inventar:"
	prefix.add_theme_font_size_override("font_size", 12)
	prefix.add_theme_color_override("font_color", Color(0.65, 0.58, 0.45))
	prefix.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_tags_container.add_child(prefix)
	# Tags absteigend nach Count sortieren
	var sorted_tags: Array = tag_counts.keys()
	sorted_tags.sort_custom(func(a, b): return tag_counts[a] > tag_counts[b])
	for tag in sorted_tags:
		var count: int = int(tag_counts[tag])
		_tags_container.add_child(_make_tag_count_chip(tag, count))

func _floor_names(affinity_tags: Array) -> String:
	# Quelle der Wahrheit: FloorConfig.display_name aus RunState.floors
	var names: Array[String] = []
	for tag in affinity_tags:
		for fc in RunState.floors:
			if fc.id == tag:
				names.append(fc.display_name)
				break
	return ", ".join(names)

func _make_tag_count_chip(tag: String, count: int) -> Control:
	var chip := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = TagPalette.bg(StringName(tag))
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", sb)
	var label := Label.new()
	label.text = "%s ×%d" % [tag, count]
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", TagPalette.fg(StringName(tag)))
	chip.add_child(label)
	return chip

func _build_grid() -> void:
	for child in _items_container.get_children():
		child.queue_free()
	for entry in _shop_items:
		var card := _make_card(entry)
		_items_container.add_child(card)

func _make_card(entry: Dictionary) -> PanelContainer:
	var item: Item = load("res://data/items/%s.tres" % entry["id"])
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 400)
	panel.tooltip_text = item.tooltip_text()
	var sb := StyleBoxFlat.new()
	if entry["sold"]:
		sb.bg_color = Color(0.10, 0.09, 0.07, 1.0)
		sb.border_color = Color(0.30, 0.27, 0.20, 1.0)
		panel.modulate = Color(0.45, 0.45, 0.45)
		sb.set_border_width_all(2)
	else:
		sb.bg_color = Color(0.15, 0.13, 0.10, 1.0)
		sb.border_color = TagPalette.rarity_color(item.rarity)
		sb.set_border_width_all(3 if item.rarity >= 2 else 2)
		if item.rarity >= 3:
			sb.shadow_color = TagPalette.rarity_color(item.rarity) * Color(1, 1, 1, 0.55)
			sb.shadow_size = 10
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = item.display_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.78, 0.55))
	vbox.add_child(name_lbl)

	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon)

	var chips := TagChips.new()
	chips.alignment = FlowContainer.ALIGNMENT_CENTER
	chips.chip_font_size = 10
	vbox.add_child(chips)
	chips.set_tags(item.tags, SynergyHelper.tags_boosted_for_candidate(item))

	# Cooldown + Beste Etage prominent
	var stats_lbl := Label.new()
	if item.cooldown_seconds >= 90.0:
		stats_lbl.text = "reaktiv"
	else:
		stats_lbl.text = "Cooldown: %.1fs" % item.cooldown_seconds
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.add_theme_font_size_override("font_size", 12)
	stats_lbl.add_theme_color_override("font_color", Color(0.80, 0.74, 0.58))
	vbox.add_child(stats_lbl)
	var shop_effect: String = item.primary_effect_label()
	if shop_effect != "":
		var effect_lbl := Label.new()
		effect_lbl.text = shop_effect
		effect_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect_lbl.add_theme_font_size_override("font_size", 13)
		effect_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55))
		vbox.add_child(effect_lbl)

	if item.floor_affinity.size() > 0:
		var affinity_lbl := Label.new()
		affinity_lbl.text = "↑ Beste Etage: %s  (+15%%)" % _floor_names(item.floor_affinity)
		affinity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		affinity_lbl.add_theme_font_size_override("font_size", 12)
		affinity_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
		affinity_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(affinity_lbl)
	else:
		var free_lbl := Label.new()
		free_lbl.text = "frei platzierbar"
		free_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		free_lbl.add_theme_font_size_override("font_size", 11)
		free_lbl.add_theme_color_override("font_color", Color(0.65, 0.58, 0.45))
		vbox.add_child(free_lbl)

	var desc_lbl := RichTextLabel.new()
	desc_lbl.bbcode_enabled = true
	desc_lbl.fit_content = true
	desc_lbl.scroll_active = false
	desc_lbl.add_theme_font_size_override("normal_font_size", 11)
	var transparent := StyleBoxEmpty.new()
	desc_lbl.add_theme_stylebox_override("normal", transparent)
	desc_lbl.text = "[center]%s[/center]" % TagPalette.colorize_tags(item.description)
	vbox.add_child(desc_lbl)

	# Warnung bei Duplicate-Buff oder Dead-Item
	if SynergyHelper.has_duplicate_buff(item):
		vbox.add_child(_make_warning_panel("⚠ Dieser Buff ist schon aktiv"))
	elif SynergyHelper.is_dead_for_build(item):
		vbox.add_child(_make_warning_panel("⚠ Wirkungslos für deinen Build"))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var btn := Button.new()
	if entry["sold"]:
		btn.text = "Verkauft"
		btn.disabled = true
	elif RunState.gold < entry["price"]:
		btn.text = "%d Gold (zu teuer)" % entry["price"]
		btn.disabled = true
	else:
		btn.text = "Kaufen für %d Gold" % entry["price"]
	btn.custom_minimum_size = Vector2(0, 38)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(_on_buy.bind(entry))
	vbox.add_child(btn)

	return panel

func _make_warning_panel(text: String) -> PanelContainer:
	var wpanel := PanelContainer.new()
	var wsb := StyleBoxFlat.new()
	wsb.bg_color = Color(0.24, 0.10, 0.10, 1.0)
	wsb.border_color = Color(0.92, 0.45, 0.40, 0.85)
	wsb.set_border_width_all(1)
	wsb.set_corner_radius_all(4)
	wsb.set_content_margin_all(6)
	wpanel.add_theme_stylebox_override("panel", wsb)
	var w_label := Label.new()
	w_label.text = text
	w_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	w_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	w_label.add_theme_font_size_override("font_size", 10)
	w_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.72))
	wpanel.add_child(w_label)
	return wpanel

func _on_buy(entry: Dictionary) -> void:
	if entry["sold"] or RunState.gold < entry["price"]:
		return
	if RunState.is_coop:
		var idx: int = _shop_items.find(entry)
		CoopManager.sync_action("shop_buy", {"idx": idx})
	else:
		_apply_buy(_shop_items.find(entry))

func _apply_buy(idx: int) -> void:
	if idx < 0 or idx >= _shop_items.size():
		return
	var entry: Dictionary = _shop_items[idx]
	if entry["sold"] or RunState.gold < entry["price"]:
		return
	AudioManager.ui("select")
	RunState.gold -= entry["price"]
	RunState.add_to_inventory(load("res://data/items/%s.tres" % entry["id"]))
	entry["sold"] = true
	_refresh_header()
	_build_grid()

func _on_reroll() -> void:
	if RunState.gold < _reroll_cost():
		return
	if RunState.is_coop:
		CoopManager.sync_action("shop_reroll", {})
	else:
		_apply_reroll()

func _apply_reroll() -> void:
	var cost: int = _reroll_cost()
	if RunState.gold < cost:
		return
	AudioManager.ui("click")
	RunState.gold -= cost
	_reroll_count += 1
	_roll_shop()
	_refresh_header()
	_build_grid()

func _on_continue() -> void:
	AudioManager.ui("click")
	if RunState.is_coop:
		CoopManager.propose_transition("shop:continue")
		_continue_btn.text = "Warte auf Mitspieler…"
		_continue_btn.disabled = true
	else:
		_do_continue()

func _do_continue() -> void:
	if RunState.current_map != null:
		RunState.current_map.mark_current_completed()
	get_tree().change_scene_to_file("res://scenes/MapView.tscn")

func _on_coop_action(action: String, payload: Dictionary) -> void:
	match action:
		"shop_buy":
			_apply_buy(int(payload.get("idx", -1)))
		"shop_reroll":
			_apply_reroll()
		"inventory_sell":
			_apply_sell(int(payload.get("inv_idx", -1)))
		"inventory_upgrade":
			_apply_upgrade(String(payload.get("item_id", "")))

func _on_coop_transition(key: String) -> void:
	if key == "shop:continue":
		_do_continue()
