class_name CooldownRing extends Control

@export var radius_outer: float = 28.0
@export var radius_inner: float = 22.0
@export var background_color: Color = Color(0.20, 0.16, 0.12, 0.85)
@export var fill_color: Color = Color(0.89, 0.72, 0.40, 0.95)
@export var border_color: Color = Color(0.78, 0.62, 0.36, 1.0)

# 0.0 = leer, 1.0 = voll (gleich Trigger)
var progress: float = 0.0:
	set(value):
		progress = clamp(value, 0.0, 1.0)
		queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(radius_outer * 2 + 4, radius_outer * 2 + 4)

func _draw() -> void:
	var center := size * 0.5
	# Hintergrund-Ring
	_draw_ring(center, radius_outer, radius_inner, 0.0, TAU, background_color)
	# Fortschritt — startet bei 12 Uhr (-PI/2), geht im Uhrzeigersinn
	if progress > 0.001:
		var start_angle: float = -PI / 2.0
		var end_angle: float = start_angle + TAU * progress
		_draw_ring(center, radius_outer, radius_inner, start_angle, end_angle, fill_color)
	# Aussen-Border (dünne Linie)
	draw_arc(center, radius_outer, 0.0, TAU, 48, border_color, 1.5, true)

func _draw_ring(center: Vector2, outer: float, inner: float, start_angle: float, end_angle: float, color: Color) -> void:
	var step_count: int = max(8, int(abs(end_angle - start_angle) / TAU * 48))
	var points: PackedVector2Array = PackedVector2Array()
	# Aussen-Kreis (Vorwärts)
	for i in range(step_count + 1):
		var t: float = float(i) / float(step_count)
		var a: float = lerp(start_angle, end_angle, t)
		points.append(center + Vector2(cos(a), sin(a)) * outer)
	# Innen-Kreis (Rückwärts)
	for i in range(step_count + 1):
		var t: float = 1.0 - float(i) / float(step_count)
		var a: float = lerp(start_angle, end_angle, t)
		points.append(center + Vector2(cos(a), sin(a)) * inner)
	draw_colored_polygon(points, color)
