extends Node

# Update-Check via GitHub raw manifest.
# - Beim Spielstart: automatisch 1× anfragen
# - On-Demand: SettingsView ruft check_now() auf wenn User klickt
#
# Manifest-Format (JSON):
#   {
#     "version": "0.2.2",
#     "download_url": "https://github.com/<user>/cogwright/releases/download/v0.2.2/Cogwright-0.2.2.zip",
#     "notes": "Was ist neu."
#   }

signal update_available(remote_version: String, download_url: String, notes: String)
signal check_finished(state: int, message: String)   # state: 0=current, 1=newer, 2=error

enum CheckState { CURRENT, NEWER, ERROR }

const TIMEOUT_SECONDS: float = 8.0

var last_state: int = CheckState.CURRENT
var last_message: String = "Noch nicht geprueft"
var last_remote_version: String = ""
var last_download_url: String = ""
var last_notes: String = ""

var _http: HTTPRequest = null

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT_SECONDS
	add_child(_http)
	_http.request_completed.connect(_on_response)
	# Auto-Check beim Spielstart (im Hintergrund, fehlende URL macht nix)
	if AppVersion.UPDATE_MANIFEST_URL != "":
		check_now()

func check_now() -> void:
	if AppVersion.UPDATE_MANIFEST_URL == "":
		last_state = CheckState.ERROR
		last_message = "Keine Update-URL konfiguriert"
		check_finished.emit(last_state, last_message)
		return
	last_message = "Suche nach Updates ..."
	check_finished.emit(last_state, last_message)
	var err: int = _http.request(AppVersion.UPDATE_MANIFEST_URL)
	if err != OK:
		last_state = CheckState.ERROR
		last_message = "HTTPRequest-Fehler: %d" % err
		check_finished.emit(last_state, last_message)

func _on_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		last_state = CheckState.ERROR
		last_message = "HTTP %d (result=%d)" % [response_code, result]
		check_finished.emit(last_state, last_message)
		return
	var text: String = body.get_string_from_utf8()
	var json := JSON.new()
	if json.parse(text) != OK:
		last_state = CheckState.ERROR
		last_message = "Manifest-JSON ungueltig"
		check_finished.emit(last_state, last_message)
		return
	var data = json.data
	if not (data is Dictionary):
		last_state = CheckState.ERROR
		last_message = "Manifest ist kein Objekt"
		check_finished.emit(last_state, last_message)
		return
	var remote_version: String = String(data.get("version", ""))
	if remote_version == "":
		last_state = CheckState.ERROR
		last_message = "Manifest ohne 'version' Feld"
		check_finished.emit(last_state, last_message)
		return
	last_remote_version = remote_version
	last_download_url = String(data.get("download_url", ""))
	last_notes = String(data.get("notes", ""))
	if AppVersion.is_newer(remote_version):
		last_state = CheckState.NEWER
		last_message = "Update verfuegbar: v%s" % remote_version
		update_available.emit(remote_version, last_download_url, last_notes)
	else:
		last_state = CheckState.CURRENT
		last_message = "Du nutzt die neueste Version (v%s)" % AppVersion.VERSION
	check_finished.emit(last_state, last_message)
