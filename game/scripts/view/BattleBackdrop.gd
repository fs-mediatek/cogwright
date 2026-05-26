extends Control

# Battle-Hintergrund: zwei Lagen ferner Werkstatt-Silhouetten + Horizont.
# Hinter dem eigentlichen Kampfgeschehen, vor dem ColorRect-Background.

@export var sky_color_top: Color = Color(0.10, 0.08, 0.07, 1.0)
@export var sky_color_bottom: Color = Color(0.16, 0.12, 0.09, 1.0)
@export var far_silhouette: Color = Color(0.13, 0.10, 0.07, 1.0)
@export var near_silhouette: Color = Color(0.08, 0.06, 0.05, 1.0)
@export var horizon_glow: Color = Color(0.85, 0.55, 0.30, 0.18)

# Boss-spezifische Farb-Paletten — werden über set_palette_for_boss() angewendet
const BOSS_PALETTES: Dictionary = {
	"warlord":              {"sky_top": Color(0.10, 0.08, 0.07), "sky_bot": Color(0.16, 0.12, 0.09), "glow": Color(0.85, 0.55, 0.30, 0.18)},
	"uhrwerk_hexe":         {"sky_top": Color(0.12, 0.08, 0.16), "sky_bot": Color(0.20, 0.10, 0.22), "glow": Color(0.70, 0.45, 0.95, 0.20)},
	"funken_tyrann":        {"sky_top": Color(0.18, 0.08, 0.05), "sky_bot": Color(0.30, 0.12, 0.06), "glow": Color(1.00, 0.45, 0.20, 0.25)},
	"stiller_maschinist":   {"sky_top": Color(0.07, 0.09, 0.11), "sky_bot": Color(0.11, 0.13, 0.16), "glow": Color(0.85, 0.85, 0.95, 0.15)},
	"oelbaron_krasnik":     {"sky_top": Color(0.09, 0.10, 0.06), "sky_bot": Color(0.14, 0.16, 0.08), "glow": Color(0.65, 0.85, 0.30, 0.15)},
	"gravelock":            {"sky_top": Color(0.07, 0.10, 0.13), "sky_bot": Color(0.12, 0.16, 0.20), "glow": Color(0.55, 0.75, 0.95, 0.16)},
	"schwarze_lokomotive":  {"sky_top": Color(0.06, 0.05, 0.05), "sky_bot": Color(0.14, 0.08, 0.06), "glow": Color(0.95, 0.40, 0.18, 0.22)},
}

var _time: float = 0.0
var _far_offset: float = 0.0
var _near_offset: float = 0.0
var _sky_texture: Texture2D = null
var _far_buildings_texture: Texture2D = null
var _mid_buildings_texture: Texture2D = null
var _foreground_texture: Texture2D = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Optional: geladene Hintergrund-PNGs nutzen (Parallax-Layer)
	_sky_texture = _try_load_texture("res://assets/backgrounds/bg_city_sky.png")
	_far_buildings_texture = _try_load_texture("res://assets/backgrounds/bg_city_far_buildings.png")
	_mid_buildings_texture = _try_load_texture("res://assets/backgrounds/bg_city_mid_buildings.png")
	_foreground_texture = _try_load_texture("res://assets/backgrounds/bg_city_foreground.png")
	set_process(true)

func _try_load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	return res if res is Texture2D else null

func set_palette_for_boss(boss_id: String) -> void:
	# Wird von BattleView vor Battle-Start aufgerufen, wenn ein Boss-Encounter läuft.
	if not BOSS_PALETTES.has(boss_id):
		return
	var p: Dictionary = BOSS_PALETTES[boss_id]
	sky_color_top = p["sky_top"]
	sky_color_bottom = p["sky_bot"]
	horizon_glow = p["glow"]
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	_far_offset += delta * 4.0   # langsamer Parallax (Pixel/s)
	_near_offset += delta * 11.0  # schneller Parallax (Pixel/s)
	queue_redraw()

func _draw() -> void:
	var s: Vector2 = size
	if _sky_texture != null:
		# PNG-Himmel: skaliert auf gesamten Bereich
		draw_texture_rect(_sky_texture, Rect2(Vector2.ZERO, s), false)
		# Optionale Parallax-Layer drauf — tilable horizontal, scrollen mit unterschiedlicher Speed
		if _far_buildings_texture != null:
			_draw_tiled_parallax(_far_buildings_texture, s, _far_offset * 0.6, 0.45, 0.85)
		if _mid_buildings_texture != null:
			_draw_tiled_parallax(_mid_buildings_texture, s, _far_offset * 1.4, 0.60, 0.95)
		if _foreground_texture != null:
			_draw_tiled_parallax(_foreground_texture, s, _near_offset * 2.0, 0.78, 1.0)
		# Leichten dunklen Tint drüber für Atmosphäre-Konsistenz
		draw_rect(Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.20), true)
	else:
		# Prozedurales Gradient als Fallback
		var stripes: int = 24
		for i in range(stripes):
			var t: float = float(i) / float(stripes - 1)
			var col: Color = sky_color_top.lerp(sky_color_bottom, t)
			var y: float = t * s.y
			var h: float = s.y / float(stripes) + 1.0
			draw_rect(Rect2(0, y, s.x, h), col, true)
	# Wenn PNG-Himmel aktiv ist, keine zusätzlichen prozeduralen Silhouetten —
	# die würden sich mit dem im Bild bereits enthaltenen Skyline-Inhalt beißen.
	if _sky_texture != null:
		return
	# Horizont-Glow: breiter weicher Streifen auf ~60% Höhe
	var horizon_y: float = s.y * 0.60
	var glow_height: float = 80.0
	for i in range(8):
		var t: float = float(i) / 7.0
		var col: Color = horizon_glow
		col.a = horizon_glow.a * (1.0 - t)
		draw_rect(Rect2(0, horizon_y - glow_height * 0.5 + t * glow_height / 8.0, s.x, glow_height / 8.0 + 2.0), col, true)
	# Ferne Silhouetten (Reihe 1) — flache Häuserchen, slow parallax
	_draw_silhouette_row(horizon_y - 18.0, 110.0, _far_offset, 220.0, far_silhouette, 0)
	# Nähere Silhouetten (Reihe 2) — höhere Industrie-Gebäude
	_draw_silhouette_row(horizon_y + 6.0, 165.0, _near_offset, 280.0, near_silhouette, 1)

func _draw_tiled_parallax(tex: Texture2D, canvas_size: Vector2, offset: float, top_ratio: float, alpha: float) -> void:
	# Zeichnet die Textur tilable horizontal über den unteren Bildbereich.
	# top_ratio = wo die obere Kante des Layers in der Canvas liegt (0..1)
	# alpha = Opazität (0..1)
	var tex_w: float = float(tex.get_width())
	var tex_h: float = float(tex.get_height())
	# Skaliere Layer-Höhe an verbleibende Canvas-Höhe an
	var layer_top: float = canvas_size.y * top_ratio
	var layer_h: float = canvas_size.y - layer_top
	if tex_h <= 0.0 or tex_w <= 0.0 or layer_h <= 0.0:
		return
	var scale: float = layer_h / tex_h
	var scaled_w: float = tex_w * scale
	# Offset auf eine ganze Tile-Breite reduzieren
	var x_offset: float = -fmod(offset, scaled_w)
	if x_offset > 0:
		x_offset -= scaled_w
	var x: float = x_offset
	while x < canvas_size.x:
		var rect := Rect2(Vector2(x, layer_top), Vector2(scaled_w, layer_h))
		draw_texture_rect(tex, rect, false, Color(1, 1, 1, alpha))
		x += scaled_w

func _draw_silhouette_row(base_y: float, max_height: float, offset: float, spacing: float, color: Color, variant: int) -> void:
	var s: Vector2 = size
	# Wiederholende Silhouetten-Muster — Offset modulo spacing für endloses scrollen
	var x_start: float = -fmod(offset, spacing) - spacing
	var x: float = x_start
	var rng := RandomNumberGenerator.new()
	rng.seed = variant * 73 + 41
	# Pre-generate building list deterministically — gleicher Seed für alle Frames
	var pattern_buildings: Array = []
	for i in range(int(s.x / spacing) + 4):
		pattern_buildings.append({
			"width": rng.randf_range(spacing * 0.55, spacing * 0.95),
			"height": rng.randf_range(max_height * 0.45, max_height),
			"roof_type": rng.randi() % 3,  # 0=flat, 1=peak, 2=stepped
			"chimney_offset": rng.randf_range(0.2, 0.8),
			"chimney_height": rng.randf_range(20.0, 38.0),
		})
	for i in range(pattern_buildings.size()):
		var b: Dictionary = pattern_buildings[i]
		var bw: float = float(b["width"])
		var bh: float = float(b["height"])
		var bx: float = x + spacing * float(i)
		var by: float = base_y - bh
		_draw_building(bx, by, bw, bh, int(b["roof_type"]), float(b["chimney_offset"]), float(b["chimney_height"]), color)

func _draw_building(x: float, y: float, w: float, h: float, roof_type: int, chimney_off: float, chimney_h: float, color: Color) -> void:
	var body: PackedVector2Array = PackedVector2Array()
	match roof_type:
		0:
			# Flach
			body.append(Vector2(x, y))
			body.append(Vector2(x + w, y))
		1:
			# Spitzdach
			body.append(Vector2(x, y + 14.0))
			body.append(Vector2(x + w * 0.5, y))
			body.append(Vector2(x + w, y + 14.0))
		2:
			# Stufenförmig
			body.append(Vector2(x, y + 12.0))
			body.append(Vector2(x + w * 0.20, y + 12.0))
			body.append(Vector2(x + w * 0.20, y))
			body.append(Vector2(x + w * 0.80, y))
			body.append(Vector2(x + w * 0.80, y + 12.0))
			body.append(Vector2(x + w, y + 12.0))
	body.append(Vector2(x + w, y + h))
	body.append(Vector2(x, y + h))
	draw_colored_polygon(body, color)
	# Schornstein
	var cx: float = x + w * chimney_off
	var cw: float = 6.0
	draw_rect(Rect2(cx - cw * 0.5, y - chimney_h, cw, chimney_h), color, true)
	# Dampf am Schornstein (statisches Symbol — leichter Color-Tint)
	var smoke_col: Color = color
	smoke_col.a *= 0.35
	smoke_col.r = min(1.0, smoke_col.r * 1.8 + 0.05)
	smoke_col.g = min(1.0, smoke_col.g * 1.8 + 0.05)
	smoke_col.b = min(1.0, smoke_col.b * 1.8 + 0.05)
	draw_circle(Vector2(cx, y - chimney_h - 6.0), 7.0, smoke_col)
	draw_circle(Vector2(cx + 4.0, y - chimney_h - 14.0), 9.0, smoke_col)
