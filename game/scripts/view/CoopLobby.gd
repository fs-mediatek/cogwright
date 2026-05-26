extends Control

# Co-Op-Lobby: Host startet Server, Client gibt IP ein.
# Sobald beide Spieler einen Charakter gewählt und Ready geklickt haben,
# kann der Host den Run starten. Beide werden in dieselbe MapView geleitet.

const RunStartLib = preload("res://scripts/view/RunStart.gd")

@onready var _status_label: Label = $Layout/ConnectionPanel/ConnectionVBox/StatusLabel
@onready var _host_btn: Button = $Layout/ConnectionPanel/ConnectionVBox/ButtonRow/HostButton
@onready var _join_btn: Button = $Layout/ConnectionPanel/ConnectionVBox/ButtonRow/JoinButton
@onready var _join_ip_edit: LineEdit = $Layout/ConnectionPanel/ConnectionVBox/ButtonRow/JoinIpEdit
@onready var _leave_btn: Button = $Layout/ConnectionPanel/ConnectionVBox/ButtonRow/LeaveButton
@onready var _players_container: VBoxContainer = $Layout/LobbyPanel/LobbyVBox/PlayersContainer
@onready var _back_btn: Button = $Layout/Footer/BackButton
@onready var _ready_btn: Button = $Layout/Footer/ReadyButton
@onready var _start_btn: Button = $Layout/Footer/StartButton

func _ready() -> void:
	_host_btn.pressed.connect(_on_host)
	_join_btn.pressed.connect(_on_join)
	_leave_btn.pressed.connect(_on_leave)
	_back_btn.pressed.connect(_on_back)
	_ready_btn.pressed.connect(_on_toggle_ready)
	_start_btn.pressed.connect(_on_start)
	CoopManager.connection_state_changed.connect(_refresh)
	CoopManager.peer_joined.connect(_on_peer_event)
	CoopManager.peer_left.connect(_on_peer_event)
	CoopManager.lobby_player_updated.connect(_on_peer_event)
	CoopManager.game_starting.connect(_on_game_starting)
	CoopManager.run_initialized.connect(_on_run_initialized)
	# Sinnvoller IP-Hint für den Host vorschlagen — sichtbar im Status, nicht editierbar
	_refresh()
	AudioManager.play_music("res://assets/audio/music/menu_factory.ogg", -14.0)
	AudioManager.play_ambient("menu")

func _on_peer_event(_pid: int) -> void:
	_refresh()

func _refresh() -> void:
	var connected: bool = CoopManager.is_active
	_host_btn.disabled = connected
	_join_btn.disabled = connected
	_join_ip_edit.editable = not connected
	_leave_btn.disabled = not connected
	_ready_btn.disabled = not connected or String(CoopManager.local_character_id) == ""
	_start_btn.disabled = not CoopManager.is_host() or not CoopManager.all_ready()
	_start_btn.visible = CoopManager.is_host() or not connected
	# Status-Zeile
	if not connected:
		_status_label.text = "Nicht verbunden. Eigene LAN-IP: %s — diese teilst du mit dem Client." % CoopManager.local_ip_hint()
	elif CoopManager.is_host():
		var n: int = CoopManager.players.size()
		_status_label.text = "Host läuft. %d/2 Spieler verbunden. Deine LAN-IP: %s" % [n, CoopManager.local_ip_hint()]
	else:
		_status_label.text = "Mit Host verbunden."
	# Ready-Button-Text
	_ready_btn.text = "Bereit ✓" if CoopManager.local_ready else "Ich bin bereit"
	_build_player_list()

func _build_player_list() -> void:
	for child in _players_container.get_children():
		child.queue_free()
	if not CoopManager.is_active:
		var hint := Label.new()
		hint.text = "Hoste eine Lobby oder tritt einer bei."
		hint.add_theme_font_size_override("font_size", 13)
		hint.add_theme_color_override("font_color", Color(0.7, 0.6, 0.45))
		_players_container.add_child(hint)
		return
	# Slot 1: lokaler Spieler. Slot 2: anderer (oder Platzhalter "wartet").
	var local_pid: int = CoopManager.local_peer_id()
	_players_container.add_child(_make_player_card(local_pid, true))
	var partner_pid: int = -1
	for pid in CoopManager.players.keys():
		if pid != local_pid:
			partner_pid = pid
			break
	if partner_pid == -1:
		var wait := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.12, 0.10, 0.08, 1.0)
		sb.border_color = Color(0.30, 0.25, 0.18, 1.0)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		sb.set_content_margin_all(12)
		wait.add_theme_stylebox_override("panel", sb)
		var wlbl := Label.new()
		wlbl.text = "Warte auf zweiten Spieler…"
		wlbl.add_theme_font_size_override("font_size", 14)
		wlbl.add_theme_color_override("font_color", Color(0.7, 0.6, 0.42))
		wait.add_child(wlbl)
		_players_container.add_child(wait)
	else:
		_players_container.add_child(_make_player_card(partner_pid, false))

func _make_player_card(pid: int, is_local: bool) -> PanelContainer:
	var entry: Dictionary = CoopManager.players.get(pid, {})
	var character_id: String = String(entry.get("character_id", ""))
	var is_ready: bool = bool(entry.get("ready", false))
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.13, 0.10, 1.0)
	sb.border_color = Color(0.55, 0.45, 0.28, 1.0) if is_local else Color(0.40, 0.34, 0.22, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)
	var name_lbl := Label.new()
	var prefix: String = "Du" if is_local else "Mitspieler"
	var ready_marker: String = " ✓" if is_ready else ""
	name_lbl.text = "%s (Peer %d)%s" % [prefix, pid, ready_marker]
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.40) if is_local else Color(0.75, 0.68, 0.50))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_lbl)
	if character_id != "":
		var char_lbl := Label.new()
		char_lbl.text = "→ %s" % _character_display_name(character_id)
		char_lbl.add_theme_font_size_override("font_size", 13)
		char_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 0.55))
		header.add_child(char_lbl)
	# Charakter-Wahl-Knöpfe nur für lokalen Spieler
	if is_local:
		var char_row := HBoxContainer.new()
		char_row.add_theme_constant_override("separation", 6)
		vbox.add_child(char_row)
		for set_def in RunStartLib.STARTER_SETS:
			var cid: String = String(set_def["id"])
			if not MetaState.is_character_unlocked(cid):
				continue
			var btn := Button.new()
			btn.text = String(set_def["name"])
			btn.add_theme_font_size_override("font_size", 12)
			btn.custom_minimum_size = Vector2(120, 30)
			btn.toggle_mode = true
			btn.button_pressed = (character_id == cid)
			btn.disabled = is_ready  # Solange ready: kann nicht mehr ändern
			btn.pressed.connect(_on_character_picked.bind(cid))
			char_row.add_child(btn)
	return panel

func _character_display_name(char_id: String) -> String:
	for set_def in RunStartLib.STARTER_SETS:
		if String(set_def["id"]) == char_id:
			return String(set_def["name"])
	return char_id

# --- Actions ---

func _on_host() -> void:
	AudioManager.ui("select")
	var err: String = CoopManager.host_lobby()
	if err != "":
		_status_label.text = err
		return
	_refresh()

func _on_join() -> void:
	AudioManager.ui("select")
	var addr: String = _join_ip_edit.text.strip_edges()
	if addr == "":
		addr = "127.0.0.1"
	var err: String = CoopManager.join_lobby(addr)
	if err != "":
		_status_label.text = err
		return
	_refresh()

func _on_leave() -> void:
	AudioManager.ui("back")
	CoopManager.leave()
	_refresh()

func _on_character_picked(char_id: String) -> void:
	AudioManager.ui("click")
	CoopManager.set_local_character(char_id)
	_refresh()

func _on_toggle_ready() -> void:
	AudioManager.ui("click")
	CoopManager.set_local_ready(not CoopManager.local_ready)
	_refresh()

func _on_start() -> void:
	if not CoopManager.is_host():
		return
	if not CoopManager.all_ready():
		return
	AudioManager.ui("select")
	CoopManager.host_start_game()

func _on_back() -> void:
	AudioManager.ui("back")
	if CoopManager.is_active:
		CoopManager.leave()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_game_starting() -> void:
	_status_label.text = "Starte Run… synchronisiere Inventar und Map."
	_host_btn.disabled = true
	_join_btn.disabled = true
	_leave_btn.disabled = true
	_ready_btn.disabled = true
	_start_btn.disabled = true

func _on_run_initialized() -> void:
	# Beide Peers haben RunState gebaut → synchron in MapView wechseln.
	get_tree().change_scene_to_file("res://scenes/MapView.tscn")
