extends Node

# Globaler Run-State, als Autoload-Singleton registriert in project.godot.
# Hält das Inventar, die Tower-Platzierungen, HP und Encounter-Fortschritt
# zwischen Szenen-Wechseln (MainMenu → RunStart → TowerBuilder → BattleView → ItemReward → ...).

signal run_started
signal run_ended(victory: bool)

const SAVE_PATH: String = "user://run_save.cfg"

# Charakter-Passive: jeder Charakter hat einen Damage-Tag-Bonus und/oder Heal-Bonus.
const CHARACTER_PASSIVES: Dictionary = {
	"fire":     {"damage_tag": &"fire",     "damage_bonus": 0.10, "heal_bonus": 0,  "ability": "spark_swirl"},
	"pressure": {"damage_tag": &"pressure", "damage_bonus": 0.10, "heal_bonus": 0,  "ability": "overpressure"},
	"blunt":    {"damage_tag": &"blunt",    "damage_bonus": 0.0,  "heal_bonus": 15, "ability": "emergency_repair"},
	"reactive": {"damage_tag": &"reactive", "damage_bonus": 0.25, "heal_bonus": 0,  "ability": "sabotage"},
	"gunner":   {"damage_tag": &"ranged",   "damage_bonus": 0.20, "heal_bonus": 0,  "ability": "salvo_burst",
	             "cd_penalty_tag": &"reactive", "cd_penalty_amount": 0.20},
	"mastermind": {"damage_tag": &"",       "damage_bonus": 0.0,  "heal_bonus": 0,  "ability": "improvise",
	             "tag_diversity_bonus": 0.08},
}

const CHARACTER_ABILITIES: Dictionary = {
	"spark_swirl":        {"name": "Funken-Wirbel",       "desc": "Alle [fire]-Items feuern sofort."},
	"overpressure":       {"name": "Überdruck",            "desc": "Alle Items im Turm feuern sofort."},
	"emergency_repair":   {"name": "Notfall-Reparatur",    "desc": "+50 HP sofort."},
	"sabotage":           {"name": "Sabotage",             "desc": "Gegner: -40% Cooldown-Speed für 5s + Brand 20 DMG."},
	"salvo_burst":        {"name": "Volle Salve",          "desc": "Alle [ranged]-Items im Turm feuern sofort."},
	"improvise":          {"name": "Improvisation",        "desc": "Alle Items im Turm feuern sofort."},
}

const BASE_HP: int = 200
const POST_VICTORY_HEAL_PERCENT: float = 0.50  # +40% Max-HP automatisch nach jedem gewonnenen Encounter

# Dynamisch — basiert auf gewählter Run-Länge. Default (NORMAL) = 5 wie bisher.
static func total_encounters_for(length: int) -> int:
	return MapGenerator.total_fights_for(length)

# Inventar: alle Items, die der Spieler aktuell besitzt (auch nicht-platzierte)
var inventory: Array[Item] = []

# Layout: floor_idx * 3 + slot_idx → Item (oder null, wenn Slot leer)
var tower_layout: Array = []  # Array[Item|null] mit Länge 9

var floors: Array[FloorConfig] = []

var current_encounter_idx: int = 0
var tower_hp: int = 0
var tower_max_hp: int = 0

var run_seed: int = 0
var encounters_won: int = 0
var is_run_active: bool = false
var last_auto_heal: int = 0  # für ItemReward-Anzeige
var current_map: RunMap = null
var pending_encounter_path: String = ""   # vom MapView gesetzt, vom BattleView gelesen
var gold: int = 0   # In-Run Currency, in Shops einsetzbar
var current_heat: int = 0  # Schwierigkeitsstufe für diesen Run
var current_run_length: int = 1   # MapGenerator.RunLength: 0=SHORT, 1=NORMAL, 2=LONG
var total_encounters: int = 5   # vom Run-Length abgeleitet, beim Start gesetzt
var current_character_id: String = "fire"   # für Passive-Effekte
var active_ability_used: bool = false   # 1x pro Battle nutzbar; reset bei advance_encounter
var active_relics: Array[String] = []   # gefundene Relikte (gelten den ganzen Run)
var run_damage_mult: float = 1.0   # Event-Konsequenzen (Segen >1.0 / Fluch <1.0), gilt den ganzen Run

func has_relic(relic_id: String) -> bool:
	return relic_id in active_relics

func add_relic(relic_id: String) -> void:
	if relic_id in active_relics:
		return
	active_relics.append(relic_id)
	# Sofort wirkende Relikte (HP-Boni) direkt anwenden
	if relic_id == "druckspeicher":
		tower_max_hp += 60
		tower_hp += 60

# Co-Op-Felder (Phase 1b+)
var is_coop: bool = false
var coop_local_peer_id: int = 0   # eigene Peer-ID innerhalb des Coop-Runs
var coop_characters: Dictionary = {}   # peer_id -> character_id (für UI-Anzeige)

# Letztes Battle-Log + Outcome — für ausklappbares Log im GameOver / RunComplete
var last_battle_log: Array[String] = []
var last_battle_outcome: String = ""
var last_encounter_name: String = ""
var last_battle_damage_breakdown: Array[Dictionary] = []   # sortierte Per-Item-Damage-Liste

func _ready() -> void:
	tower_layout.resize(9)

func start_new_run(starter_items: Array[Item], seed_value: int = -1, length: int = MapGenerator.RunLength.NORMAL, character_id: String = "fire") -> void:
	current_character_id = character_id
	active_ability_used = false
	active_relics.clear()
	run_damage_mult = 1.0
	inventory.clear()
	# Resources werden von load() gecached — gleiches Item zweimal im Set wäre
	# dieselbe Reference. Wir duplizieren, damit jede Inventar-Position eine
	# eindeutige Instanz ist (sonst kollabieren Duplikate in unplaced_items()).
	for item in starter_items:
		inventory.append(item.duplicate(true))
	# Werkstatt-Upgrade: zusätzliche Starter-Items zufällig aus Pool
	var extra_count: int = MetaState.upgrade_level("starter_extra_item")
	if extra_count > 0:
		var pool: Array = MetaState.DEFAULT_ITEMS
		var extra_rng := RandomNumberGenerator.new()
		extra_rng.seed = (randi() if seed_value < 0 else seed_value) + 7777
		for j in range(extra_count):
			var pick_id: String = String(pool[extra_rng.randi() % pool.size()])
			var bonus_path: String = "res://data/items/%s.tres" % pick_id
			if ResourceLoader.exists(bonus_path):
				inventory.append((load(bonus_path) as Item).duplicate(true))
	tower_layout.clear()
	tower_layout.resize(9)
	floors = _load_floors()
	# Werkstatt-Upgrade: zusätzliche Max-HP
	tower_max_hp = _compute_max_hp(BASE_HP, floors) + MetaState.upgrade_level("tower_hp") * 25
	# Perk Notvorrat: +50 max HP
	if MetaState.has_perk("notvorrat"):
		tower_max_hp += 50
	tower_hp = tower_max_hp
	current_encounter_idx = 0
	encounters_won = 0
	is_run_active = true
	run_seed = randi() if seed_value < 0 else seed_value
	current_run_length = length
	total_encounters = MapGenerator.total_fights_for(length)
	current_map = MapGenerator.generate(run_seed, length)
	pending_encounter_path = ""
	# Werkstatt-Upgrade: zusätzliches Startkapital
	gold = 30 + MetaState.upgrade_level("starting_gold") * 5
	MetaState.on_run_started()
	run_started.emit()

func end_run(victory: bool) -> void:
	is_run_active = false
	if victory:
		MetaState.on_run_won()
	# Perk-Unlocks pruefen am Run-Ende
	var newly_unlocked: Array[String] = MetaState.check_perk_unlocks()
	for perk_id in newly_unlocked:
		MetaState.last_run_unlocks.append("Perk: %s" % MetaState.PERKS[perk_id]["name"])
	if is_coop:
		is_coop = false
		coop_local_peer_id = 0
		coop_characters.clear()
	clear_save()
	run_ended.emit(victory)

# --- Mid-Run-Save ---

func save_run() -> bool:
	# Coop-Runs werden NICHT persistiert (sync-Komplexität).
	if not is_run_active or is_coop or current_map == null:
		clear_save()
		return false
	var cfg := ConfigFile.new()
	cfg.set_value("run", "version", 1)
	cfg.set_value("run", "seed", run_seed)
	cfg.set_value("run", "length", current_run_length)
	cfg.set_value("run", "total_encounters", total_encounters)
	cfg.set_value("run", "current_encounter_idx", current_encounter_idx)
	cfg.set_value("run", "encounters_won", encounters_won)
	cfg.set_value("run", "tower_hp", tower_hp)
	cfg.set_value("run", "tower_max_hp", tower_max_hp)
	cfg.set_value("run", "gold", gold)
	cfg.set_value("run", "heat", current_heat)
	cfg.set_value("run", "pending_encounter_path", pending_encounter_path)
	# Inventar via resource_path-IDs (auf .tres-Dateinamen reduziert)
	var inv_ids: Array[String] = []
	var inv_inscriptions: Array[String] = []
	for it in inventory:
		inv_ids.append(_item_id_from_resource(it))
		inv_inscriptions.append(String(it.inscription))
	cfg.set_value("run", "inventory_ids", inv_ids)
	cfg.set_value("run", "inventory_inscriptions", inv_inscriptions)
	# Tower-Layout: pro Slot der Inventar-Index (oder -1 wenn leer)
	var layout_idx: Array[int] = []
	for s in tower_layout:
		layout_idx.append(inventory.find(s) if s != null else -1)
	cfg.set_value("run", "tower_layout_indices", layout_idx)
	cfg.set_value("run", "active_relics", active_relics)
	cfg.set_value("run", "run_damage_mult", run_damage_mult)
	# Map: aktueller Node + besuchte Knoten
	cfg.set_value("run", "current_node_id", current_map.current_node_id)
	var completed_ids: Array[int] = []
	for n in current_map.nodes:
		if n.completed:
			completed_ids.append(n.id)
	cfg.set_value("run", "completed_node_ids", completed_ids)
	return cfg.save(SAVE_PATH) == OK

func has_saved_run() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func load_run() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	if int(cfg.get_value("run", "version", 0)) != 1:
		clear_save()
		return false
	# Inventar rekonstruieren
	var inv_ids: Array = cfg.get_value("run", "inventory_ids", [])
	var inv_inscriptions: Array = cfg.get_value("run", "inventory_inscriptions", [])
	inventory.clear()
	for i in range(inv_ids.size()):
		var item_id: String = String(inv_ids[i])
		var path: String = "res://data/items/%s.tres" % item_id
		if ResourceLoader.exists(path):
			var it: Item = (load(path) as Item).duplicate(true)
			if i < inv_inscriptions.size():
				it.inscription = StringName(String(inv_inscriptions[i]))
			inventory.append(it)
	# Floors immer aus Configs
	floors = _load_floors()
	tower_max_hp = int(cfg.get_value("run", "tower_max_hp", _compute_max_hp(BASE_HP, floors)))
	tower_hp = int(cfg.get_value("run", "tower_hp", tower_max_hp))
	current_encounter_idx = int(cfg.get_value("run", "current_encounter_idx", 0))
	encounters_won = int(cfg.get_value("run", "encounters_won", 0))
	gold = int(cfg.get_value("run", "gold", 0))
	current_heat = int(cfg.get_value("run", "heat", 0))
	run_seed = int(cfg.get_value("run", "seed", 0))
	current_run_length = int(cfg.get_value("run", "length", 1))
	total_encounters = int(cfg.get_value("run", "total_encounters", 5))
	pending_encounter_path = String(cfg.get_value("run", "pending_encounter_path", ""))
	active_relics.clear()
	for r in cfg.get_value("run", "active_relics", []):
		active_relics.append(String(r))
	run_damage_mult = float(cfg.get_value("run", "run_damage_mult", 1.0))
	# Layout
	tower_layout.clear()
	tower_layout.resize(9)
	var layout_idx: Array = cfg.get_value("run", "tower_layout_indices", [])
	for i in range(min(9, layout_idx.size())):
		var idx: int = int(layout_idx[i])
		if idx >= 0 and idx < inventory.size():
			tower_layout[i] = inventory[idx]
	# Map regenerieren aus seed + length, dann completed-Status applizieren
	current_map = MapGenerator.generate(run_seed, current_run_length)
	current_map.current_node_id = int(cfg.get_value("run", "current_node_id", -1))
	var completed_ids: Array = cfg.get_value("run", "completed_node_ids", [])
	for n in current_map.nodes:
		if n.id in completed_ids:
			n.completed = true
	is_run_active = true
	run_started.emit()
	return true

func _item_id_from_resource(item: Item) -> String:
	# Wichtig: nach item.duplicate(true) ist resource_path leer.
	# Item.id ist das exportierte StringName-Feld und bleibt erhalten.
	if item == null:
		return ""
	return String(item.id)

func has_next_encounter() -> bool:
	# Map-basiert: nach Boss-Sieg ist Run zu Ende.
	if current_map == null:
		return current_encounter_idx < total_encounters
	if current_map.current_node_id == -1:
		return true  # noch am Start
	var current_node: MapNode = current_map.get_node_by_id(current_map.current_node_id)
	if current_node == null:
		return false
	# Wenn aktueller Knoten Boss ist (und der wurde gerade besucht): kein Next mehr.
	return current_node.type != MapNode.NodeType.BOSS

func advance_encounter() -> int:
	encounters_won += 1
	current_encounter_idx += 1
	active_ability_used = false   # Aktive Fähigkeit pro Battle resetten
	MetaState.on_encounter_won()
	# Gold-Reward — höher bei Elite/Boss, +Upgrade-Bonus
	var gold_reward: int = 15
	var is_elite: bool = false
	if current_map != null:
		var cn: MapNode = current_map.current_node()
		if cn != null:
			match cn.type:
				MapNode.NodeType.ELITE:
					gold_reward = 30
					is_elite = true
				MapNode.NodeType.BOSS: gold_reward = 60
				_: gold_reward = 15
	gold_reward += MetaState.upgrade_level("encounter_gold") * 2
	# Werkstatt-Upgrade "elite_gold": +10 Gold pro Stufe nach Elite-Sieg
	if is_elite:
		gold_reward += MetaState.upgrade_level("elite_gold") * 10
		MetaState.track_elite_defeat()
	gold += gold_reward
	MetaState.track_gold_in_run(gold)
	# Auto-Heilung nach jedem Sieg, +5%-Punkte pro Upgrade-Stufe
	var heal_percent: float = POST_VICTORY_HEAL_PERCENT + float(MetaState.upgrade_level("auto_heal_boost")) * 0.05
	var heal_amount: int = int(round(float(tower_max_hp) * heal_percent))
	var before: int = tower_hp
	tower_hp = min(tower_max_hp, tower_hp + heal_amount)
	return tower_hp - before  # tatsächlich gewährter Heal-Wert

func place_in_slot(slot_index: int, item: Item) -> void:
	# Wenn das Item bereits an anderer Stelle steht, dort entfernen.
	for i in range(tower_layout.size()):
		if tower_layout[i] == item:
			tower_layout[i] = null
	tower_layout[slot_index] = item

func remove_from_slot(slot_index: int) -> Item:
	var item: Item = tower_layout[slot_index]
	tower_layout[slot_index] = null
	return item

func placed_items() -> Array[Item]:
	var result: Array[Item] = []
	for it in tower_layout:
		if it != null:
			result.append(it)
	return result

func unplaced_items() -> Array[Item]:
	var placed := placed_items()
	var result: Array[Item] = []
	for it in inventory:
		if it not in placed:
			result.append(it)
	return result

func build_player_tower() -> Tower:
	var t := Tower.new()
	t.name = "Player"
	t.floors = floors
	t.max_hp = tower_max_hp
	t.hp = tower_hp
	for i in range(tower_layout.size()):
		if tower_layout[i] != null:
			var floor_idx: int = i / 3
			var slot_idx: int = i % 3
			t.add_slot(tower_layout[i], floor_idx, slot_idx)
	return t

func add_to_inventory(item: Item) -> void:
	# Duplizieren analog zu start_new_run — vermeidet Resource-Cache-Aliasing,
	# falls der Spieler später dasselbe Item nochmal als Belohnung wählt.
	inventory.append(item.duplicate(true))

func apply_inscription(item: Item, inscription_id: String) -> void:
	# Setzt eine Inschrift auf eine konkrete Inventar-Instanz (Item.duplicate-Instanz).
	if item != null:
		item.inscription = StringName(inscription_id)

# --- Sell / Upgrade ---

func sell_price(item: Item) -> int:
	if item == null:
		return 0
	match item.rarity:
		Item.Rarity.COMMON: return 5
		Item.Rarity.UNCOMMON: return 10
		Item.Rarity.RARE: return 18
		Item.Rarity.LEGENDARY: return 30
	return 5

func sell_item_at(inv_idx: int) -> int:
	if inv_idx < 0 or inv_idx >= inventory.size():
		return 0
	var item: Item = inventory[inv_idx]
	var price: int = sell_price(item)
	for i in range(tower_layout.size()):
		if tower_layout[i] == item:
			tower_layout[i] = null
	inventory.remove_at(inv_idx)
	gold += price
	return price

func find_upgrade_candidates() -> Array[String]:
	# Item-IDs (StringName als String) mit 3+ Vorkommen im Inventar
	var counts: Dictionary = {}
	for it in inventory:
		var k: String = String(it.id)
		counts[k] = int(counts.get(k, 0)) + 1
	var result: Array[String] = []
	for k in counts.keys():
		if int(counts[k]) >= 3:
			result.append(String(k))
	return result

func upgrade_item(item_id: String) -> Item:
	# Sucht 3 Items mit der gegebenen id, entfernt sie und gibt 1 verstaerktes zurueck.
	var to_remove: Array[Item] = []
	for it in inventory:
		if String(it.id) == item_id:
			to_remove.append(it)
			if to_remove.size() >= 3:
				break
	if to_remove.size() < 3:
		return null
	for it in to_remove:
		for i in range(tower_layout.size()):
			if tower_layout[i] == it:
				tower_layout[i] = null
		inventory.erase(it)
	var upgraded: Item = to_remove[0].duplicate(true)
	upgraded.display_name = "Verstärkter " + upgraded.display_name
	upgraded.rarity = min(upgraded.rarity + 1, Item.Rarity.LEGENDARY)
	if upgraded.cooldown_seconds < 90.0:
		# Reaktive Items (CD ≥ 90) bleiben reaktiv
		upgraded.cooldown_seconds = max(0.5, upgraded.cooldown_seconds * 0.85)
	var new_effects: Array[ItemEffect] = []
	for eff in upgraded.effects:
		var new_eff: ItemEffect = eff.duplicate(true)
		if new_eff is DealDamageEffect:
			var d := new_eff as DealDamageEffect
			d.amount = int(ceil(float(d.amount) * 1.4))
		elif new_eff is HealSelfEffect:
			var h := new_eff as HealSelfEffect
			h.amount = int(ceil(float(h.amount) * 1.4))
		elif new_eff is TagBonusEffect:
			var t := new_eff as TagBonusEffect
			t.bonus_damage_percent = t.bonus_damage_percent * 1.3
		elif new_eff is BoostNeighborEffect:
			var b := new_eff as BoostNeighborEffect
			b.cooldown_reduction_percent = min(80.0, b.cooldown_reduction_percent * 1.3)
		elif new_eff is BoostFloorEffect:
			var bf := new_eff as BoostFloorEffect
			bf.cooldown_reduction_percent = min(80.0, bf.cooldown_reduction_percent * 1.3)
		new_effects.append(new_eff)
	upgraded.effects = new_effects
	inventory.append(upgraded)
	return upgraded

func _load_floors() -> Array[FloorConfig]:
	var f: Array[FloorConfig] = []
	f.append(load("res://data/floors/foundation.tres"))
	f.append(load("res://data/floors/workshop.tres"))
	f.append(load("res://data/floors/pinnacle.tres"))
	return f

func _compute_max_hp(base: int, fl: Array[FloorConfig]) -> int:
	var total: float = float(base)
	for f in fl:
		total += float(base) * f.hp_modifier
	return int(round(total))
