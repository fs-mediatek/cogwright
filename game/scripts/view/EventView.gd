extends Control

const EVENT_PATHS: Array[String] = [
	"res://data/events/01_wandering_inventor.tres",
	"res://data/events/02_rusted_shrine.tres",
	"res://data/events/03_scrapheap.tres",
	"res://data/events/04_enchanted_book.tres",
	"res://data/events/05_drifter_dog.tres",
	"res://data/events/06_oil_barrel.tres",
	"res://data/events/07_singing_pipes.tres",
	"res://data/events/08_pressure_cache.tres",
	"res://data/events/09_clockmaker_apprentice.tres",
	"res://data/events/10_steam_vent.tres",
	"res://data/events/11_forge_offering.tres",
	"res://data/events/12_mysterious_lever.tres",
	"res://data/events/13_graviermeister.tres",
	"res://data/events/14_faustischer_pakt.tres",
]

@onready var _title_label: Label = $Layout/TitleLabel
@onready var _description_label: RichTextLabel = $Layout/DescriptionLabel
@onready var _choices_container: VBoxContainer = $Layout/ChoicesContainer
@onready var _result_label: RichTextLabel = $Layout/ResultLabel
@onready var _continue_btn: Button = $Layout/ContinueButton
@onready var _header_stats: Label = $Layout/HeaderStats

var _event: EventConfig
var _resolved: bool = false

func _ready() -> void:
	if not RunState.is_run_active:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	_continue_btn.pressed.connect(_on_continue)
	_continue_btn.visible = false
	_result_label.visible = false
	_load_event()
	_refresh_header()
	AudioManager.play_music("res://assets/audio/music/menu_factory.ogg", -14.0)
	AudioManager.play_ambient("event")
	if RunState.is_coop:
		CoopManager.action_applied.connect(_on_coop_action)
		CoopManager.transition_committed.connect(_on_coop_transition)

func _load_event() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = RunState.run_seed + RunState.current_encounter_idx * 7727
	_event = load(EVENT_PATHS[rng.randi() % EVENT_PATHS.size()])
	_title_label.text = _event.title
	_description_label.text = "[center]%s[/center]" % _event.description
	_build_choices()

func _refresh_header() -> void:
	_header_stats.text = "Gold: %d   ·   HP: %d / %d" % [RunState.gold, RunState.tower_hp, RunState.tower_max_hp]

func _build_choices() -> void:
	for child in _choices_container.get_children():
		child.queue_free()
	for i in range(_event.choice_labels.size()):
		var btn := Button.new()
		btn.text = "%s\n%s" % [_event.choice_labels[i], _event.choice_descriptions[i]]
		btn.custom_minimum_size = Vector2(700, 60)
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_choice.bind(i))
		_choices_container.add_child(btn)

func _on_choice(idx: int) -> void:
	if _resolved:
		return
	if RunState.is_coop:
		CoopManager.sync_action("event_choice", {"idx": idx})
	else:
		_apply_choice(idx)

func _apply_choice(idx: int) -> void:
	if _resolved:
		return
	var outcome: String = _event.choice_outcomes[idx]
	# Verzweigung: laedt ein Folge-Event in dieselbe Ansicht, ohne den Run-Schritt abzuschliessen.
	if outcome.begins_with("branch:"):
		AudioManager.ui("select")
		_load_followup(outcome.substr("branch:".length()))
		return
	_resolved = true
	AudioManager.ui("select")
	var result_text: String = _resolve_outcome(outcome)
	_result_label.text = "[center]%s[/center]" % result_text
	_result_label.visible = true
	_continue_btn.visible = true
	for child in _choices_container.get_children():
		(child as Button).disabled = true
	_refresh_header()

func _resolve_outcome(outcome: String) -> String:
	# Werkstatt-Upgrade "event_luck": +20% pro Stufe auf positive Belohnungen (Gold, HP)
	var luck_mult: float = 1.0 + float(MetaState.upgrade_level("event_luck")) * 0.20
	var parts: Array = outcome.split(":")
	var key: String = parts[0]
	match key:
		"noop":
			return "Du gehst weiter, ohne etwas zu ändern."
		"gold":
			var amount: int = int(parts[1])
			if amount > 0:
				amount = int(round(float(amount) * luck_mult))
			RunState.gold = max(0, RunState.gold + amount)
			return "✦ %+d Gold" % amount
		"item":
			var item_id: String = parts[1]
			var cost: int = int(parts[2])  # negativ = Kosten
			if RunState.gold + cost < 0:
				return "Du hast nicht genug Gold."
			RunState.gold += cost
			RunState.add_to_inventory(load("res://data/items/%s.tres" % item_id))
			return "✦ %s erhalten (%d Gold)" % [load("res://data/items/%s.tres" % item_id).display_name, cost]
		"trade_inventory_for_gold_hp":
			var g: int = int(round(float(int(parts[1])) * luck_mult))
			var h: int = int(round(float(int(parts[2])) * luck_mult))
			if RunState.inventory.size() > 0:
				var rng := RandomNumberGenerator.new()
				rng.seed = RunState.run_seed + 1234
				var lost: Item = RunState.inventory[rng.randi() % RunState.inventory.size()]
				# Aus Inventar entfernen (auch aus Tower wenn platziert)
				_remove_item(lost)
				RunState.gold += g
				RunState.tower_hp = min(RunState.tower_max_hp, RunState.tower_hp + h)
				return "✦ %s gegeben.   +%d Gold, +%d HP" % [lost.display_name, g, h]
			return "Dein Inventar ist leer — die Erfinderin nickt traurig und zieht weiter."
		"damage_gold":
			var dmg: int = int(parts[1])
			var gl: int = int(round(float(int(parts[2])) * luck_mult))
			RunState.tower_hp = max(1, RunState.tower_hp - dmg)
			RunState.gold += gl
			return "✦ -%d HP, +%d Gold" % [dmg, gl]
		"heal_full_cost":
			var c: int = int(parts[1])
			if RunState.gold < c:
				return "Du hast nicht genug Gold, der Hebel rührt sich nicht."
			RunState.gold -= c
			RunState.tower_hp = RunState.tower_max_hp
			return "✦ Voll geheilt.   -%d Gold" % c
		"random_item_or_damage":
			var dmg2: int = int(parts[1])
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = RunState.run_seed + RunState.current_encounter_idx + 999
			# Bei Glück (luck) verschiebt sich die Wahrscheinlichkeit zugunsten des Item-Funds
			var roll: float = rng2.randf()
			var item_threshold: float = 0.5 + float(MetaState.upgrade_level("event_luck")) * 0.10
			if roll < item_threshold:
				# Item-Glück
				var ids: Array[String] = ["spark_spitter", "steam_kettle", "gear_sync", "pressure_hammer"]
				var item_id: String = ids[rng2.randi() % ids.size()]
				RunState.add_to_inventory(load("res://data/items/%s.tres" % item_id))
				return "✦ Glück gehabt — %s gefunden." % load("res://data/items/%s.tres" % item_id).display_name
			else:
				RunState.tower_hp = max(1, RunState.tower_hp - dmg2)
				return "✦ Eine scharfe Kante — -%d HP." % dmg2
		"relic":
			# relic:random  oder  relic:<id>  (optional :<hp_kosten>)
			var which: String = parts[1] if parts.size() > 1 else "random"
			var hp_cost: int = int(parts[2]) if parts.size() > 2 else 0
			if hp_cost > 0:
				RunState.tower_hp = max(1, RunState.tower_hp - hp_cost)
			var rng_r := RandomNumberGenerator.new()
			rng_r.seed = RunState.run_seed + RunState.current_encounter_idx * 3301 + 17
			var grant_id: String = which
			if which == "random":
				var picks: Array[String] = RelicDB.random_unowned(RunState.active_relics, 1, rng_r)
				if picks.is_empty():
					RunState.gold += 40
					return "✦ Du besitzt bereits alle Relikte — +40 Gold als Trost."
				grant_id = picks[0]
			if RunState.has_relic(grant_id):
				RunState.gold += 40
				return "✦ Relikt bereits in Besitz — +40 Gold."
			RunState.add_relic(grant_id)
			return "✦ Relikt erhalten: %s" % RelicDB.relic_name(grant_id)
		"inscribe":
			# inscribe:random  oder  inscribe:<inscription_id>  (optional :<gold_kosten>)
			if RunState.inventory.is_empty():
				return "Dein Inventar ist leer — nichts zu gravieren."
			var insc_cost: int = int(parts[2]) if parts.size() > 2 else 0
			if RunState.gold < insc_cost:
				return "Du hast nicht genug Gold für die Gravur."
			var rng_i := RandomNumberGenerator.new()
			rng_i.seed = RunState.run_seed + RunState.current_encounter_idx * 5113 + 41
			var insc_id: String = parts[1] if parts.size() > 1 else "random"
			if insc_id == "random":
				insc_id = InscriptionDB.random_choices(1, rng_i)[0]
			RunState.gold -= insc_cost
			# Bevorzugt ein platziertes Item, sonst irgendein Inventar-Item
			var target: Item = null
			for it in RunState.placed_items():
				target = it
				break
			if target == null:
				target = RunState.inventory[rng_i.randi() % RunState.inventory.size()]
			RunState.apply_inscription(target, insc_id)
			return "✦ %s wurde mit »%s« graviert." % [target.display_name, InscriptionDB.inscription_name(insc_id)]
		"curse":
			# curse:<dmg_delta>:<gold>  z.B.  curse:-0.10:60  -> -10% Run-Schaden, +60 Gold
			var delta: float = float(parts[1])
			var bonus_gold: int = int(parts[2]) if parts.size() > 2 else 0
			RunState.run_damage_mult = max(0.5, RunState.run_damage_mult + delta)
			RunState.gold += bonus_gold
			return "✦ Ein Fluch senkt sich herab — Schaden %+.0f%% für den ganzen Run, dafür +%d Gold." % [delta * 100.0, bonus_gold]
		"blessing":
			# blessing:<dmg_delta>  z.B.  blessing:0.08  -> +8% Run-Schaden
			var bdelta: float = float(parts[1])
			RunState.run_damage_mult = min(2.0, RunState.run_damage_mult + bdelta)
			return "✦ Ein Segen durchströmt deinen Turm — Schaden %+.0f%% für den ganzen Run." % (bdelta * 100.0)
		"damage_then_blessing":
			# damage_then_blessing:<hp>:<dmg_delta>  -> HP-Kosten, dann Run-Segen
			var dhp: int = int(parts[1])
			var ddelta: float = float(parts[2])
			RunState.tower_hp = max(1, RunState.tower_hp - dhp)
			RunState.run_damage_mult = min(2.0, RunState.run_damage_mult + ddelta)
			return "✦ -%d HP — dafür +%.0f%% Schaden für den ganzen Run." % [dhp, ddelta * 100.0]
		"gold_then_blessing":
			# gold_then_blessing:<gold_delta>:<dmg_delta>  -> Gold-Kosten, dann Run-Segen
			var gcost: int = int(parts[1])  # negativ = Kosten
			var gdelta: float = float(parts[2])
			if RunState.gold + gcost < 0:
				return "Du hast nicht genug Gold — die Esse erlischt enttäuscht."
			RunState.gold += gcost
			RunState.run_damage_mult = min(2.0, RunState.run_damage_mult + gdelta)
			return "✦ %d Gold — dafür +%.0f%% Schaden für den ganzen Run." % [gcost, gdelta * 100.0]
	return "(unerwartetes Outcome: %s)" % outcome

func _load_followup(path: String) -> void:
	# Laedt ein Folge-Event (Verzweigung). Setzt Titel/Beschreibung/Choices neu.
	var full_path: String = path if path.begins_with("res://") else "res://data/events/%s.tres" % path
	if not ResourceLoader.exists(full_path):
		_result_label.text = "[center](Verzweigung nicht gefunden)[/center]"
		_result_label.visible = true
		_continue_btn.visible = true
		return
	_event = load(full_path)
	_title_label.text = _event.title
	_description_label.text = "[center]%s[/center]" % _event.description
	_build_choices()
	_refresh_header()

func _remove_item(item: Item) -> void:
	# Aus Tower entfernen
	for i in range(RunState.tower_layout.size()):
		if RunState.tower_layout[i] == item:
			RunState.tower_layout[i] = null
	# Aus Inventar entfernen
	RunState.inventory.erase(item)

func _on_continue() -> void:
	AudioManager.ui("click")
	if RunState.is_coop:
		CoopManager.propose_transition("event:continue")
		_continue_btn.text = "Warte auf Mitspieler…"
		_continue_btn.disabled = true
	else:
		_do_continue()

func _do_continue() -> void:
	if RunState.current_map != null:
		RunState.current_map.mark_current_completed()
	get_tree().change_scene_to_file("res://scenes/MapView.tscn")

func _on_coop_action(action: String, payload: Dictionary) -> void:
	if action == "event_choice":
		_apply_choice(int(payload.get("idx", 0)))

func _on_coop_transition(key: String) -> void:
	if key == "event:continue":
		_do_continue()
