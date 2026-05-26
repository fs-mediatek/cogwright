class_name Projectile extends Node2D

const TRAVEL_TIME: float = 0.42
const ARC_HEIGHT: float = 80.0
const SPIN_TURNS: float = 1.5

signal impacted

var _icon: TextureRect
var _start: Vector2
var _end: Vector2
var _age: float = 0.0
var _done: bool = false
var _speed_multiplier: float = 1.0

func _ready() -> void:
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(36, 36)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.pivot_offset = Vector2(18, 18)
	_icon.position = Vector2(-18, -18)
	_icon.size = Vector2(36, 36)
	add_child(_icon)

func launch(from_pos: Vector2, to_pos: Vector2, icon: Texture2D, tint: Color, speed_multiplier: float = 1.0) -> void:
	_start = from_pos
	_end = to_pos
	_speed_multiplier = max(0.1, speed_multiplier)
	global_position = from_pos
	if not is_node_ready():
		await ready
	_icon.texture = icon
	_icon.modulate = tint

func _process(delta: float) -> void:
	if _done:
		return
	_age += delta * _speed_multiplier
	var travel: float = TRAVEL_TIME
	var t: float = clamp(_age / travel, 0.0, 1.0)
	# Easing für „Beschleunigen ans Ziel"
	var ease_t: float = t * t * (3.0 - 2.0 * t)
	# Linear interpolierte Position + Bogen
	var linear_pos: Vector2 = _start.lerp(_end, ease_t)
	var arc_offset: float = -sin(t * PI) * ARC_HEIGHT
	global_position = linear_pos + Vector2(0, arc_offset)
	_icon.rotation = t * TAU * SPIN_TURNS
	_icon.scale = Vector2.ONE * (0.8 + 0.4 * sin(t * PI))
	if t >= 1.0:
		_done = true
		impacted.emit()
		queue_free()
