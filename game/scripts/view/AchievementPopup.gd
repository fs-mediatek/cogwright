extends CanvasLayer

# Globaler Achievement-Popup-Overlay. Wird als Autoload-Scene instanziiert oder
# in CommonOverlay eingehängt. Lauscht auf MetaState-Unlocks und zeigt eine
# slide-in Toast-Karte oben rechts.

const SLIDE_DURATION: float = 0.35
const HOLD_DURATION: float = 3.2
const SLIDE_OUT_DURATION: float = 0.45

var _queue: Array[Dictionary] = []
var _showing: bool = false

func _ready() -> void:
	layer = 100
	# Auf MetaState-Signal wartet HintState.gd nicht — also direkt achievement-events abfangen.
	# MetaState.unlock_achievement gibt true zurück wenn neu — wir hooken über das
	# meta_changed signal nicht, da das auch bei anderen events feuert.
	# Stattdessen: ein dedizierter signal + emit in MetaState.unlock_achievement.
	if MetaState.has_signal("achievement_unlocked"):
		MetaState.achievement_unlocked.connect(_on_unlock)

func _on_unlock(achievement_id: String) -> void:
	var info: Dictionary = MetaState.ALL_ACHIEVEMENTS.get(achievement_id, {})
	if info.is_empty():
		return
	_queue.append({"id": achievement_id, "name": info.get("name", achievement_id), "desc": info.get("desc", "")})
	if not _showing:
		_process_queue()

func _process_queue() -> void:
	if _queue.is_empty():
		_showing = false
		return
	_showing = true
	var entry: Dictionary = _queue.pop_front()
	_show_toast(entry)

func _show_toast(entry: Dictionary) -> void:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.15, 0.09, 0.95)
	sb.border_color = Color(0.95, 0.78, 0.35, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(14)
	sb.shadow_color = Color(0.95, 0.78, 0.35, 0.5)
	sb.shadow_size = 12
	panel.add_theme_stylebox_override("panel", sb)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	var header := Label.new()
	header.text = "🏆 Achievement freigeschaltet"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
	vbox.add_child(header)
	var name_lbl := Label.new()
	name_lbl.text = String(entry.get("name", ""))
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	vbox.add_child(name_lbl)
	var desc_lbl := Label.new()
	desc_lbl.text = String(entry.get("desc", ""))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.78, 0.60))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.custom_minimum_size = Vector2(340, 0)
	vbox.add_child(desc_lbl)
	add_child(panel)
	# Positionierung: oben rechts mit Margin, dann slide-in von rechts
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	await get_tree().process_frame   # warten bis size verfügbar
	var panel_size: Vector2 = panel.size
	var target_x: float = viewport_size.x - panel_size.x - 32.0
	var target_y: float = 32.0
	panel.position = Vector2(viewport_size.x + 20.0, target_y)
	# AudioCue
	AudioManager.sfx("victory" if MetaState.has_method("get_dummy") else "buff", -6.0)
	# Slide-in
	var t_in := create_tween()
	t_in.set_trans(Tween.TRANS_BACK)
	t_in.set_ease(Tween.EASE_OUT)
	t_in.tween_property(panel, "position:x", target_x, SLIDE_DURATION)
	await t_in.finished
	await get_tree().create_timer(HOLD_DURATION).timeout
	# Slide-out
	var t_out := create_tween()
	t_out.set_trans(Tween.TRANS_QUAD)
	t_out.set_ease(Tween.EASE_IN)
	t_out.tween_property(panel, "position:x", viewport_size.x + 20.0, SLIDE_OUT_DURATION)
	await t_out.finished
	panel.queue_free()
	_process_queue()
