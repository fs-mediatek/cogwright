extends Node

# Co-Op-Verbindungsmanager als Autoload.
# Host-autoritativ: Host (peer 1) ist Wahrheits-Quelle für RunState.
# Phase 1a: Verbindung herstellen, Lobby-Status, Charakter-Auswahl synchronisieren.

signal connection_state_changed
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal lobby_player_updated(peer_id: int)
signal game_starting
signal run_initialized   # Beide Peers haben RunState aufgebaut, Szene kann wechseln

# Generische Coop-Sync-Signals
signal transition_proposed(key: String, proposer_id: int)
signal transition_cleared(key: String)
signal transition_committed(key: String)
signal action_applied(action: String, payload: Dictionary)

enum Role { NONE, HOST, CLIENT }

const DEFAULT_PORT: int = 31413
const MAX_CLIENTS: int = 1   # 2-Spieler-Coop → Host + 1 Client
const RunStartLib = preload("res://scripts/view/RunStart.gd")

var role: Role = Role.NONE
var is_active: bool = false
# Peer-ID → {character_id, ready, name}
var players: Dictionary = {}
var local_character_id: String = ""
var local_ready: bool = false

# Generische Transition-Vorschläge: key -> proposer_peer_id (1 wenn vom Host)
var pending_transitions: Dictionary = {}

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# --- Public API: Host/Join/Leave ---

func host_lobby(port: int = DEFAULT_PORT) -> String:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		return "Konnte Server nicht starten (Port belegt?): %s" % err
	multiplayer.multiplayer_peer = peer
	role = Role.HOST
	is_active = true
	players.clear()
	players[1] = _make_player_entry("Host")
	local_character_id = ""
	local_ready = false
	connection_state_changed.emit()
	return ""

func join_lobby(address: String, port: int = DEFAULT_PORT) -> String:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		return "Konnte nicht verbinden: %s" % err
	multiplayer.multiplayer_peer = peer
	role = Role.CLIENT
	is_active = true
	players.clear()
	local_character_id = ""
	local_ready = false
	connection_state_changed.emit()
	return ""

func leave() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	role = Role.NONE
	is_active = false
	players.clear()
	local_character_id = ""
	local_ready = false
	connection_state_changed.emit()

func is_host() -> bool:
	return role == Role.HOST

func is_client() -> bool:
	return role == Role.CLIENT

func local_peer_id() -> int:
	if multiplayer.multiplayer_peer == null:
		return 0
	return multiplayer.get_unique_id()

# --- Lobby-Aktionen ---

func set_local_character(character_id: String) -> void:
	local_character_id = character_id
	var pid: int = local_peer_id()
	if not players.has(pid):
		players[pid] = _make_player_entry(_default_name_for_peer(pid))
	players[pid]["character_id"] = character_id
	# An alle senden (inkl. Host selbst muss informiert sein)
	_broadcast_player_update.rpc(pid, character_id, local_ready)
	lobby_player_updated.emit(pid)

func set_local_ready(ready: bool) -> void:
	local_ready = ready
	var pid: int = local_peer_id()
	if not players.has(pid):
		players[pid] = _make_player_entry(_default_name_for_peer(pid))
	players[pid]["ready"] = ready
	_broadcast_player_update.rpc(pid, local_character_id, ready)
	lobby_player_updated.emit(pid)

func all_ready() -> bool:
	if players.size() < 2:
		return false
	for entry in players.values():
		if not entry.get("ready", false):
			return false
		if String(entry.get("character_id", "")) == "":
			return false
	return true

func host_start_game() -> void:
	if not is_host():
		return
	if not all_ready():
		return
	# Beide Charakter-Starter-Sets zusammenführen → gemeinsames Inventar.
	# Reihenfolge stabil: zuerst Host (Peer 1), dann anderer Peer.
	var combined_ids: Array[String] = []
	var character_map: Dictionary = {}
	var sorted_pids: Array = players.keys()
	sorted_pids.sort()  # 1 (Host) zuerst, dann höhere
	for pid in sorted_pids:
		var entry: Dictionary = players[pid]
		var char_id: String = String(entry.get("character_id", ""))
		character_map[pid] = char_id
		combined_ids.append_array(_items_for_character(char_id))
	var seed_val: int = randi()
	var heat_val: int = MetaState.selected_heat
	# Coop nutzt aktuell immer NORMAL-Länge — kann später als Lobby-Option folgen
	var length_val: int = MapGenerator.RunLength.NORMAL
	_remote_init_run.rpc(combined_ids, seed_val, heat_val, character_map, length_val)

# --- RPCs ---

@rpc("any_peer", "call_local", "reliable")
func _broadcast_player_update(peer_id: int, character_id: String, ready: bool) -> void:
	if not players.has(peer_id):
		players[peer_id] = _make_player_entry(_default_name_for_peer(peer_id))
	players[peer_id]["character_id"] = character_id
	players[peer_id]["ready"] = ready
	lobby_player_updated.emit(peer_id)

@rpc("authority", "call_local", "reliable")
func _remote_init_run(starter_ids: Array, seed_val: int, heat: int, character_map: Dictionary, length: int = 1) -> void:
	game_starting.emit()
	var items: Array[Item] = []
	for raw_id in starter_ids:
		var id: String = String(raw_id)
		var item: Item = load("res://data/items/%s.tres" % id)
		if item != null:
			items.append(item)
	# Heat-Wert synchronisieren (Client kennt selected_heat nicht zwingend gleich)
	if heat > 0 and heat > MetaState.max_heat_unlocked:
		# Falls Client noch keine Heat freigeschaltet hat: trotzdem akzeptieren für diesen Run.
		MetaState.max_heat_unlocked = heat
	MetaState.selected_heat = heat
	# Coop-Felder im RunState setzen
	RunState.is_coop = true
	RunState.coop_local_peer_id = local_peer_id()
	RunState.coop_characters.clear()
	for pid in character_map.keys():
		RunState.coop_characters[int(pid)] = String(character_map[pid])
	# Im Coop nimmt der lokale Peer seinen eigenen Charakter für Passive-Effekte
	var local_char: String = String(character_map.get(local_peer_id(), "fire"))
	RunState.start_new_run(items, seed_val, length, local_char)
	run_initialized.emit()

func _items_for_character(char_id: String) -> Array[String]:
	for set_def in RunStartLib.STARTER_SETS:
		if String(set_def["id"]) == char_id:
			var result: Array[String] = []
			for raw in set_def["item_ids"]:
				result.append(String(raw))
			return result
	return []

# --- Peer-Events ---

func _on_peer_connected(peer_id: int) -> void:
	if not players.has(peer_id):
		players[peer_id] = _make_player_entry(_default_name_for_peer(peer_id))
	# Host schickt dem neuen Peer den aktuellen Lobby-Stand
	if is_host():
		for existing_id in players.keys():
			var entry: Dictionary = players[existing_id]
			_broadcast_player_update.rpc_id(peer_id, existing_id, entry.get("character_id", ""), entry.get("ready", false))
	peer_joined.emit(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	players.erase(peer_id)
	peer_left.emit(peer_id)

func _on_connected_to_server() -> void:
	# Client kennt jetzt seine eigene ID
	var pid: int = local_peer_id()
	if not players.has(pid):
		players[pid] = _make_player_entry(_default_name_for_peer(pid))
	connection_state_changed.emit()

func _on_connection_failed() -> void:
	leave()

func _on_server_disconnected() -> void:
	leave()

# --- Helpers ---

func _make_player_entry(display_name: String) -> Dictionary:
	return {
		"name": display_name,
		"character_id": "",
		"ready": false,
	}

func _default_name_for_peer(pid: int) -> String:
	if pid == 1:
		return "Host"
	return "Spieler %d" % pid

func local_ip_hint() -> String:
	# Best-effort: erste IPv4 die nicht Loopback ist.
	for ip in IP.get_local_addresses():
		if ip.begins_with("127.") or ip.find(":") != -1:
			continue
		return ip
	return "127.0.0.1"

# --- Generic Coop-Sync API ---
# propose_transition: erstmaliger Klick markiert Vorschlag; zweiter Peer mit demselben
# key bestätigt → transition_committed wird auf allen Peers emittiert.
# Wenn derselbe Peer zweimal klickt: kein Effekt. Wenn ein anderer key kommt: alter
# Vorschlag verfällt (transition_cleared) und neuer Vorschlag wird aktiv.
func propose_transition(key: String) -> void:
	if not is_active:
		# Single-Player Fallback: direkt committen
		transition_committed.emit(key)
		return
	_remote_propose_transition.rpc(key, local_peer_id())

func cancel_transition(key: String) -> void:
	if not is_active:
		return
	_remote_cancel_transition.rpc(key)

@rpc("any_peer", "call_local", "reliable")
func _remote_propose_transition(key: String, proposer_id: int) -> void:
	var existing_proposer: int = int(pending_transitions.get(key, 0))
	if existing_proposer == 0:
		pending_transitions[key] = proposer_id
		transition_proposed.emit(key, proposer_id)
		return
	if existing_proposer == proposer_id:
		# Derselbe Peer klickt wieder — kein Commit
		return
	# Anderer Peer bestätigt
	pending_transitions.erase(key)
	transition_proposed.emit(key, 0)
	transition_committed.emit(key)

@rpc("any_peer", "call_local", "reliable")
func _remote_cancel_transition(key: String) -> void:
	if not pending_transitions.has(key):
		return
	pending_transitions.erase(key)
	transition_cleared.emit(key)

func clear_all_transitions() -> void:
	# Wird beim Szenenwechsel/Cleanup aufgerufen
	for key in pending_transitions.keys():
		transition_cleared.emit(key)
	pending_transitions.clear()

# sync_action: fire-and-forget Aktion, die auf allen Peers identisch ausgeführt wird.
# Beispiele: Item-Kauf im Shop, Slot-Placement, Reroll, Event-Choice.
# Empfangende Seite verarbeitet via action_applied-Signal.
func sync_action(action: String, payload: Dictionary = {}) -> void:
	if not is_active:
		# Single-Player Fallback: lokal anwenden
		action_applied.emit(action, payload)
		return
	_remote_sync_action.rpc(action, payload)

@rpc("any_peer", "call_local", "reliable")
func _remote_sync_action(action: String, payload: Dictionary) -> void:
	action_applied.emit(action, payload)
