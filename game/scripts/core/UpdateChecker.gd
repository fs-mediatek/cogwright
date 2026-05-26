extends Node

# Optional: prueft beim Spielstart eine Manifest-URL auf neuere Version.
# Manifest-Format (JSON):
#   {
#     "version": "0.2.1",
#     "download_url": "https://.../Cogwright-0.2.1.zip",
#     "notes": "Was ist neu in dieser Version."
#   }
#
# Falls AppVersion.UPDATE_MANIFEST_URL leer ist, passiert nichts.
# Falls eine neuere Version verfuegbar ist, wird `update_available` emittiert.

signal update_available(remote_version: String, download_url: String, notes: String)
signal check_failed(reason: String)

var _http: HTTPRequest = null

func _ready() -> void:
	if AppVersion.UPDATE_MANIFEST_URL == "":
		return
	_http = HTTPRequest.new()
	_http.timeout = 8.0
	add_child(_http)
	_http.request_completed.connect(_on_response)
	var err: int = _http.request(AppVersion.UPDATE_MANIFEST_URL)
	if err != OK:
		check_failed.emit("HTTPRequest fehlgeschlagen: %d" % err)

func _on_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		check_failed.emit("HTTP %d (result=%d)" % [response_code, result])
		return
	var text: String = body.get_string_from_utf8()
	var json := JSON.new()
	if json.parse(text) != OK:
		check_failed.emit("Manifest-JSON ungueltig")
		return
	var data = json.data
	if not (data is Dictionary):
		check_failed.emit("Manifest ist kein Objekt")
		return
	var remote_version: String = String(data.get("version", ""))
	if remote_version == "":
		check_failed.emit("Manifest ohne 'version' Feld")
		return
	if AppVersion.is_newer(remote_version):  # type: ignore
		update_available.emit(
			remote_version,
			String(data.get("download_url", "")),
			String(data.get("notes", "")),
		)
