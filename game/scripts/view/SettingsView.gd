extends Control

@onready var _master_slider: HSlider = $Center/VBox/MasterRow/Slider
@onready var _master_value: Label = $Center/VBox/MasterRow/ValueLabel
@onready var _music_slider: HSlider = $Center/VBox/MusicRow/Slider
@onready var _music_value: Label = $Center/VBox/MusicRow/ValueLabel
@onready var _sfx_slider: HSlider = $Center/VBox/SfxRow/Slider
@onready var _sfx_value: Label = $Center/VBox/SfxRow/ValueLabel
@onready var _fullscreen_check: CheckButton = $Center/VBox/FullscreenRow/Check
@onready var _language_option: OptionButton = $Center/VBox/LanguageRow/OptionButton
@onready var _item_sounds_check: CheckButton = $Center/VBox/ItemSoundsRow/Check
@onready var _screen_shake_check: CheckButton = $Center/VBox/ScreenShakeRow/Check
@onready var _telemetry_enabled_check: CheckButton = $Center/VBox/TelemetryEnabledRow/Check
@onready var _update_status_label: Label = $Center/VBox/UpdateRow/StatusLabel
@onready var _update_check_btn: Button = $Center/VBox/UpdateRow/CheckButton
@onready var _update_download_btn: Button = $Center/VBox/UpdateRow/DownloadButton
@onready var _back_btn: Button = $Center/VBox/BackButton

func _ready() -> void:
	_install_hero_background()
	_master_slider.value = SettingsState.master_volume * 100.0
	_music_slider.value = SettingsState.music_volume * 100.0
	_sfx_slider.value = SettingsState.sfx_volume * 100.0
	_fullscreen_check.button_pressed = SettingsState.fullscreen
	_item_sounds_check.button_pressed = SettingsState.item_sounds_enabled
	_screen_shake_check.button_pressed = SettingsState.screen_shake_enabled
	_update_value_labels()
	_master_slider.value_changed.connect(_on_master)
	_music_slider.value_changed.connect(_on_music)
	_sfx_slider.value_changed.connect(_on_sfx)
	_fullscreen_check.toggled.connect(_on_fullscreen)
	_item_sounds_check.toggled.connect(_on_item_sounds)
	_screen_shake_check.toggled.connect(_on_screen_shake)
	_language_option.selected = 0 if SettingsState.locale == "de" else 1
	_language_option.item_selected.connect(_on_language)
	_telemetry_enabled_check.button_pressed = SettingsState.telemetry_enabled
	_telemetry_enabled_check.toggled.connect(_on_telemetry_enabled)
	_update_check_btn.pressed.connect(_on_update_check)
	_update_download_btn.pressed.connect(_on_update_download)
	_back_btn.pressed.connect(_on_back)
	_refresh_update_label()
	UpdateChecker.check_finished.connect(func(_s, _m): _refresh_update_label())

func _on_telemetry_enabled(pressed: bool) -> void:
	SettingsState.set_telemetry_enabled(pressed)
	AudioManager.ui("click")

func _on_update_check() -> void:
	AudioManager.ui("click")
	UpdateChecker.check_now()

func _on_update_download() -> void:
	AudioManager.ui("click")
	if UpdateChecker.last_download_url != "":
		OS.shell_open(UpdateChecker.last_download_url)

func _refresh_update_label() -> void:
	_update_status_label.text = "v%s  ·  %s" % [AppVersion.VERSION, UpdateChecker.last_message]
	var has_update: bool = UpdateChecker.last_state == UpdateChecker.CheckState.NEWER and UpdateChecker.last_download_url != ""
	_update_download_btn.visible = has_update
	if has_update:
		_update_status_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.35))
	else:
		_update_status_label.remove_theme_color_override("font_color")

func _on_item_sounds(pressed: bool) -> void:
	SettingsState.item_sounds_enabled = pressed
	SettingsState.save_settings()
	AudioManager.ui("click")

func _on_screen_shake(pressed: bool) -> void:
	SettingsState.screen_shake_enabled = pressed
	SettingsState.save_settings()
	AudioManager.ui("click")

func _on_master(value: float) -> void:
	SettingsState.set_master(value / 100.0)
	_update_value_labels()

func _on_music(value: float) -> void:
	SettingsState.set_music(value / 100.0)
	_update_value_labels()

func _on_sfx(value: float) -> void:
	SettingsState.set_sfx(value / 100.0)
	_update_value_labels()
	AudioManager.ui("click")

func _on_fullscreen(pressed: bool) -> void:
	SettingsState.set_fullscreen(pressed)
	AudioManager.ui("click")

func _update_value_labels() -> void:
	_master_value.text = "%d%%" % int(round(SettingsState.master_volume * 100))
	_music_value.text = "%d%%" % int(round(SettingsState.music_volume * 100))
	_sfx_value.text = "%d%%" % int(round(SettingsState.sfx_volume * 100))

func _on_language(idx: int) -> void:
	AudioManager.ui("click")
	SettingsState.set_locale("de" if idx == 0 else "en")

func _install_hero_background() -> void:
	var bg_path: String = "res://assets/backgrounds/bg_settings.png"
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

func _on_back() -> void:
	AudioManager.ui("back")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
