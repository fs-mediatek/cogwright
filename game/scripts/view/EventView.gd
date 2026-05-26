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
	_resolved = true
	AudioManager.ui("select")
	var outcome: String = _event.choice_outcomes[idx]
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
	return "(unerwartetes Outcome: %s)" % outcome

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
