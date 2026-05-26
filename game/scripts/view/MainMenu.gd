extends Control

@onready var _continue_button: Button = $Center/VBox/ContinueButton
@onready var _new_run_button: Button = $Center/VBox/NewRunButton
@onready var _coop_button: Button = $Center/VBox/CoopButton
@onready var _daily_button: Button = $Center/VBox/DailyButton
@onready var _sandbox_button: Button = $Center/VBox/SandboxButton
@onready var _workshop_button: Button = $Center/VBox/WorkshopButton
@onready var _codex_button: Button = $Center/VBox/CodexButton
@onready var _stats_button: Button = $Center/VBox/StatsButton
@onready var _settings_button: Button = $Center/VBox/SettingsButton
@onready var _quit_button: Button = $Center/VBox/QuitButton
@onready var _version_label: Label = $VersionLabel

func _ready() -> void:
	# Optional: Hero-Background-PNG einblenden wenn vorhanden
	_install_hero_background()
	_continue_button.visible = RunState.has_saved_run()
	_continue_button.pressed.connect(_on_continue)
	_new_run_button.pressed.connect(_on_new_run)
	_coop_button.pressed.connect(_on_coop)
	_daily_button.pressed.connect(_on_daily)
	_sandbox_button.visible = MetaState.bosses_defeated >= 3
	_sandbox_button.pressed.connect(_on_sandbox)
	_workshop_button.pressed.connect(_on_workshop)
	_codex_button.pressed.connect(_on_codex)
	_stats_button.pressed.connect(_on_stats)
	_settings_button.pressed.connect(_on_settings)
	_quit_button.pressed.connect(_on_quit)
	AudioManager.play_music("res://assets/audio/music/menu_factory.ogg", -14.0)
	AudioManager.play_ambient("menu")
	_version_label.text = "v%s" % AppVersion.VERSION
	if UpdateChecker != null:
		UpdateChecker.update_available.connect(_on_update_available)

func _on_update_available(remote_version: String, _download_url: String, _notes: String) -> void:
	_version_label.text = "v%s  ·  Update verfügbar: v%s" % [AppVersion.VERSION, remote_version]
	_version_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))

func _install_hero_background() -> void:
	# Lädt assets/backgrounds/bg_main_menu.png wenn vorhanden und legt es als
	# Layer zwischen Background-ColorRect und BackgroundPattern (Atmosphere bleibt darüber).
	var bg_path: String = "res://assets/backgrounds/bg_main_menu.png"
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
	bg.modulate = Color(1, 1, 1, 0.85)   # leicht dimmen damit Title und Buttons gut lesbar bleiben
	add_child(bg)
	# Zwischen Background-ColorRect (0) und BackgroundPattern (1) einsortieren
	move_child(bg, 1)

func _on_stats() -> void:
	AudioManager.ui("click")
	get_tree().change_scene_to_file("res://scenes/MetaStats.tscn")

func _on_continue() -> void:
	AudioManager.ui("click")
	if RunState.load_run():
		get_tree().change_scene_to_file("res://scenes/MapView.tscn")

func _on_new_run() -> void:
	AudioManager.ui("click")
	get_tree().change_scene_to_file("res://scenes/RunStart.tscn")

func _on_sandbox() -> void:
	AudioManager.ui("click")
	get_tree().change_scene_to_file("res://scenes/SandboxStart.tscn")

func _on_coop() -> void:
	AudioManager.ui("click")
	get_tree().change_scene_to_file("res://scenes/CoopLobby.tscn")

func _on_daily() -> void:
	AudioManager.ui("click")
	get_tree().change_scene_to_file("res://scenes/DailyView.tscn")

func _on_workshop() -> void:
	AudioManager.ui("click")
	get_tree().change_scene_to_file("res://scenes/MetaWorkshop.tscn")

func _on_codex() -> void:
	AudioManager.ui("click")
	get_tree().change_scene_to_file("res://scenes/CodexView.tscn")

func _on_settings() -> void:
	AudioManager.ui("click")
	get_tree().change_scene_to_file("res://scenes/SettingsView.tscn")

func _on_quit() -> void:
	AudioManager.ui("back")
	get_tree().quit()
