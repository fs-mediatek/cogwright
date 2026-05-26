extends Control

const HEAL_PERCENT: float = 0.45

@onready var _title: Label = $Center/VBox/TitleLabel
@onready var _heal_value: Label = $Center/VBox/HealValueLabel
@onready var _hp_before: Label = $Center/VBox/HpBeforeLabel
@onready var _hp_after: Label = $Center/VBox/HpAfterLabel
@onready var _continue_btn: Button = $Center/VBox/ContinueButton

func _ready() -> void:
	if not RunState.is_run_active:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	_install_hero_background()
	_continue_btn.pressed.connect(_on_continue)
	AudioManager.play_music("res://assets/audio/music/menu_factory.ogg", -14.0)
	AudioManager.play_ambient("heal")
	_perform_heal()
	if RunState.is_coop:
		CoopManager.transition_committed.connect(_on_coop_transition)

func _install_hero_background() -> void:
	var bg_path: String = "res://assets/backgrounds/bg_heal.png"
	if not ResourceLoader.exists(bg_path):
		return
	var res: Resource = load(bg_path)
	if not (res is Texture2D):
		return
	var bg := TextureRect.new()
	bg.texture = res
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.modulate = Color(1, 1, 1, 0.75)
	add_child(bg)
	move_child(bg, 1)

func _perform_heal() -> void:
	var before: int = RunState.tower_hp
	var heal: int = int(round(float(RunState.tower_max_hp) * HEAL_PERCENT))
	# Charakter-Passive: Schmiedin (blunt) bekommt +15 HP an Heal-Knoten
	var passive: Dictionary = RunState.CHARACTER_PASSIVES.get(RunState.current_character_id, {})
	heal += int(passive.get("heal_bonus", 0))
	RunState.tower_hp = min(RunState.tower_max_hp, RunState.tower_hp + heal)
	var actual: int = RunState.tower_hp - before
	_hp_before.text = "Vorher:  %d / %d" % [before, RunState.tower_max_hp]
	_heal_value.text = "+%d HP" % actual
	_hp_after.text = "Jetzt:  %d / %d" % [RunState.tower_hp, RunState.tower_max_hp]
	AudioManager.sfx("heal", -2.0)
	# Knoten als abgeschlossen markieren, sonst hängt der Spieler hier fest
	if RunState.current_map != null:
		RunState.current_map.mark_current_completed()

func _on_continue() -> void:
	AudioManager.ui("click")
	if RunState.is_coop:
		CoopManager.propose_transition("heal:continue")
		_continue_btn.text = "Warte auf Mitspieler…"
		_continue_btn.disabled = true
	else:
		_do_continue()

func _do_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/MapView.tscn")

func _on_coop_transition(key: String) -> void:
	if key == "heal:continue":
		_do_continue()
