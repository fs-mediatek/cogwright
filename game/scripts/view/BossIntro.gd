extends Control

# 2-Sekunden-Intro vor dem Boss-Kampf.
# Zeigt Boss-Namen, HP und Flavor. Klick oder Space überspringt.

const AUTO_CONTINUE_SECONDS: float = 6.5

# Encounter-ID -> Asset-Slug fuer Boss-Portraits.
# Falls die encounter.id nicht zum PNG-Filename passt, hier mappen.
const PORTRAIT_OVERRIDES: Dictionary = {
	"warlord": "eisenbaron_gravelock",
}

@onready var _name_label: Label = $Center/VBox/NameLabel
@onready var _hp_label: Label = $Center/VBox/HpLabel
@onready var _desc_label: Label = $Center/VBox/DescLabel
@onready var _hint_label: Label = $Center/VBox/HintLabel
@onready var _portrait: TextureRect = $Center/VBox/BossPortrait

var _continued: bool = false

func _ready() -> void:
	if not RunState.is_run_active or RunState.pending_encounter_path == "":
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	var enc: EncounterConfig = load(RunState.pending_encounter_path)
	if enc != null:
		_name_label.text = enc.display_name
		_hp_label.text = "%d HP" % enc.base_hp
		_desc_label.text = enc.description
		# Boss-Portrait wenn vorhanden — Mapping ID -> Asset-Slug
		var asset_slug: String = PORTRAIT_OVERRIDES.get(String(enc.id), String(enc.id))
		var portrait_path: String = "res://assets/bosses/boss_%s.png" % asset_slug
		if ResourceLoader.exists(portrait_path):
			var tex: Resource = load(portrait_path)
			if tex is Texture2D:
				_portrait.texture = tex
				_portrait.visible = true
	AudioManager.play_music("res://assets/audio/music/menu_factory.ogg", -10.0)
	AudioManager.play_ambient("boss_intro", -18.0)
	AudioManager.sfx("buff", -2.0)
	# Auto-Continue nach AUTO_CONTINUE_SECONDS
	await get_tree().create_timer(AUTO_CONTINUE_SECONDS).timeout
	_continue()

func _input(event: InputEvent) -> void:
	if _continued:
		return
	if event is InputEventMouseButton and event.pressed:
		_continue()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_continue()

func _continue() -> void:
	if _continued:
		return
	_continued = true
	AudioManager.ui("click")
	get_tree().change_scene_to_file("res://scenes/BattleView.tscn")
