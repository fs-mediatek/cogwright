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
const HEAL_PERCENT: float = 0.50  # Werkstatt-Reparatur heilt 50% des Max-HP
const SKIP_GOLD_REWARD: int = 12  # Anreiz, eine Belohnung zu überspringen

var _reroll_offset: int = 0
var _reroll_used: bool = false

@onready var _items_container: HBoxContainer = $Layout/ItemsContainer
@onready var _skip_button: Button = $Layout/Footer/SkipButton
@onready var _title_label: Label = $Layout/TitleLabel
@onready var _subtitle_label: Label = $Layout/SubtitleLabel
@onready var _inventory_panel: PanelContainer = $Layout/InventoryPanel
@onready var _inventory_strip: HBoxContainer = $Layout/InventoryPanel/InventoryScroll/InventoryStrip
@onready var _damage_panel: PanelContainer = $Layout/DamagePanel
@onready var _damage_rows: VBoxContainer = $Layout/DamagePanel/DamageVBox/DamageRows

func _ready() -> void:
	if not RunState.is_run_active:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	_install_hero_background()
	_skip_button.pressed.connect(_on_skip)
	_title_label.text = "Sieg! Encounter %d / %d gewonnen." % [RunState.encounters_won, RunState.total_encounters]
	var sub: String = "Wähle eine Belohnung für deinen Turm."
	if RunState.last_auto_heal > 0:
		sub += "  ✦ Werkstatt-Reparaturen: +%d HP wiederhergestellt (jetzt %d / %d)." % [
			RunState.last_auto_heal,
			RunState.tower_hp,
			RunState.tower_max_hp,
		]
	_subtitle_label.text = sub
	_skip_button.text = "Überspringen (+%d Gold)" % _skip_gold_reward()
	_setup_mastermind_reroll()
	_build_inventory_strip()
	_build_damage_breakdown()
	_build_choices()
	AudioManager.play_music("res://assets/audio/music/menu_factory.ogg", -14.0)
	AudioManager.play_ambient("workshop")

func _install_hero_background() -> void:
	# Übergangs-Screen nach Battle: Werkstatt-Atmosphäre nutzen, damit nicht der nackte Brown auftaucht
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
	bg.modulate = Color(1, 1, 1, 0.55)
	add_child(bg)
	move_child(bg, 1)

func _build_damage_breakdown() -> void:
	for c in _damage_rows.get_children():
		c.queue_free()
	var breakdown: Array = RunState.last_battle_damage_breakdown
	if breakdown.is_empty():
		_damage_panel.visible = false
		return
	_damage_panel.visible = true
	# Total für Prozent-Anzeige
	var total: int = 0
	for entry in breakdown:
		total += int(entry["damage_total"])
	if total <= 0:
		_damage_panel.visible = false
		return
	# Top 6 Items zeigen
	for i in range(min(6, breakdown.size())):
		var entry: Dictionary = breakdown[i]
		var dmg: int = int(entry["damage_total"])
		var pct: float = float(dmg) / float(total) * 100.0
		var triggers: int = int(entry["trigger_count"])
		var crits: int = int(entry.get("crits", 0))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		# Icon
		var icon := TextureRect.new()
		icon.texture = entry["icon"]
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
		# Name
		var name_lbl := Label.new()
		name_lbl.text = String(entry["item_name"])
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", Color(0.85, 0.78, 0.60))
		name_lbl.custom_minimum_size = Vector2(180, 0)
		row.add_child(name_lbl)
		# Bar (Filled Background)
		var bar := PanelContainer.new()
		bar.custom_minimum_size = Vector2(0, 14)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var bar_bg := StyleBoxFlat.new()
		bar_bg.bg_color = Color(0.13, 0.10, 0.07, 1.0)
		bar_bg.border_color = Color(0.35, 0.28, 0.18, 1.0)
		bar_bg.set_border_width_all(1)
		bar_bg.set_corner_radius_all(3)
		bar.add_theme_stylebox_override("panel", bar_bg)
		var fill_outer := Control.new()
		bar.add_child(fill_outer)
		var fill := ColorRect.new()
		fill.color = Color(0.95, 0.55, 0.25)
		fill.anchor_top = 0
		fill.anchor_bottom = 1
		fill.anchor_left = 0
		fill.anchor_right = clamp(pct / 100.0, 0.02, 1.0)
		fill.offset_left = 2
		fill.offset_right = -2
		fill.offset_top = 2
		fill.offset_bottom = -2
		fill_outer.add_child(fill)
		row.add_child(bar)
		# Damage + %
		var dmg_lbl := Label.new()
		var crit_str: String = "" if crits == 0 else "  (%dx CRIT)" % crits
		dmg_lbl.text = "%d  · %.0f%%  · %dx%s" % [dmg, pct, triggers, crit_str]
		dmg_lbl.add_theme_font_size_override("font_size", 11)
		dmg_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
		dmg_lbl.custom_minimum_size = Vector2(170, 0)
		row.add_child(dmg_lbl)
		_damage_rows.add_child(row)
	# Summary
	var summary := Label.new()
	summary.text = "Gesamt-Schaden: %d  ·  über %d Items" % [total, breakdown.size()]
	summary.add_theme_font_size_override("font_size", 11)
	summary.add_theme_color_override("font_color", Color(0.65, 0.60, 0.48))
	_damage_rows.add_child(summary)
	if RunState.is_coop:
		CoopManager.action_applied.connect(_on_coop_action)

func _build_inventory_strip() -> void:
	for child in _inventory_strip.get_children():
		child.queue_free()
	var header := Label.new()
	header.text = "Dein Inventar (%d):" % RunState.inventory.size()
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
	for item in RunState.inventory:
		_inventory_strip.add_child(_make_inventory_chip(item))

func _make_inventory_chip(item: Item) -> Control:
	var chip := PanelContainer.new()
	chip.tooltip_text = item.tooltip_text()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.13, 0.10, 1.0)
	sb.border_color = Color(0.40, 0.32, 0.20, 1.0)
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
	name_lbl.text = item.display_name
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
	vbox.add_child(name_lbl)
	var chips := TagChips.new()
	chips.chip_font_size = 9
	chips.chip_padding_h = 4
	chips.chip_padding_v = 1
	vbox.add_child(chips)
	chips.set_tags(item.tags, [])
	return chip

func _build_choices() -> void:
	for child in _items_container.get_children():
		child.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = RunState.run_seed + RunState.current_encounter_idx * 7919 + _reroll_offset * 104729
	# Score jedes Item nach Build-Synergie; zufälliger Tie-Breaker für Variation
	var scored: Array[Dictionary] = []
	for item_id in ALL_ITEM_IDS:
		var item: Item = load("res://data/items/%s.tres" % item_id)
		var score: float = SynergyHelper.score_for_build(item)
		score += rng.randf()
		scored.append({"id": item_id, "score": score, "item": item})
	scored.sort_custom(func(a, b): return a["score"] > b["score"])
	# Elite-Sieg: mehr Karten zur Wahl
	var was_elite: bool = _was_elite_encounter()
	var item_count: int = 4 if was_elite else 3
	# Perk Gluecksrad: +1 Option grundsaetzlich
	if MetaState.has_perk("gluecksrad"):
		item_count += 1
	# Perk Pluendererglueck: +1 Option bei Elite-Kaempfen
	if was_elite and MetaState.has_perk("pluendererglueck"):
		item_count += 1
	# Floor-Diversity: zähle, wie viele Items pro Etage der Spieler bereits hat
	var floor_counts: Dictionary = {&"foundation": 0, &"workshop": 0, &"pinnacle": 0}
	for it in RunState.inventory:
		for aff in it.floor_affinity:
			if floor_counts.has(aff):
				floor_counts[aff] = int(floor_counts[aff]) + 1
	# Finde unterrepräsentierte Etage
	var min_floor: StringName = &"foundation"
	var min_count: int = 99999
	for f in floor_counts.keys():
		if int(floor_counts[f]) < min_count:
			min_count = int(floor_counts[f])
			min_floor = f
	# Top-Picks aus Smart-Pool für die ersten N-1 Slots, letzter Slot reserviert für Underrepresented-Floor
	var picks: Array[Dictionary] = []
	for entry in scored:
		if picks.size() >= item_count - 1:
			break
		picks.append(entry)
	# Suche das beste Item für die unterrepräsentierte Etage, das nicht bereits gewählt ist
	var picked_ids: Array[String] = []
	for p in picks:
		picked_ids.append(String(p["id"]))
	var floor_pick: Dictionary = {}
	for entry in scored:
		var item: Item = entry["item"]
		if String(entry["id"]) in picked_ids:
			continue
		if item.floor_affinity.has(min_floor):
			floor_pick = entry
			break
	if floor_pick.is_empty():
		# Fallback: nimm einfach das nächste vom Smart-Pool, das noch nicht drin ist
		for entry in scored:
			if String(entry["id"]) not in picked_ids:
				floor_pick = entry
				break
	if not floor_pick.is_empty():
		picks.append(floor_pick)
	# Render + Discovery-Tracking (erstes Mal ein Item sehen → Kristall-Bonus)
	for p in picks:
		var item: Item = p["item"]
		MetaState.try_discover_item(String(item.id))
		var card := _make_reward_card(item)
		_items_container.add_child(card)
	# Werkstatt-Reparatur (heilt 50% Max-HP)
	var heal_card := _make_heal_card()
	_items_container.add_child(heal_card)
	if was_elite:
		_subtitle_label.text = _subtitle_label.text + "\n[Elite-Sieg: 4 Items zur Wahl statt 3]"

func _was_elite_encounter() -> bool:
	if RunState.current_map == null:
		return false
	# Das current_node wurde gerade abgeschlossen — wir wissen vom completed-Knoten
	# noch nicht, ob es Elite war. Wir prüfen alle gerade abgeschlossenen Knoten der vorherigen Reihe.
	# Pragmatisch: aktueller Knoten ist der zuletzt besiegte, weil mark_current_completed erst aufgerufen wurde.
	var cn: MapNode = RunState.current_map.current_node()
	return cn != null and cn.type == MapNode.NodeType.ELITE

func _make_reward_card(item: Item) -> PanelContainer:
	# 300 statt 360 — bei Gluecksrad/Pluendererglueck-Perks bis zu 5 Karten gleichzeitig.
	# HFlowContainer (Parent) bricht automatisch um, falls Breite ueberlaufen wuerde.
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 420)
	panel.tooltip_text = item.tooltip_text()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.13, 0.10, 1.0)
	sb.border_color = TagPalette.rarity_color(item.rarity)
	sb.set_border_width_all(3 if item.rarity >= 2 else 2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(20)
	if item.rarity >= 3:
		sb.shadow_color = TagPalette.rarity_color(item.rarity) * Color(1, 1, 1, 0.55)
		sb.shadow_size = 10
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var rarity_lbl := Label.new()
	rarity_lbl.text = TagPalette.rarity_name(item.rarity)
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_lbl.add_theme_font_size_override("font_size", 10)
	rarity_lbl.add_theme_color_override("font_color", TagPalette.rarity_color(item.rarity))
	vbox.add_child(rarity_lbl)

	var name_lbl := Label.new()
	name_lbl.text = item.display_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.78, 0.55))
	vbox.add_child(name_lbl)

	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.custom_minimum_size = Vector2(80, 80)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon)

	# Tag-Chips mit Synergie-Hervorhebung
	var boosted := SynergyHelper.tags_boosted_for_candidate(item)
	var chips := TagChips.new()
	chips.alignment = FlowContainer.ALIGNMENT_CENTER
	vbox.add_child(chips)
	chips.set_tags(item.tags, boosted)

	var stats_lbl := Label.new()
	stats_lbl.text = "Cooldown: %.1fs" % item.cooldown_seconds
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.add_theme_font_size_override("font_size", 13)
	stats_lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 0.60))
	vbox.add_child(stats_lbl)
	var reward_effect: String = item.primary_effect_label()
	if reward_effect != "":
		var effect_lbl := Label.new()
		effect_lbl.text = reward_effect
		effect_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		effect_lbl.add_theme_font_size_override("font_size", 14)
		effect_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.55))
		vbox.add_child(effect_lbl)

	# „Beste Etage"-Hinweis prominent
	if item.floor_affinity.size() > 0:
		var affinity_lbl := Label.new()
		affinity_lbl.text = "↑ Beste Etage: %s  (+15%%)" % _floor_names(item.floor_affinity)
		affinity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		affinity_lbl.add_theme_font_size_override("font_size", 13)
		affinity_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
		vbox.add_child(affinity_lbl)

	var desc_lbl := RichTextLabel.new()
	desc_lbl.bbcode_enabled = true
	desc_lbl.fit_content = true
	desc_lbl.scroll_active = false
	desc_lbl.custom_minimum_size = Vector2(0, 50)
	desc_lbl.add_theme_font_size_override("normal_font_size", 12)
	desc_lbl.text = "[center]%s[/center]" % TagPalette.colorize_tags(item.description)
	# Transparenter Hintergrund — kein zusätzliches Panel-Theme greifen lassen
	var transparent_box := StyleBoxEmpty.new()
	desc_lbl.add_theme_stylebox_override("normal", transparent_box)
	desc_lbl.add_theme_stylebox_override("focus", transparent_box)
	vbox.add_child(desc_lbl)

	# Synergie-Hinweis ODER Warnung bei wirkungslosem Item
	var is_dead: bool = SynergyHelper.is_dead_for_build(item)
	var is_duplicate_buff: bool = SynergyHelper.has_duplicate_buff(item)
	var synergy_text: String = SynergyHelper.synergy_summary(item)
	if is_dead or is_duplicate_buff:
		var warn_panel := PanelContainer.new()
		var wsb := StyleBoxFlat.new()
		wsb.bg_color = Color(0.24, 0.10, 0.10, 1.0)
		wsb.border_color = Color(0.92, 0.45, 0.40, 0.85)
		wsb.set_border_width_all(1)
		wsb.set_corner_radius_all(4)
		wsb.set_content_margin_all(8)
		warn_panel.add_theme_stylebox_override("panel", wsb)
		var w_label := RichTextLabel.new()
		w_label.bbcode_enabled = true
		w_label.fit_content = true
		w_label.scroll_active = false
		w_label.add_theme_font_size_override("normal_font_size", 11)
		w_label.add_theme_color_override("default_color", Color(1.0, 0.78, 0.72))
		var transparent: StyleBoxEmpty = StyleBoxEmpty.new()
		w_label.add_theme_stylebox_override("normal", transparent)
		w_label.add_theme_stylebox_override("focus", transparent)
		var warn_text: String
		if is_duplicate_buff:
			warn_text = "⚠ Dieser Buff ist schon aktiv — Tag-Buffs überschreiben sich, nicht addieren."
		else:
			warn_text = "⚠ Wirkungslos: keiner deiner Items hat den passenden Tag"
		w_label.text = TagPalette.colorize_tags(warn_text)
		warn_panel.add_child(w_label)
		vbox.add_child(warn_panel)
	elif synergy_text != "":
		var synergy_panel := PanelContainer.new()
		var ssb := StyleBoxFlat.new()
		ssb.bg_color = Color(0.22, 0.18, 0.10, 1.0)
		ssb.border_color = Color(1.0, 0.85, 0.45, 0.8)
		ssb.set_border_width_all(1)
		ssb.set_corner_radius_all(4)
		ssb.set_content_margin_all(8)
		synergy_panel.add_theme_stylebox_override("panel", ssb)
		var s_label := RichTextLabel.new()
		s_label.bbcode_enabled = true
		s_label.fit_content = true
		s_label.scroll_active = false
		s_label.add_theme_font_size_override("normal_font_size", 11)
		s_label.add_theme_color_override("default_color", Color(1.0, 0.9, 0.7))
		var transparent2: StyleBoxEmpty = StyleBoxEmpty.new()
		s_label.add_theme_stylebox_override("normal", transparent2)
		s_label.add_theme_stylebox_override("focus", transparent2)
		s_label.text = TagPalette.colorize_tags("✦ %s" % synergy_text)
		synergy_panel.add_child(s_label)
		vbox.add_child(synergy_panel)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var choose_btn := Button.new()
	choose_btn.text = "Hinzufügen"
	choose_btn.custom_minimum_size = Vector2(0, 36)
	choose_btn.add_theme_font_size_override("font_size", 14)
	choose_btn.pressed.connect(_on_item_chosen.bind(item))
	vbox.add_child(choose_btn)

	return panel

func _make_heal_card() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 420)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.16, 0.13, 1.0)
	sb.border_color = Color(0.45, 0.85, 0.50, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = "Werkstatt-Reparatur"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color(0.55, 0.95, 0.60))
	vbox.add_child(name_lbl)

	var heal_amount: int = int(round(float(RunState.tower_max_hp) * HEAL_PERCENT))
	var current_missing: int = RunState.tower_max_hp - RunState.tower_hp
	var actual: int = min(heal_amount, current_missing)

	var big_label := Label.new()
	big_label.text = "+%d HP" % heal_amount
	big_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_label.add_theme_font_size_override("font_size", 36)
	big_label.add_theme_color_override("font_color", Color(0.65, 1.0, 0.70))
	vbox.add_child(big_label)

	var desc_lbl := Label.new()
	desc_lbl.text = "Stelle %d%% deiner Maximalrüstung wieder her (max. %d HP). Aktuell fehlen %d HP." % [
		int(HEAL_PERCENT * 100),
		actual,
		current_missing,
	]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8))
	vbox.add_child(desc_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var btn := Button.new()
	btn.text = "Reparieren"
	btn.custom_minimum_size = Vector2(0, 36)
	btn.add_theme_font_size_override("font_size", 14)
	btn.disabled = current_missing <= 0
	if btn.disabled:
		btn.text = "Volle HP"
	btn.pressed.connect(_on_repair_chosen.bind(heal_amount))
	vbox.add_child(btn)

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

func _on_item_chosen(item: Item) -> void:
	if RunState.is_coop:
		CoopManager.sync_action("reward_pick_item", {"item_id": _item_id_from_resource(item)})
	else:
		_apply_pick_item(item.resource_path)

func _on_repair_chosen(heal_amount: int) -> void:
	if RunState.is_coop:
		CoopManager.sync_action("reward_repair", {"amount": heal_amount})
	else:
		_apply_repair(heal_amount)

var _reroll_btn: Button = null

func _setup_mastermind_reroll() -> void:
	# Nur fuer Mastermind: 1x gratis Reroll pro Item-Belohnung.
	if RunState.current_character_id != "mastermind":
		return
	var footer: HBoxContainer = $Layout/Footer
	_reroll_btn = Button.new()
	_reroll_btn.custom_minimum_size = Vector2(220, 36)
	_reroll_btn.text = "🎲 Neu würfeln (1x gratis)"
	_reroll_btn.add_theme_font_size_override("font_size", 13)
	_reroll_btn.pressed.connect(_on_reroll)
	# Vor dem Skip-Button einsortieren
	footer.add_child(_reroll_btn)
	footer.move_child(_reroll_btn, 0)

func _on_reroll() -> void:
	if _reroll_used:
		return
	_reroll_used = true
	_reroll_offset += 1
	AudioManager.ui("select")
	if _reroll_btn != null:
		_reroll_btn.disabled = true
		_reroll_btn.text = "🎲 Bereits gewürfelt"
	_build_choices()

func _on_skip() -> void:
	if RunState.is_coop:
		CoopManager.sync_action("reward_skip", {})
	else:
		_apply_skip()

func _apply_pick_item(resource_path: String) -> void:
	AudioManager.ui("select")
	var item: Item = load(resource_path)
	if item == null:
		return
	RunState.add_to_inventory(item)
	get_tree().change_scene_to_file("res://scenes/MapView.tscn")

func _apply_repair(heal_amount: int) -> void:
	AudioManager.sfx("heal", -4.0)
	RunState.tower_hp = min(RunState.tower_max_hp, RunState.tower_hp + heal_amount)
	get_tree().change_scene_to_file("res://scenes/MapView.tscn")

func _apply_skip() -> void:
	AudioManager.ui("select")
	RunState.gold += _skip_gold_reward()
	get_tree().change_scene_to_file("res://scenes/MapView.tscn")

func _skip_gold_reward() -> int:
	return SKIP_GOLD_REWARD + MetaState.upgrade_level("skip_bonus") * 5

func _on_coop_action(action: String, payload: Dictionary) -> void:
	match action:
		"reward_pick_item":
			var item_id: String = String(payload.get("item_id", ""))
			if item_id != "":
				_apply_pick_item("res://data/items/%s.tres" % item_id)
		"reward_repair":
			_apply_repair(int(payload.get("amount", 0)))
		"reward_skip":
			_apply_skip()

func _item_id_from_resource(item: Item) -> String:
	# Extrahiere die ID aus dem Pfad: res://data/items/<id>.tres
	var p: String = item.resource_path
	if p.is_empty():
		return ""
	var fname: String = p.get_file()  # "<id>.tres"
	return fname.get_basename()
