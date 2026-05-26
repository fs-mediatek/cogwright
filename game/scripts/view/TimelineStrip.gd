class_name TimelineStrip extends Control

const LOOKAHEAD_SECONDS: float = 5.0
const ICON_SIZE: float = 28.0
const REFRESH_INTERVAL: float = 0.1  # alle 100ms neu berechnen, nicht jeden Frame

@export var player_color: Color = Color(0.40, 0.78, 0.85)
@export var rival_color: Color = Color(0.88, 0.42, 0.40)
@export var lane_bg: Color = Color(0.18, 0.15, 0.12, 0.9)
@export var separator_color: Color = Color(0.30, 0.27, 0.23, 1.0)

var _battle: BattleController
var _refresh_timer: float = 0.0
var _upcoming: Array[Dictionary] = []

@onready var _container: Control = $Container

func _ready() -> void:
	custom_minimum_size = Vector2(0, 56)

func bind(battle: BattleController) -> void:
	_battle = battle
	if is_node_ready():
		_rebuild_now()

func _process(delta: float) -> void:
	if _battle == null:
		return
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = REFRESH_INTERVAL
		_rebuild_now()

func _rebuild_now() -> void:
	_upcoming = _battle.predict_upcoming_triggers(LOOKAHEAD_SECONDS)
	queue_redraw()
	for child in _container.get_children():
		child.queue_free()
	if size.x < 50.0:
		return
	for entry in _upcoming:
		var t: float = entry["time"]
		var tower: Tower = entry["tower"]
		var slot: ItemSlot = entry["slot"]
		var x: float = (t / LOOKAHEAD_SECONDS) * size.x
		var icon_node := TextureRect.new()
		icon_node.texture = slot.item.icon
		icon_node.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_node.position = Vector2(x - ICON_SIZE * 0.5, 14)
		icon_node.size = Vector2(ICON_SIZE, ICON_SIZE)
		var is_player: bool = (tower == _battle.attacker)
		icon_node.modulate = player_color if is_player else rival_color
		# Spätere Trigger fader
		var fade: float = 1.0 - smoothstep(0.6, 1.0, t / LOOKAHEAD_SECONDS) * 0.4
		icon_node.modulate.a = fade
		_container.add_child(icon_node)

func _draw() -> void:
	# Hintergrund-Strip
	draw_rect(Rect2(Vector2.ZERO, size), lane_bg)
	# Vertikale Sekunden-Marker
	for i in range(1, int(LOOKAHEAD_SECONDS)):
		var x: float = (float(i) / LOOKAHEAD_SECONDS) * size.x
		draw_line(Vector2(x, 4), Vector2(x, size.y - 4), separator_color, 1.0)
	# „Jetzt"-Linie ganz links
	draw_line(Vector2(2, 0), Vector2(2, size.y), Color(0.95, 0.85, 0.6, 0.9), 2.0)

func _on_resized() -> void:
	_rebuild_now()
