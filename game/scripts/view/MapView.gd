extends Control

const NODE_RADIUS: float = 30.0
const NODE_HORIZONTAL_PADDING: float = 120.0
const ROW_HEIGHT: float = 110.0
const MAX_MAP_WIDTH: float = 1200.0   # Spaltenbereich nicht breiter werden lassen — sonst zerlaufen die Verbindungen optisch
const PIPE_WIDTH_NORMAL: float = 7.0
const PIPE_WIDTH_HIGHLIGHT: float = 11.0
const PIPE_OUTER_COLOR: Color = Color(0.20, 0.14, 0.08, 1.0)
const PIPE_INNER_COLOR: Color = Color(0.55, 0.42, 0.24, 1.0)
const PIPE_INNER_HIGHLIGHT: Color = Color(0.98, 0.82, 0.42, 1.0)
const PIPE_RIVET_COLOR: Color = Color(0.78, 0.60, 0.32, 1.0)

@onready var _canvas: Control = $Canvas
@onready var _title_label: Label = $Layout/Header/TitleLabel
@onready var _hp_label: Label = $Layout/Header/HpLabel
@onready var _menu_button: Button = $Layout/Footer/MenuButton
@onready var _legend_label: Label = $Layout/Footer/LegendLabel

var _node_positions: Dictionary = {}   # MapNode.id -> Vector2
var _pulse_time: float = 0.0
var _effective_row_height: float = ROW_HEIGHT   # passt sich an Canvas + Row-Count an
var _effective_node_radius: float = NODE_RADIUS   # schrumpft mit row_height bei vielen Reihen

const TOP_PADDING: float = 60.0
const BOTTOM_PADDING: float = 70.0
const MIN_ROW_HEIGHT: float = 65.0
const MIN_NODE_RADIUS: float = 18.0

func _ready() -> void:
	if not RunState.is_run_active or RunState.current_map == null:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	_menu_button.pressed.connect(_on_menu)
	# Optional: Pergament-Map-Background wenn vorhanden — überlagert das ColorRect.
	# WICHTIG: kein z_index setzen (würde das Bild HINTER das opaque ColorRect schieben).
	# Sichtbarkeit über Tree-Order: zwischen Background (0) und Layout (2).
	var bg_path: String = "res://assets/backgrounds/bg_map_parchment.png"
	if ResourceLoader.exists(bg_path):
		var res: Resource = load(bg_path)
		if res is Texture2D:
			var bg := TextureRect.new()
			bg.texture = res
			bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bg.modulate = Color(1, 1, 1, 0.85)   # Leicht dimmen, damit Knoten klarer hervortreten
			add_child(bg)
			move_child(bg, 1)   # Zwischen Background-ColorRect (0) und Layout (2)
	if RunState.is_coop:
		var coop_role: String = "Host" if CoopManager.is_host() else "Spieler 2"
		_title_label.text = "Reisekarte  ·  Co-Op (%s)" % coop_role
	else:
		_title_label.text = "Reisekarte"
	_hp_label.text = "HP: %d / %d   ·   Gold: %d" % [RunState.tower_hp, RunState.tower_max_hp, RunState.gold]
	# Auto-Save bei jedem Map-Besuch (nur Solo-Runs persistieren)
	if not RunState.is_coop:
		RunState.save_run()
	_legend_label.text = "⚔ Kampf · ❤ Reparatur · ⚙ Werkstatt · ❓ Begegnung · ☠ Elite · 🏆 Boss"
	AudioManager.play_music("res://assets/audio/music/menu_factory.ogg", -14.0)
	AudioManager.play_ambient("map")
	HintOverlay.show_if_new(self, "first_map",
		"Reisekarte",
		"Klicke einen [b]gold-umrandeten[/b] Knoten, um dorthin zu reisen.\n\n⚔ Kampf  ·  ❤ Reparatur  ·  ⚙ Werkstatt  ·  ❓ Begegnung  ·  ☠ Elite  ·  🏆 Boss\n\nNicht alle Wege führen zum Boss — wähle deine Route nach deinem Build.")
	# Auf nächsten Frame warten, damit _canvas seine endgültige Größe hat
	await get_tree().process_frame
	_compute_positions()
	_canvas.draw.connect(_draw_map)
	_build_node_buttons()
	_canvas.queue_redraw()
	set_process(true)
	if RunState.is_coop:
		_legend_label.text = "Co-Op: Klicke einen Knoten als Vorschlag — der zweite Spieler bestätigt mit demselben Klick."
		CoopManager.transition_proposed.connect(_on_transition_proposed)
		CoopManager.transition_committed.connect(_on_transition_committed)
		CoopManager.transition_cleared.connect(_on_transition_cleared)

func _process(delta: float) -> void:
	_pulse_time += delta
	_canvas.queue_redraw()

func _compute_positions() -> void:
	var map: RunMap = RunState.current_map
	var canvas_size: Vector2 = _canvas.size
	# Dynamische Row-Height: bei wenigen Reihen großzügig (110), bei vielen Reihen schrumpfen
	# damit alles in die Canvas-Höhe passt.
	var available_height: float = canvas_size.y - TOP_PADDING - BOTTOM_PADDING
	var total_rows: int = max(map.total_rows, 1)
	if total_rows > 1:
		_effective_row_height = max(MIN_ROW_HEIGHT, min(ROW_HEIGHT, available_height / float(total_rows - 1)))
	else:
		_effective_row_height = ROW_HEIGHT
	# Knoten schrumpfen wenn die Reihen eng sind, damit sie sich nicht überlappen.
	# Button-Gesamthöhe = radius*2 + 28 muss < row_height bleiben.
	var max_radius_for_height: float = (_effective_row_height - 28.0 - 8.0) * 0.5
	_effective_node_radius = clamp(max_radius_for_height, MIN_NODE_RADIUS, NODE_RADIUS)
	# Map-Bereich horizontal cappen, dann zentriert auf der Canvas platzieren.
	# Bei sehr breitem Fenster bleiben die Spalten dichter zusammen — die Pipes
	# wirken nicht mehr wie endlose Diagonalen.
	var map_width: float = min(canvas_size.x - 2.0 * NODE_HORIZONTAL_PADDING, MAX_MAP_WIDTH)
	var map_left: float = (canvas_size.x - map_width) * 0.5
	# Reihen von unten (row 0 = unten) nach oben anordnen
	for row in range(map.total_rows):
		var nodes_in_row: Array[MapNode] = map.get_nodes_in_row(row)
		nodes_in_row.sort_custom(func(a, b): return a.column < b.column)
		var count: int = nodes_in_row.size()
		var y: float = canvas_size.y - BOTTOM_PADDING - float(row) * _effective_row_height
		for i in range(count):
			var node: MapNode = nodes_in_row[i]
			var x: float
			if count == 1:
				x = canvas_size.x * 0.5
			else:
				var spacing: float = map_width / float(count - 1)
				x = map_left + float(i) * spacing
			_node_positions[node.id] = Vector2(x, y)

func _build_node_buttons() -> void:
	for child in _canvas.get_children():
		child.queue_free()
	var map: RunMap = RunState.current_map
	var reachable: Array[MapNode] = map.reachable_nodes_from_current()
	var reachable_ids: Array[int] = []
	for r in reachable:
		reachable_ids.append(r.id)
	# Reihen-Labels auf der linken Seite
	for row in range(map.total_rows):
		var lbl := _make_row_label(row)
		if lbl != null:
			_canvas.add_child(lbl)
	for node in map.nodes:
		var btn := _make_node_button(node, reachable_ids.has(node.id))
		_canvas.add_child(btn)

func _make_row_label(row: int) -> Label:
	var map: RunMap = RunState.current_map
	var nodes_in_row: Array[MapNode] = map.get_nodes_in_row(row)
	if nodes_in_row.is_empty():
		return null
	var total_rows: int = map.total_rows
	# Labels passen sich der Run-Länge an
	var row_title: String = ""
	if row == 0:
		row_title = "Aufbruch"
	elif row == total_rows - 1:
		row_title = "Spitze"
	elif row == total_rows - 2:
		row_title = "Vor dem Endkampf"
	else:
		row_title = "Etage %d" % row
	var lbl := Label.new()
	lbl.text = row_title
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.45, 0.30, 0.85))
	lbl.size = Vector2(110, 18)
	var y: float = _canvas.size.y - BOTTOM_PADDING - float(row) * _effective_row_height - 9.0
	lbl.position = Vector2(6.0, y)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl

func _node_icon_texture_path(node: MapNode) -> String:
	match node.type:
		MapNode.NodeType.START: return "res://assets/ui/map_nodes/map_start.png"
		MapNode.NodeType.BOSS: return "res://assets/ui/map_nodes/map_boss.png"
		MapNode.NodeType.ELITE: return "res://assets/ui/map_nodes/map_elite.png"
		MapNode.NodeType.SHOP: return "res://assets/ui/map_nodes/map_shop.png"
		MapNode.NodeType.EVENT: return "res://assets/ui/map_nodes/map_event.png"
		MapNode.NodeType.HEAL: return "res://assets/ui/map_nodes/map_heal.png"
		MapNode.NodeType.COMBAT: return "res://assets/ui/map_nodes/map_combat.png"
		_: return ""

func _make_node_button(node: MapNode, is_reachable: bool) -> Button:
	var btn := Button.new()
	var size_px: float = _effective_node_radius * 2.0 + 28.0
	btn.size = Vector2(size_px, size_px)
	btn.position = _node_positions[node.id] - btn.size * 0.5
	# PNG-Icon nutzen wenn vorhanden, sonst Fallback auf Emoji+Label
	var tex_path: String = _node_icon_texture_path(node)
	var has_icon: bool = ResourceLoader.exists(tex_path)
	if has_icon:
		btn.text = ""
		btn.icon = load(tex_path)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.expand_icon = true
	else:
		btn.text = "%s\n%s" % [_node_icon(node), _node_label(node)]
		btn.add_theme_font_size_override("font_size", 11)
	btn.disabled = not is_reachable
	# Typ-Farbpalette
	var type_color: Color = _type_accent(node.type)
	# Farbig nach Typ und State
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(int(size_px * 0.5))
	sb.set_content_margin_all(4)
	if node.completed:
		sb.bg_color = Color(0.18, 0.14, 0.09, 1.0)
		sb.border_color = Color(0.36, 0.30, 0.20, 1.0)
		sb.set_border_width_all(2)
		btn.add_theme_color_override("font_color", Color(0.55, 0.50, 0.40))
	elif is_reachable:
		sb.bg_color = type_color.darkened(0.55)
		sb.border_color = type_color
		sb.set_border_width_all(3)
		sb.shadow_color = type_color * Color(1, 1, 1, 0.55)
		sb.shadow_size = 8
		btn.add_theme_color_override("font_color", type_color.lerp(Color(1, 1, 1), 0.55))
	else:
		sb.bg_color = Color(0.11, 0.09, 0.07, 1.0)
		sb.border_color = type_color.darkened(0.55)
		sb.set_border_width_all(1)
		btn.add_theme_color_override("font_color", type_color.darkened(0.25))
	# Coop-Vorschlag-Marker: leuchtend cyan wenn jemand diesen Knoten vorgeschlagen hat
	if RunState.is_coop:
		var prop_key: String = "map:%d" % node.id
		if CoopManager.pending_transitions.has(prop_key):
			var proposer: int = int(CoopManager.pending_transitions[prop_key])
			var is_own: bool = (proposer == CoopManager.local_peer_id())
			var color: Color = Color(0.95, 0.78, 0.35, 1.0) if is_own else Color(0.55, 0.95, 0.95, 1.0)
			sb.border_color = color
			sb.set_border_width_all(4)
			sb.shadow_color = color * Color(1, 1, 1, 0.6)
			sb.shadow_size = 12
	btn.add_theme_stylebox_override("normal", sb)
	# Hover-Variation
	var sb_hover := sb.duplicate()
	sb_hover.bg_color = sb.bg_color.lerp(Color(1, 0.9, 0.7), 0.20)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	btn.tooltip_text = _node_tooltip(node, is_reachable)
	btn.pressed.connect(_on_node_clicked.bind(node))
	return btn

func _node_tooltip(node: MapNode, is_reachable: bool) -> String:
	var head: String = "%s — %s" % [_node_icon(node), _node_label(node)]
	var body: String = _node_description(node)
	var state: String
	if node.completed:
		state = "✓ Bereits besucht"
	elif is_reachable:
		state = "● Erreichbar — klicken zum Reisen"
	else:
		state = "✗ Nicht erreichbar"
	return "%s\n\n%s\n\n%s" % [head, body, state]

func _node_description(node: MapNode) -> String:
	match node.type:
		MapNode.NodeType.START:
			return "Startpunkt deiner Reise."
		MapNode.NodeType.COMBAT:
			var enc_name: String = _encounter_display(node.encounter_path)
			var suffix: String = (" — %s" % enc_name) if enc_name != "" else ""
			return "Standard-Kampf%s. Sieg → Item-Belohnung + Auto-Heilung." % suffix
		MapNode.NodeType.ELITE:
			var enc_name: String = _encounter_display(node.encounter_path)
			var suffix: String = (" — %s" % enc_name) if enc_name != "" else ""
			return "Elite-Kampf%s. Härter, gibt mehr Gold und heilt nach Sieg auf volle HP." % suffix
		MapNode.NodeType.BOSS:
			var enc_name: String = _encounter_display(node.encounter_path)
			var suffix: String = (" — %s" % enc_name) if enc_name != "" else ""
			return "Endboss%s. Sieg beendet den Run mit Belohnungen + Resonanzkristallen." % suffix
		MapNode.NodeType.SHOP:
			return "Werkstatt: Items kaufen, verkaufen oder rerollen. Reroll-Kosten sinken mit dem Marktkenner-Upgrade."
		MapNode.NodeType.HEAL:
			return "Reparaturstation: Turm auf volle HP heilen — kein Kampf."
		MapNode.NodeType.EVENT:
			return "Zufallsbegegnung: Wähle eine von mehreren Optionen mit unterschiedlichen Risiken/Belohnungen."
		_:
			return ""

func _encounter_display(encounter_path: String) -> String:
	if encounter_path == "" or not ResourceLoader.exists(encounter_path):
		return ""
	var enc: EncounterConfig = load(encounter_path)
	if enc == null:
		return ""
	return enc.display_name

func _node_icon(node: MapNode) -> String:
	match node.type:
		MapNode.NodeType.START: return "▶"
		MapNode.NodeType.BOSS: return "🏆"
		MapNode.NodeType.ELITE: return "☠"
		MapNode.NodeType.SHOP: return "⚙"
		MapNode.NodeType.EVENT: return "❓"
		MapNode.NodeType.HEAL: return "❤"
		MapNode.NodeType.COMBAT: return "⚔"
		_: return "·"

func _node_label(node: MapNode) -> String:
	match node.type:
		MapNode.NodeType.START: return "Start"
		MapNode.NodeType.BOSS: return "BOSS"
		MapNode.NodeType.ELITE: return "Elite"
		MapNode.NodeType.SHOP: return "Werkstatt"
		MapNode.NodeType.EVENT: return "Event"
		MapNode.NodeType.HEAL: return "Heilung"
		MapNode.NodeType.COMBAT: return "Kampf"
		_: return "?"

func _type_accent(t: int) -> Color:
	match t:
		MapNode.NodeType.HEAL: return Color(0.45, 0.85, 0.50)
		MapNode.NodeType.SHOP: return Color(0.95, 0.75, 0.35)
		MapNode.NodeType.EVENT: return Color(0.55, 0.65, 0.95)
		MapNode.NodeType.ELITE: return Color(0.85, 0.45, 0.85)
		MapNode.NodeType.BOSS: return Color(0.95, 0.45, 0.40)
		MapNode.NodeType.START: return Color(0.60, 0.60, 0.55)
		_: return Color(0.95, 0.78, 0.35)

func _draw_map() -> void:
	_draw_background_cogs()
	_draw_pipes()
	_draw_pulse_rings()

func _draw_background_cogs() -> void:
	# Große, transparente Zahnräder im Hintergrund der Canvas — Atmosphäre.
	var canvas_size: Vector2 = _canvas.size
	var cog_positions: Array[Vector2] = [
		Vector2(canvas_size.x * 0.12, canvas_size.y * 0.18),
		Vector2(canvas_size.x * 0.88, canvas_size.y * 0.30),
		Vector2(canvas_size.x * 0.18, canvas_size.y * 0.82),
		Vector2(canvas_size.x * 0.82, canvas_size.y * 0.78),
	]
	var radii: Array[float] = [70.0, 95.0, 80.0, 60.0]
	var rot_speeds: Array[float] = [0.18, -0.12, -0.22, 0.16]
	for i in range(cog_positions.size()):
		_draw_cogwheel(cog_positions[i], radii[i], _pulse_time * rot_speeds[i], Color(0.30, 0.22, 0.14, 0.18))

func _draw_cogwheel(center: Vector2, radius: float, rotation: float, color: Color) -> void:
	var teeth: int = 14
	var tooth_depth: float = radius * 0.18
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(teeth * 4):
		var t: float = float(i) / float(teeth * 4)
		var ang: float = t * TAU + rotation
		# 0..0.25 outer, 0.25..0.5 down ramp, 0.5..0.75 inner, 0.75..1 up ramp
		var sub: float = fmod(t * float(teeth), 1.0)
		var r: float = radius
		if sub < 0.30:
			r = radius
		elif sub < 0.50:
			r = radius - tooth_depth
		elif sub < 0.80:
			r = radius - tooth_depth
		else:
			r = radius
		pts.append(center + Vector2(cos(ang), sin(ang)) * r)
	# Geschlossener Ring
	pts.append(pts[0])
	_canvas.draw_polyline(pts, color, 2.5, true)
	# Innen-Kreis
	_canvas.draw_arc(center, radius * 0.45, 0.0, TAU, 48, color, 2.0, true)
	# Speichen (4 Stück)
	for s in range(4):
		var ang: float = float(s) * TAU * 0.25 + rotation
		var p1: Vector2 = center + Vector2(cos(ang), sin(ang)) * (radius * 0.45)
		var p2: Vector2 = center + Vector2(cos(ang), sin(ang)) * (radius - tooth_depth - 4.0)
		_canvas.draw_line(p1, p2, color, 2.0, true)

func _draw_pipes() -> void:
	var map: RunMap = RunState.current_map
	if map == null:
		return
	var reachable_ids: Array[int] = []
	for r in map.reachable_nodes_from_current():
		reachable_ids.append(r.id)
	# Zwei Pässe: erst alle Outer (dunkel), dann alle Inner — sonst überzeichnen Pipes einander.
	for node in map.nodes:
		var from_pos: Vector2 = _node_positions.get(node.id, Vector2.ZERO)
		for conn_id in node.connections:
			var to_pos: Vector2 = _node_positions.get(conn_id, Vector2.ZERO)
			var highlight: bool = _is_pipe_highlighted(node, conn_id, reachable_ids)
			var outer_width: float = (PIPE_WIDTH_HIGHLIGHT if highlight else PIPE_WIDTH_NORMAL) + 4.0
			_canvas.draw_line(from_pos, to_pos, PIPE_OUTER_COLOR, outer_width, true)
	for node in map.nodes:
		var from_pos: Vector2 = _node_positions.get(node.id, Vector2.ZERO)
		for conn_id in node.connections:
			var to_pos: Vector2 = _node_positions.get(conn_id, Vector2.ZERO)
			var highlight: bool = _is_pipe_highlighted(node, conn_id, reachable_ids)
			var inner_width: float = PIPE_WIDTH_HIGHLIGHT if highlight else PIPE_WIDTH_NORMAL
			var inner_color: Color = PIPE_INNER_HIGHLIGHT if highlight else PIPE_INNER_COLOR
			# Subtle pulse on highlighted pipes
			if highlight:
				var pulse: float = (sin(_pulse_time * 4.0) + 1.0) * 0.5
				inner_color = inner_color.lerp(Color(1, 1, 0.75), pulse * 0.35)
			_canvas.draw_line(from_pos, to_pos, inner_color, inner_width, true)
			# Nieten/Rivets an den Endpunkten
			var rivet_radius: float = 2.5 if not highlight else 3.0
			_canvas.draw_circle(from_pos, rivet_radius, PIPE_RIVET_COLOR)
			_canvas.draw_circle(to_pos, rivet_radius, PIPE_RIVET_COLOR)

func _is_pipe_highlighted(node: MapNode, conn_id: int, reachable_ids: Array[int]) -> bool:
	var map: RunMap = RunState.current_map
	if map == null:
		return false
	var is_current_source: bool = (node.id == map.current_node_id) or (node.type == MapNode.NodeType.START and map.current_node_id == -1)
	return is_current_source and conn_id in reachable_ids

func _draw_pulse_rings() -> void:
	var map: RunMap = RunState.current_map
	if map == null:
		return
	var reachable: Array[MapNode] = map.reachable_nodes_from_current()
	var pulse: float = (sin(_pulse_time * 3.5) + 1.0) * 0.5  # 0..1
	var ring_r: float = _effective_node_radius + 14.0 + pulse * 8.0
	var ring_alpha: float = 0.55 - pulse * 0.35
	for n in reachable:
		var pos: Vector2 = _node_positions.get(n.id, Vector2.ZERO)
		var c: Color = _type_accent(n.type)
		c.a = ring_alpha
		_canvas.draw_arc(pos, ring_r, 0.0, TAU, 48, c, 3.0, true)
	# "Du bist hier"-Markierung auf dem aktuellen Knoten (oder Start, wenn noch nichts besucht)
	var marker_id: int = map.current_node_id
	if marker_id == -1:
		for n in map.nodes:
			if n.type == MapNode.NodeType.START:
				marker_id = n.id
				break
	if marker_id != -1 and _node_positions.has(marker_id):
		var current_pos: Vector2 = _node_positions.get(marker_id, Vector2.ZERO)
		var marker_y: float = current_pos.y - _effective_node_radius - 22.0
		var triangle: PackedVector2Array = PackedVector2Array([
			Vector2(current_pos.x - 8.0, marker_y - 8.0),
			Vector2(current_pos.x + 8.0, marker_y - 8.0),
			Vector2(current_pos.x, marker_y + 4.0),
		])
		var marker_col: Color = Color(0.98, 0.82, 0.42, 0.85 + pulse * 0.15)
		_canvas.draw_colored_polygon(triangle, marker_col)

func _on_node_clicked(node: MapNode) -> void:
	AudioManager.sting("node_pick", -4.0)
	if RunState.is_coop:
		CoopManager.propose_transition("map:%d" % node.id)
	else:
		_execute_map_move(node.id)

func _execute_map_move(node_id: int) -> void:
	var node: MapNode = RunState.current_map.get_node_by_id(node_id)
	if node == null:
		return
	RunState.current_map.move_to(node_id)
	match node.type:
		MapNode.NodeType.COMBAT, MapNode.NodeType.ELITE, MapNode.NodeType.BOSS:
			RunState.pending_encounter_path = node.encounter_path
			get_tree().change_scene_to_file("res://scenes/TowerBuilder.tscn")
		MapNode.NodeType.HEAL:
			get_tree().change_scene_to_file("res://scenes/HealNodeView.tscn")
		MapNode.NodeType.SHOP:
			get_tree().change_scene_to_file("res://scenes/ShopView.tscn")
		MapNode.NodeType.EVENT:
			get_tree().change_scene_to_file("res://scenes/EventView.tscn")
		_:
			pass

func _on_transition_proposed(key: String, _proposer_id: int) -> void:
	if not key.begins_with("map:"):
		return
	_build_node_buttons()

func _on_transition_committed(key: String) -> void:
	if not key.begins_with("map:"):
		return
	var node_id: int = int(key.substr(4))
	_execute_map_move(node_id)

func _on_transition_cleared(key: String) -> void:
	if not key.begins_with("map:"):
		return
	_build_node_buttons()

func _on_menu() -> void:
	AudioManager.ui("back")
	RunState.end_run(false)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
