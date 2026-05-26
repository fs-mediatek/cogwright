extends Node

# Discord-Webhook-Telemetry: sendet Battle-Logs an einen Discord-Channel.
#
# Setup:
#   1. Discord-Server -> Channel -> Einstellungen -> Integrations -> Webhooks
#   2. Webhook-URL kopieren
#   3. In Settings unter "Telemetrie" eintragen + aktivieren
#
# Privacy:
#   Versand nur wenn SettingsState.telemetry_enabled = true.
#   Inhalt: Game-Version, Char, Perks, Tower-Layout, Encounter, Outcome, Log-Auszug.
#   Kein Maschinen-Identifier, keine Saves, kein OS-Info.

const MAX_FIELD_LEN: int = 1000   # Discord-Limit ist 1024, mit Sicherheitsmarge
const MAX_LOG_LINES: int = 25     # Letzte N Log-Zeilen mitsenden
const TIMEOUT_SECONDS: float = 6.0

# Built-in Tester-Webhook — wird genutzt wenn telemetry_webhook_url leer ist.
# Mit den Testern abgestimmt, daher fest im Build verankert.
const BUILT_IN_WEBHOOK_URL: String = "https://discord.com/api/webhooks/1508835274271232051/HVdpzGoMyy7RxQhFy1Z58H4wrDzXTyLRZyDYv_Me51YKJXoBzgL3WA_8Kp4wbnBBoerT"

var _http: HTTPRequest = null
var _pending: int = 0

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT_SECONDS
	add_child(_http)
	_http.request_completed.connect(_on_response)

func is_active() -> bool:
	if not SettingsState.telemetry_enabled:
		return false
	return _effective_url() != ""

func _effective_url() -> String:
	var override: String = SettingsState.telemetry_webhook_url.strip_edges()
	if override.begins_with("https://discord.com/api/webhooks/") or override.begins_with("https://discordapp.com/api/webhooks/"):
		return override
	return BUILT_IN_WEBHOOK_URL

func send_battle_log(payload: Dictionary) -> void:
	if not is_active():
		return
	var url: String = _effective_url()
	var embed: Dictionary = _build_embed(payload)
	var body: Dictionary = {
		"username": "Cogwright Test-Telemetry",
		"embeds": [embed],
	}
	var json: String = JSON.stringify(body)
	var headers: PackedStringArray = PackedStringArray(["Content-Type: application/json"])
	var err: int = _http.request(url, headers, HTTPClient.METHOD_POST, json)
	if err != OK:
		push_warning("[Telemetry] HTTP-Request fehlgeschlagen: %d" % err)
		return
	_pending += 1

func send_daily_score(payload: Dictionary) -> void:
	# Postet ein Daily-Run-Ergebnis als kompakten Leaderboard-Eintrag.
	# Der Discord-Channel sammelt so die Daily-Scores aller Tester.
	if not is_active():
		return
	var url: String = _effective_url()
	var alias: String = String(payload.get("alias", "")).strip_edges()
	if alias == "":
		alias = "Tester"
	var won: bool = payload.get("victory", false)
	var fields: Array = [
		{"name": "Spieler", "value": alias, "inline": true},
		{"name": "Score", "value": str(int(payload.get("score", 0))), "inline": true},
		{"name": "Tag", "value": String(payload.get("date_key", "")), "inline": true},
		{"name": "Charakter", "value": "%s · Heat %d" % [payload.get("character", "?"), int(payload.get("heat", 0))], "inline": true},
		{"name": "Encounters", "value": str(int(payload.get("encounters_won", 0))), "inline": true},
		{"name": "Ergebnis", "value": "Sieg" if won else "Niederlage", "inline": true},
	]
	var body: Dictionary = {
		"username": "Cogwright Daily-Leaderboard",
		"embeds": [{
			"title": "🏁 Daily-Score · %s" % String(payload.get("date_key", "")),
			"description": "`LEADERBOARD` Eintrag — automatisch aggregierbar.",
			"color": 0xF1C40F if won else 0x95A5A6,
			"fields": fields,
			"timestamp": Time.get_datetime_string_from_system(false, true),
		}],
	}
	var json: String = JSON.stringify(body)
	var headers: PackedStringArray = PackedStringArray(["Content-Type: application/json"])
	var err: int = _http.request(url, headers, HTTPClient.METHOD_POST, json)
	if err != OK:
		push_warning("[Telemetry] Daily-Score Request fehlgeschlagen: %d" % err)
		return
	_pending += 1

func _on_response(_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	_pending = max(0, _pending - 1)
	if response_code < 200 or response_code >= 300:
		push_warning("[Telemetry] Discord-Webhook HTTP %d" % response_code)

func _build_embed(p: Dictionary) -> Dictionary:
	var color: int = 0x57F287 if p.get("victory", false) else 0xED4245   # green / red
	var fields: Array = []
	fields.append({
		"name": "Charakter",
		"value": "%s · Heat %d" % [p.get("character", "?"), int(p.get("heat", 0))],
		"inline": true,
	})
	fields.append({
		"name": "Encounter",
		"value": String(p.get("encounter_name", "?")),
		"inline": true,
	})
	fields.append({
		"name": "Ergebnis",
		"value": "%s · HP %d/%d" % [
			p.get("outcome", "?"),
			int(p.get("player_hp_end", 0)),
			int(p.get("player_max_hp", 0)),
		],
		"inline": true,
	})
	var perks: Array = p.get("perks", [])
	if perks.size() > 0:
		fields.append({
			"name": "Perks",
			"value": ", ".join(perks),
			"inline": false,
		})
	var layout_text: String = String(p.get("tower_layout_text", ""))
	if layout_text != "":
		fields.append({
			"name": "Turm-Layout",
			"value": _wrap_code(layout_text, MAX_FIELD_LEN),
			"inline": false,
		})
	var log_excerpt: String = String(p.get("log_excerpt", ""))
	if log_excerpt != "":
		fields.append({
			"name": "Battle-Log (letzte %d Zeilen)" % MAX_LOG_LINES,
			"value": _wrap_code(log_excerpt, MAX_FIELD_LEN),
			"inline": false,
		})
	return {
		"title": "Cogwright v%s · %s" % [AppVersion.VERSION, "Sieg" if p.get("victory", false) else "Niederlage"],
		"color": color,
		"fields": fields,
		"timestamp": Time.get_datetime_string_from_system(false, true),
	}

func _wrap_code(s: String, max_len: int) -> String:
	# Discord-Code-Block, gekuerzt mit Suffix
	var content: String = s
	var overhead: int = 8   # "```\n" + "\n```"
	if content.length() > max_len - overhead:
		content = content.substr(0, max_len - overhead - 3) + "..."
	return "```\n" + content + "\n```"
