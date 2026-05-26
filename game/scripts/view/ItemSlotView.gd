class_name ItemSlotView extends PanelContainer

const FLASH_DURATION: float = 0.28
const FLASH_COLOR: Color = Color(1.7, 1.5, 0.95)
const NORMAL_COLOR: Color = Color(1, 1, 1)
const AFFINITY_BORDER: Color = Color(0.78, 0.62, 0.36, 1.0)
const NORMAL_BORDER: Color = Color(0.30, 0.27, 0.23, 1.0)

var slot: ItemSlot
var floor_id: StringName
var floor_modifier: float = 0.0

var _flash_remaining: float = 0.0
var _icon_anim_t: float = 0.0  # 0..1 → bounce-back

@onready var _name_label: Label = $VBox/NameLabel
@onready var _ring_holder: Control = $VBox/RingHolder
@onready var _ring: CooldownRing = $VBox/RingHolder/CooldownRing
@onready var _icon: TextureRect = $VBox/RingHolder/IconCenter/Icon
@onready var _icon_center: CenterContainer = $VBox/RingHolder/IconCenter
@onready var _info_label: Label = $VBox/InfoLabel
@onready var _particles: CPUParticles2D = $VBox/RingHolder/Particles

func _ready() -> void:
	modulate = NORMAL_COLOR

func bind(_slot: ItemSlot, _floor_id: StringName, _floor_modifier: float) -> void:
	slot = _slot
	floor_id = _floor_id
	floor_modifier = _floor_modifier
	if is_node_ready():
		_apply_static()
	else:
		ready.connect(_apply_static, CONNECT_ONE_SHOT)

func _apply_static() -> void:
	if slot == null:
		_name_label.text = "(leer)"
		_info_label.text = ""
		_icon.texture = null
		_ring.progress = 0.0
		tooltip_text = ""
		return
	_name_label.text = slot.item.display_name
	_info_label.text = "CD %.1fs" % slot.item.cooldown_seconds
	_icon.texture = slot.item.icon
	tooltip_text = slot.item.tooltip_text()
	mouse_filter = Control.MOUSE_FILTER_STOP

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.14, 0.12, 0.10, 1.0)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	if _has_affinity():
		sb.bg_color = Color(0.19, 0.16, 0.11, 1.0)
		sb.border_color = AFFINITY_BORDER
		sb.set_border_width_all(2)
	else:
		sb.border_color = NORMAL_BORDER
		sb.set_border_width_all(1)
	add_theme_stylebox_override("panel", sb)
	_tune_particles_for_item()

func _tune_particles_for_item() -> void:
	# Partikel-Farbe + Verhalten basierend auf primary tag
	if _particles == null or slot == null:
		return
	var tags: Array = slot.item.tags
	var grad := Gradient.new()
	# Defaults: golden sparks
	var c1: Color = Color(1.0, 0.85, 0.40, 1.0)
	var c2: Color = Color(1.0, 0.55, 0.15, 0.7)
	var c3: Color = Color(1.0, 0.40, 0.10, 0.0)
	var gravity_y: float = -40.0
	if &"fire" in tags:
		c1 = Color(1.0, 0.70, 0.20, 1.0)
		c2 = Color(1.0, 0.30, 0.05, 0.7)
		c3 = Color(0.85, 0.10, 0.05, 0.0)
		gravity_y = -60.0   # Funken steigen schneller
	elif &"steam" in tags:
		c1 = Color(0.95, 0.95, 1.0, 0.9)
		c2 = Color(0.80, 0.85, 0.95, 0.5)
		c3 = Color(0.75, 0.80, 0.90, 0.0)
		gravity_y = -55.0   # Dampf steigt
	elif &"pressure" in tags:
		c1 = Color(0.95, 0.78, 0.40, 1.0)
		c2 = Color(0.85, 0.65, 0.25, 0.7)
		c3 = Color(0.75, 0.55, 0.18, 0.0)
		gravity_y = -30.0
	elif &"mechanical" in tags or &"blunt" in tags:
		c1 = Color(0.85, 0.80, 0.70, 1.0)
		c2 = Color(0.65, 0.60, 0.50, 0.6)
		c3 = Color(0.45, 0.42, 0.35, 0.0)
		gravity_y = 40.0   # Metall-Splitter fallen
	elif &"precision" in tags or &"ranged" in tags:
		c1 = Color(0.55, 0.85, 1.0, 1.0)
		c2 = Color(0.35, 0.70, 0.95, 0.7)
		c3 = Color(0.25, 0.55, 0.85, 0.0)
		gravity_y = -25.0
	elif &"support" in tags:
		c1 = Color(0.55, 0.95, 0.55, 1.0)
		c2 = Color(0.40, 0.85, 0.50, 0.7)
		c3 = Color(0.30, 0.70, 0.40, 0.0)
		gravity_y = -45.0
	grad.set_color(0, c1)
	grad.add_point(0.5, c2)
	grad.set_color(grad.get_point_count() - 1, c3)
	_particles.color_ramp = grad
	_particles.gravity = Vector2(0, gravity_y)

func _has_affinity() -> bool:
	if slot == null:
		return false
	return slot.item.floor_affinity.has(floor_id)

func refresh() -> void:
	if slot == null:
		return
	var cd: float = slot.item.cooldown_seconds
	if cd <= 0.001:
		_ring.progress = 0.0
		_info_label.text = ""
		return
	var progress: float = (cd - max(0.0, slot.time_until_trigger)) / cd
	_ring.progress = clamp(progress, 0.0, 1.0)
	var current_speed: float = slot.current_speed(floor_modifier)
	var seconds_left: float = max(0.0, slot.time_until_trigger) / max(current_speed, 0.01)
	if cd >= 90.0:
		_info_label.text = "reaktiv"
	else:
		_info_label.text = "%.1fs" % seconds_left

func flash() -> void:
	_flash_remaining = FLASH_DURATION
	modulate = FLASH_COLOR
	_icon_anim_t = 0.0
	if _particles:
		_particles.restart()
		_particles.emitting = true

func _process(delta: float) -> void:
	if _flash_remaining > 0.0:
		_flash_remaining = max(0.0, _flash_remaining - delta)
		var t: float = _flash_remaining / FLASH_DURATION
		modulate = NORMAL_COLOR.lerp(FLASH_COLOR, t)
		# Icon-Bounce: scale 1.0 -> 1.25 -> 1.0
		_icon_anim_t = 1.0 - t
		var s: float = 1.0 + sin(_icon_anim_t * PI) * 0.25
		_icon_center.scale = Vector2(s, s)
		_icon_center.pivot_offset = _icon_center.size * 0.5
	else:
		_icon_center.scale = Vector2.ONE
