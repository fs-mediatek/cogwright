class_name FloatingNumber extends Label

const LIFETIME: float = 1.2
const RISE_DISTANCE: float = 50.0

var _age: float = 0.0
var _start_position: Vector2
var _is_crit: bool = false
var _is_combo: bool = false

func show_text(display: String, color: Color, start_pos: Vector2, is_crit: bool = false, is_combo: bool = false) -> void:
	text = display
	_is_crit = is_crit
	_is_combo = is_combo
	add_theme_color_override("font_color", color)
	var size: int = 22
	if is_crit:
		size = 38
	elif is_combo:
		size = 28
	add_theme_font_size_override("font_size", size)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	add_theme_constant_override("outline_size", 6 if is_crit else 4)
	_start_position = start_pos
	position = start_pos
	_age = 0.0
	pivot_offset = size * Vector2(0.5, 0.5)

func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	var t: float = _age / LIFETIME
	position = _start_position - Vector2(0, RISE_DISTANCE * t)
	modulate.a = 1.0 - smoothstep(0.6, 1.0, t)
	if _is_crit:
		# Schneller pop-in dann shrink-back: anfangs 1.4x, dann auf 1.0
		var pop: float = 1.0 + 0.45 * (1.0 - smoothstep(0.0, 0.20, t))
		scale = Vector2(pop, pop)
	elif _is_combo:
		var pop: float = 1.0 + 0.25 * (1.0 - smoothstep(0.0, 0.18, t))
		scale = Vector2(pop, pop)
