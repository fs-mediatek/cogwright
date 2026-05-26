extends Control

@export var is_victory: bool = false

@onready var _title: Label = $Center/VBox/TitleLabel
@onready var _stats: Label = $Center/VBox/StatsLabel
@onready var _flavor: Label = $Center/VBox/FlavorLabel
@onready var _damage_breakdown: VBoxContainer = get_node_or_null("Center/VBox/DamageBreakdown")
@onready var _new_run_btn: Button = $Center/VBox/Buttons/NewRunButton
@onready var _menu_btn: Button = $Center/VBox/Buttons/MenuButton
@onready var _log_toggle_btn: Button = $Center/VBox/Buttons/LogToggleButton
@onready var _log_panel: PanelContainer = $LogPanel
@onready var _log_text: RichTextLabel = $LogPanel/VBox/LogText
@onready var _log_close_btn: Button = $LogPanel/VBox/CloseButton
@onready var _log_title: Label = $LogPanel/VBox/Header

func _ready() -> void:
	_install_hero_background()
	_apply_text_legibility()
	if is_victory:
		_title.text = "Run abgeschlossen!"
		_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
		var boss_name: String = RunState.last_encounter_name if RunState.last_encounter_name != "" else "Der letzte Boss"
		_flavor.text = "%s ist gefallen.\nDeine Werkstatt rauscht weiter durch das Aetherland." % boss_name
		AudioManager.ui("victory")
		AudioManager.sting("victory", -4.0)
	else:
		_title.text = "Turm zerschlagen"
		_title.add_theme_color_override("font_color", Color(0.9, 0.5, 0.4))
		_flavor.text = "Diesmal nicht. Aber jede gefallene Werkstatt\nhinterlässt eine Lektion."
		AudioManager.ui("defeat")
		AudioManager.sting("defeat", -4.0)
	var stats_parts: Array[String] = []
	stats_parts.append("Encounter gewonnen: %d" % RunState.encounters_won)
	stats_parts.append("+%d Resonanzkristalle (gesamt: %d)" % [MetaState.last_run_crystals, MetaState.resonance_crystals])
	if not MetaState.last_run_unlocks.is_empty():
		stats_parts.append("")
		stats_parts.append("✦ Freigeschaltet:")
		for u in MetaState.last_run_unlocks:
			stats_parts.append("  • " + u)
	stats_parts.append("")
	stats_parts.append("Runs insgesamt: %d gewonnen / %d versucht" % [MetaState.runs_won, MetaState.runs_attempted])
	_stats.text = "\n".join(stats_parts)
	_new_run_btn.pressed.connect(_on_new_run)
	_menu_btn.pressed.connect(_on_menu)
	_log_toggle_btn.pressed.connect(_on_show_log)
	_log_close_btn.pressed.connect(_on_close_log)
	_log_panel.visible = false
	_populate_log()
	_populate_damage_breakdown()
	AudioManager.play_music("res://assets/audio/music/menu_factory.ogg", -14.0)

func _install_hero_background() -> void:
	var bg_path: String = "res://assets/backgrounds/bg_victory.png" if is_victory else "res://assets/backgrounds/bg_defeat.png"
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
	# Dunkler Scrim hinter dem Text-Block, damit Labels auf hellem Himmel lesbar bleiben
	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.42)
	scrim.set_anchors_preset(Control.PRESET_CENTER)
	scrim.custom_minimum_size = Vector2(720, 360)
	scrim.size = Vector2(720, 360)
	scrim.position = Vector2(-360, -180)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	move_child(scrim, 2)

func _apply_text_legibility() -> void:
	# Schwarze Outline + hellere Farben für Labels, damit sie auf BG-Bildern lesbar bleiben
	for lbl in [_title, _stats, _flavor]:
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
		lbl.add_theme_constant_override("outline_size", 5)
	_stats.add_theme_color_override("font_color", Color(0.98, 0.94, 0.85))
	_flavor.add_theme_color_override("font_color", Color(0.92, 0.85, 0.70))

func _populate_damage_breakdown() -> void:
	if _damage_breakdown == null:
		return
	for c in _damage_breakdown.get_children():
		c.queue_free()
	var breakdown: Array = RunState.last_battle_damage_breakdown
	if breakdown.is_empty():
		return
	var total: int = 0
	for entry in breakdown:
		total += int(entry["damage_total"])
	if total <= 0:
		return
	var title := Label.new()
	title.text = "Letzte Schlacht — Schaden-Auswertung"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_damage_breakdown.add_child(title)
	for i in range(min(6, breakdown.size())):
		var entry: Dictionary = breakdown[i]
		var dmg: int = int(entry["damage_total"])
		var pct: float = float(dmg) / float(total) * 100.0
		var triggers: int = int(entry["trigger_count"])
		var crits: int = int(entry.get("crits", 0))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var icon := TextureRect.new()
		icon.texture = entry["icon"]
		icon.custom_minimum_size = Vector2(22, 22)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
		var name_lbl := Label.new()
		name_lbl.text = String(entry["item_name"])
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", Color(0.85, 0.78, 0.60))
		name_lbl.custom_minimum_size = Vector2(160, 0)
		row.add_child(name_lbl)
		var bar := PanelContainer.new()
		bar.custom_minimum_size = Vector2(0, 12)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var bar_bg := StyleBoxFlat.new()
		bar_bg.bg_color = Color(0.13, 0.10, 0.07, 1.0)
		bar_bg.border_color = Color(0.35, 0.28, 0.18, 1.0)
		bar_bg.set_border_width_all(1)
		bar_bg.set_corner_radius_all(3)
		bar.add_theme_stylebox_override("panel", bar_bg)
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
		var fill_outer := Control.new()
		fill_outer.add_child(fill)
		bar.add_child(fill_outer)
		row.add_child(bar)
		var dmg_lbl := Label.new()
		var crit_str: String = "" if crits == 0 else "  (%dx CRIT)" % crits
		dmg_lbl.text = "%d · %.0f%% · %dx%s" % [dmg, pct, triggers, crit_str]
		dmg_lbl.add_theme_font_size_override("font_size", 11)
		dmg_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
		dmg_lbl.custom_minimum_size = Vector2(160, 0)
		row.add_child(dmg_lbl)
		_damage_breakdown.add_child(row)
	var summary := Label.new()
	summary.text = "Gesamt: %d  ·  über %d Items" % [total, breakdown.size()]
	summary.add_theme_font_size_override("font_size", 10)
	summary.add_theme_color_override("font_color", Color(0.65, 0.60, 0.48))
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_damage_breakdown.add_child(summary)

func _populate_log() -> void:
	if RunState.last_battle_log.is_empty():
		_log_toggle_btn.disabled = true
		_log_toggle_btn.text = "(kein Log)"
		return
	_log_toggle_btn.disabled = false
	_log_toggle_btn.text = "Kampflog anzeigen"
	_log_title.text = "Kampflog — %s vs %s" % [
		RunState.last_battle_outcome,
		RunState.last_encounter_name,
	]
	_log_text.clear()
	for line in RunState.last_battle_log:
		_log_text.append_text(line + "\n")

func _on_show_log() -> void:
	AudioManager.ui("click")
	_log_panel.visible = true

func _on_close_log() -> void:
	AudioManager.ui("back")
	_log_panel.visible = false

func _on_new_run() -> void:
	AudioManager.ui("click")
	get_tree().change_scene_to_file("res://scenes/RunStart.tscn")

func _on_menu() -> void:
	AudioManager.ui("back")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
