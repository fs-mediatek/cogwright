extends Control

# Daily Challenge: starter Run mit festem Datums-Seed + Pyrotechniker-Starter.
# Highscore wird in MetaState gespeichert.

const STARTER_PYRO: Array[String] = ["spark_spitter", "spark_spitter", "combustion_chamber"]

@onready var _date_label: Label = $Center/VBox/DateLabel
@onready var _seed_label: Label = $Center/VBox/SeedLabel
@onready var _best_label: Label = $Center/VBox/BestLabel
@onready var _today_label: Label = $Center/VBox/TodayLabel
@onready var _start_btn: Button = $Center/VBox/StartButton
@onready var _back_btn: Button = $Center/VBox/BackButton
@onready var _leaderboard_container: VBoxContainer = $Center/VBox/LeaderboardContainer

func _ready() -> void:
	_start_btn.pressed.connect(_on_start)
	_back_btn.pressed.connect(_on_back)
	_refresh()
	AudioManager.play_music("res://assets/audio/music/menu_factory.ogg", -14.0)
	AudioManager.play_ambient("menu")

func _refresh() -> void:
	_date_label.text = "Daily Challenge — %s" % MetaState.current_daily_key()
	_seed_label.text = "Seed: %d   (jeden Spieler weltweit erhält heute dieselbe Map)" % MetaState.current_daily_seed()
	var today_score: int = MetaState.get_daily_score(MetaState.current_daily_key())
	if today_score < 0:
		_today_label.text = "Heute noch nicht gespielt."
	elif today_score >= 100:
		_today_label.text = "Heute: ✦ Boss besiegt mit %d Encounter-Siegen." % (today_score - 100)
	else:
		_today_label.text = "Heute beste Versuch: %d Encounter-Siege (kein Boss-Sieg)." % today_score
	_best_label.text = "Insgesamt gespielte Daily-Tage: %d" % MetaState.daily_records.size()
	_build_leaderboard()

func _build_leaderboard() -> void:
	for c in _leaderboard_container.get_children():
		c.queue_free()
	# Top-10 nach Score sortieren
	var entries: Array = []
	for k in MetaState.daily_records.keys():
		entries.append({"date": String(k), "score": int(MetaState.daily_records[k])})
	entries.sort_custom(func(a, b): return a["score"] > b["score"])
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "— noch keine Daily-Runs gespielt —"
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", Color(0.60, 0.55, 0.42))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_leaderboard_container.add_child(empty)
		return
	for i in range(min(10, entries.size())):
		var entry: Dictionary = entries[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var rank := Label.new()
		rank.text = "%d." % (i + 1)
		rank.custom_minimum_size = Vector2(28, 0)
		rank.add_theme_font_size_override("font_size", 12)
		rank.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
		row.add_child(rank)
		var date_lbl := Label.new()
		date_lbl.text = entry["date"]
		date_lbl.add_theme_font_size_override("font_size", 12)
		date_lbl.add_theme_color_override("font_color", Color(0.75, 0.68, 0.55))
		date_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(date_lbl)
		var score_lbl := Label.new()
		var s: int = entry["score"]
		if s >= 100:
			score_lbl.text = "✦ Boss + %d Encounter" % (s - 100)
			score_lbl.add_theme_color_override("font_color", Color(0.55, 0.95, 0.55))
		else:
			score_lbl.text = "%d Encounter" % s
			score_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
		score_lbl.add_theme_font_size_override("font_size", 12)
		row.add_child(score_lbl)
		_leaderboard_container.add_child(row)

func _on_start() -> void:
	AudioManager.ui("click")
	var items: Array[Item] = []
	for id in STARTER_PYRO:
		items.append(load("res://data/items/%s.tres" % id))
	MetaState.is_daily_run = true
	RunState.start_new_run(items, MetaState.current_daily_seed())
	get_tree().change_scene_to_file("res://scenes/MapView.tscn")

func _on_back() -> void:
	AudioManager.ui("back")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
