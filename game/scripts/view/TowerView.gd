class_name TowerView extends VBoxContainer

const SLOT_SCENE := preload("res://scenes/ItemSlotView.tscn")
const HP_HEALTHY: Color = Color(0.40, 0.78, 0.40)
const HP_HURT: Color = Color(0.88, 0.74, 0.32)
const HP_CRITICAL: Color = Color(0.88, 0.35, 0.30)

@onready var _name_label: Label = $NameLabel
@onready var _hp_bar: ProgressBar = $HpBar
@onready var _hp_label: Label = $HpBar/HpLabel
@onready var _buffs_label: Label = $BuffsLabel
@onready var _floors_frame: PanelContainer = $FloorsFrame
@onready var _floors_container: VBoxContainer = $FloorsFrame/FloorsContainer

var tower: Tower
var _slot_views: Dictionary = {}  # ItemSlot -> ItemSlotView
var _battle: BattleController
var _hp_bar_tween: Tween = null
var _name_tween: Tween = null

func bind(_tower: Tower, battle: BattleController = null) -> void:
	tower = _tower
	_battle = battle
	if is_node_ready():
		_build_floors()
	else:
		ready.connect(_build_floors, CONNECT_ONE_SHOT)

func _build_floors() -> void:
	_name_label.text = tower.name
	_hp_bar.max_value = tower.max_hp
	_hp_bar.value = tower.hp
	_hp_label.text = "%d / %d" % [tower.hp, tower.max_hp]
	_buffs_label.text = ""

	for child in _floors_container.get_children():
		child.queue_free()
	_slot_views.clear()
	_apply_tower_frame()

	# Pinnacle oben, Foundation unten
	for floor_idx in range(tower.floors.size() - 1, -1, -1):
		var fc: FloorConfig = tower.floors[floor_idx]
		var floor_box := VBoxContainer.new()
		floor_box.add_theme_constant_override("separation", 3)
		floor_box.size_flags_vertical = Control.SIZE_EXPAND_FILL

		var label := Label.new()
		label.text = "%d · %s" % [floor_idx, fc.display_name]
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.92, 0.82, 0.55))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		label.add_theme_constant_override("outline_size", 3)
		floor_box.add_child(label)

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		floor_box.add_child(row)

		for slot in tower.slots_on_floor(floor_idx):
			var view: ItemSlotView = SLOT_SCENE.instantiate()
			row.add_child(view)
			view.bind(slot, fc.id, fc.cooldown_speed_modifier)
			_slot_views[slot] = view

		_floors_container.add_child(floor_box)

func _apply_tower_frame() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.08, 0.06, 0.78)
	sb.border_color = Color(0.55, 0.42, 0.24, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	_floors_frame.add_theme_stylebox_override("panel", sb)

func refresh() -> void:
	if tower == null:
		return
	_hp_bar.value = tower.hp
	_hp_label.text = "%d / %d" % [tower.hp, tower.max_hp]
	_apply_hp_color()
	_refresh_buffs()
	_refresh_status_overlay()
	for slot in _slot_views.keys():
		_slot_views[slot].refresh()

func _refresh_status_overlay() -> void:
	if _battle == null:
		return
	# Burn/Slow/Shield-Status oben im HP-Label anzeigen (knapp), zusätzlich Farbtinte
	var burn: int = _battle.get_burn_total(tower)
	var slow: float = _battle.get_slow_percent(tower)
	var shield: int = _battle.get_shield_amount(tower)
	var stun: float = _battle.get_stun_remaining(tower)
	var mark: float = _battle.get_mark_percent(tower)
	var parts: Array[String] = []
	if shield > 0:
		parts.append("🛡 %d" % shield)
	if burn > 0:
		parts.append("🔥 %d/s" % burn)
	if slow > 0:
		parts.append("❄ -%.0f%%" % slow)
	if stun > 0.0:
		parts.append("⏹ %.1fs" % stun)
	if mark > 0.0:
		parts.append("◎ +%.0f%%" % mark)
	if parts.size() > 0:
		_hp_label.text = "%d / %d   %s" % [tower.hp, tower.max_hp, " ".join(parts)]

func _apply_hp_color() -> void:
	var ratio: float = 0.0 if tower.max_hp == 0 else float(tower.hp) / float(tower.max_hp)
	var color: Color
	if ratio > 0.6:
		color = HP_HEALTHY
	elif ratio > 0.3:
		color = HP_HURT
	else:
		color = HP_CRITICAL
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("fill", fill)

func _refresh_buffs() -> void:
	if _battle == null:
		_buffs_label.text = ""
		return
	if not _battle._tag_bonuses.has(tower):
		_buffs_label.text = ""
		return
	var entry: Dictionary = _battle._tag_bonuses[tower]
	if entry.is_empty():
		_buffs_label.text = ""
		return
	var parts: Array[String] = []
	for tag in entry.keys():
		var bonus: float = entry[tag]["bonus"]
		var remaining: float = entry[tag]["remaining"]
		parts.append("[%s] +%.0f%% (%.1fs)" % [String(tag), bonus, remaining])
	_buffs_label.text = "  ".join(parts)

func flash_slot(slot: ItemSlot) -> void:
	if _slot_views.has(slot):
		_slot_views[slot].flash()

func get_slot_view(slot: ItemSlot) -> ItemSlotView:
	return _slot_views.get(slot, null)

func get_global_center() -> Vector2:
	var rect := get_global_rect()
	return rect.position + rect.size * 0.5

func flash_damage(amount: int) -> void:
	# Visueller Damage-Flash: HP-Bar pulst kurz rot, Name-Label zuckt.
	if _hp_bar_tween != null and _hp_bar_tween.is_running():
		_hp_bar_tween.kill()
	_hp_bar.modulate = Color(1.6, 0.5, 0.5, 1.0)
	_hp_bar_tween = create_tween()
	_hp_bar_tween.tween_property(_hp_bar, "modulate", Color(1, 1, 1, 1), 0.30)
	if amount >= 10:
		if _name_tween != null and _name_tween.is_running():
			_name_tween.kill()
		_name_label.modulate = Color(1.5, 0.5, 0.5, 1.0)
		_name_tween = create_tween()
		_name_tween.tween_property(_name_label, "modulate", Color(1, 1, 1, 1), 0.40)
