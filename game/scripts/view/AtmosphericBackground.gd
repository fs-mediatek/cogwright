class_name AtmosphericBackground extends Control

# Wiederverwendbarer Steampunk-Atmosphäre-Hintergrund.
# Zeichnet langsam rotierende, transparente Zahnräder + treibende Dampfwolken.
# Wird hinter dem UI-Layout plaziert (mouse_filter = IGNORE).

@export var cog_count: int = 6
@export var steam_puff_count: int = 18
@export var pipe_columns: int = 0   # vertikale Rohr-Silhouetten am linken/rechten Rand
@export var steam_color: Color = Color(1.0, 0.95, 0.85, 0.08)
@export var cog_color: Color = Color(0.32, 0.23, 0.14, 0.22)
@export var pipe_color: Color = Color(0.20, 0.14, 0.08, 0.30)
@export var rng_seed: int = 17

var _time: float = 0.0
var _cogs: Array[Dictionary] = []
var _puffs: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_seed_cogs()
	_seed_puffs()
	set_process(true)

func _seed_cogs() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	for i in range(cog_count):
		_cogs.append({
			"pos": Vector2(rng.randf(), rng.randf()),  # normalized 0-1
			"radius": rng.randf_range(70.0, 180.0),
			"speed": rng.randf_range(0.06, 0.20) * (1.0 if rng.randf() > 0.5 else -1.0),
			"phase": rng.randf() * TAU,
			"alpha_mul": rng.randf_range(0.5, 1.2),
		})

func _seed_puffs() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed + 89
	for i in range(steam_puff_count):
		_puffs.append(_random_puff(rng, true))

func _random_puff(rng: RandomNumberGenerator, anywhere: bool) -> Dictionary:
	var y: float = rng.randf() if anywhere else 1.05 + rng.randf() * 0.15
	return {
		"pos": Vector2(rng.randf(), y),
		"vel": Vector2(rng.randf_range(-0.003, 0.003), -rng.randf_range(0.025, 0.07)),
		"radius": rng.randf_range(40.0, 120.0),
		"alpha": rng.randf_range(0.4, 1.0),
		"lifetime": rng.randf_range(10.0, 18.0),
		"age": rng.randf_range(0.0, 8.0) if anywhere else 0.0,
	}

func _process(delta: float) -> void:
	_time += delta
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed + int(_time * 1000.0)
	for puff in _puffs:
		puff["pos"] = puff["pos"] + puff["vel"] * delta
		puff["age"] = float(puff["age"]) + delta
		if float(puff["age"]) >= float(puff["lifetime"]) or float(puff["pos"].y) < -0.25:
			var fresh: Dictionary = _random_puff(rng, false)
			for k in fresh.keys():
				puff[k] = fresh[k]
	queue_redraw()

func _draw() -> void:
	var s: Vector2 = size
	# Vertikale Rohr-Silhouetten (optional)
	if pipe_columns > 0:
		for c in range(pipe_columns):
			var x_norm: float = float(c + 1) / float(pipe_columns + 1)
			var x: float = x_norm * s.x
			# Edge-Pipes: links und rechts dunkler/dicker
			var is_edge: bool = (c == 0 or c == pipe_columns - 1)
			var w: float = 22.0 if is_edge else 14.0
			draw_rect(Rect2(x - w * 0.5, 0, w, s.y), pipe_color, true)
			# Nieten alle 80px
			var y_pos: float = 30.0
			while y_pos < s.y:
				draw_circle(Vector2(x, y_pos), w * 0.20, Color(pipe_color.r * 1.5, pipe_color.g * 1.5, pipe_color.b * 1.5, pipe_color.a * 1.3))
				y_pos += 80.0
	# Zahnräder
	for cog in _cogs:
		var center := Vector2(float(cog["pos"].x) * s.x, float(cog["pos"].y) * s.y)
		var col: Color = cog_color
		col.a = cog_color.a * float(cog["alpha_mul"])
		_draw_cogwheel(center, float(cog["radius"]), _time * float(cog["speed"]) + float(cog["phase"]), col)
	# Dampfwolken
	for puff in _puffs:
		var fade_in: float = clamp(float(puff["age"]) / 2.0, 0.0, 1.0)
		var fade_out: float = 1.0 - clamp((float(puff["age"]) - (float(puff["lifetime"]) - 3.0)) / 3.0, 0.0, 1.0)
		var fade: float = fade_in * fade_out
		var col: Color = steam_color
		col.a = steam_color.a * fade * float(puff["alpha"])
		var center := Vector2(float(puff["pos"].x) * s.x, float(puff["pos"].y) * s.y)
		var r: float = float(puff["radius"])
		draw_circle(center, r, col)
		col.a *= 1.6
		draw_circle(center, r * 0.55, col)

func _draw_cogwheel(center: Vector2, radius: float, rotation: float, color: Color) -> void:
	var teeth: int = 16
	var tooth_depth: float = radius * 0.16
	var samples_per_tooth: int = 4
	var total_samples: int = teeth * samples_per_tooth
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(total_samples):
		var t: float = float(i) / float(total_samples)
		var ang: float = t * TAU + rotation
		var sub: float = fmod(t * float(teeth), 1.0)
		var r: float = radius
		if sub >= 0.30 and sub < 0.80:
			r = radius - tooth_depth
		pts.append(center + Vector2(cos(ang), sin(ang)) * r)
	pts.append(pts[0])
	draw_polyline(pts, color, 2.5, true)
	draw_arc(center, radius * 0.45, 0.0, TAU, 48, color, 2.0, true)
	for s_idx in range(4):
		var ang: float = float(s_idx) * TAU * 0.25 + rotation
		var p1: Vector2 = center + Vector2(cos(ang), sin(ang)) * (radius * 0.45)
		var p2: Vector2 = center + Vector2(cos(ang), sin(ang)) * (radius - tooth_depth - 4.0)
		draw_line(p1, p2, color, 2.0, true)
