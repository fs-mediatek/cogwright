extends Node

# Persistenter Spiel-State über alle Runs hinweg.
# Wird beim Spielstart aus user://meta_save.cfg geladen und nach jedem Run gespeichert.

const SAVE_PATH: String = "user://meta_save.cfg"

signal meta_changed   # für UI-Refreshes
signal item_unlocked(item_id)
signal character_unlocked(character_id)
signal achievement_unlocked(id)

# Run-Statistiken
var runs_attempted: int = 0
var runs_won: int = 0
var encounters_won_total: int = 0
var bosses_defeated: int = 0

# Erweiterte Stats (für Stats-Screen)
var total_damage_dealt: int = 0
var total_damage_taken: int = 0
var item_placements: Dictionary = {}   # item_id → count
var item_purchases: Dictionary = {}    # item_id → count
var character_wins: Dictionary = {}    # character_id → count
var character_attempts: Dictionary = {}# character_id → count
var discovered_items: Array[String] = []  # IDs der Items, die schon mal als Reward/Shop angeboten wurden

# Currency
var resonance_crystals: int = 0
var max_heat_unlocked: int = 0   # Heat freigeschaltet, sobald 1. Boss-Sieg
var selected_heat: int = 0       # vom RunStart-Selector gesetzt

# Daily-Challenge: gespeicherte Highscores als Datum-String → Score
var daily_records: Dictionary = {}
var is_daily_run: bool = false

# Achievements: id -> bool (unlocked)
var achievements: Dictionary = {}
const ALL_ACHIEVEMENTS: Dictionary = {
	"first_blood": {"name": "Erste Funken", "desc": "Gewinne deinen ersten Encounter."},
	"first_boss": {"name": "Eisenfäller", "desc": "Besiege den Endboss zum ersten Mal."},
	"three_bosses": {"name": "Werkstatt-Veteran", "desc": "Besiege den Endboss dreimal."},
	"heat_3": {"name": "Glühend heiß", "desc": "Gewinne einen Run auf Heat 3 oder höher."},
	"all_chars": {"name": "Vier Hände am Werk", "desc": "Schalte alle vier Charaktere frei."},
	"daily_win": {"name": "Tageswerk", "desc": "Gewinne eine Daily Challenge."},
	"shop_addict": {"name": "Werkstatt-Stammgast", "desc": "Kaufe 5 Items in einem Run im Shop."},
	"perfect_run": {"name": "Ungerührt", "desc": "Beende einen Run mit voller HP."},
}

# Freigeschaltete Inhalte
var characters_unlocked: Array[String] = []
var items_unlocked: Array[String] = []

# --- Perks ---
# Lifetime-Stats fuer Perk-Unlocks
var lifetime_crits: int = 0
var lifetime_elites_defeated: int = 0
var max_gold_in_run: int = 0
var bosses_defeated_per_id: Dictionary = {}    # boss_encounter_id -> count
var heat3_wins: int = 0

var unlocked_perks: Array[String] = []
var selected_perks: Array[String] = []   # max 3, persistiert fuer naechsten Run

# Perk-Registry — alle 13 Perks mit Beschreibung + Unlock-Bedingung
const PERKS: Dictionary = {
	"notvorrat": {
		"name": "Notvorrat",
		"desc": "Start mit +50 max Tower-HP.",
		"unlock_desc": "Besiege den Endboss zum ersten Mal.",
	},
	"schnellfeuer": {
		"name": "Schnellfeuer",
		"desc": "Alle [ranged]-Items: -15% Cooldown.",
		"unlock_desc": "Gewinne einen Run mit Pyrotechniker.",
	},
	"aetherantrieb": {
		"name": "Aetherantrieb",
		"desc": "Battle-Speed startet auf x1.5.",
		"unlock_desc": "Entdecke 15 Items im Codex.",
	},
	"druckverwerter": {
		"name": "Druckverwerter",
		"desc": "Alle [pressure]-Items: +20% Schaden.",
		"unlock_desc": "Gewinne einen Heat-3-Run mit Druckmeister.",
	},
	"werkbank_mogul": {
		"name": "Werkbank-Mogul",
		"desc": "Werkstatt-Upgrades kosten 25% weniger Resonanzkristalle.",
		"unlock_desc": "Bringe alle 14 Werkstatt-Upgrades auf Stufe 1.",
	},
	"gluecksrad": {
		"name": "Glücksrad",
		"desc": "Item-Reward zeigt 4 Optionen statt 3.",
		"unlock_desc": "Schließe einen Run mit 4 Boss-Siegen ab.",
	},
	"reaktiv_kette": {
		"name": "Reaktiv-Kette",
		"desc": "Reactive-Trigger feuern auch auf diagonale Nachbarn.",
		"unlock_desc": "Gewinne einen Run mit Saboteur ohne Reparatur-Halt.",
	},
	"eisenhaut": {
		"name": "Eisenhaut",
		"desc": "Bei HP unter 30%: +30 dauerhaftes Schild bis Battle-Ende.",
		"unlock_desc": "Gewinne einen Run mit Schmiedin ohne Heil-Knoten zu nutzen.",
	},
	"marktkenner": {
		"name": "Marktkenner",
		"desc": "Shop-Items kosten 30% weniger Gold.",
		"unlock_desc": "Sammle 500 Gold in einem einzigen Run.",
	},
	"pluendererglueck": {
		"name": "Plündererglück",
		"desc": "Elite-Kämpfe geben +1 zusätzliches zufälliges Item.",
		"unlock_desc": "Besiege 5 Elite-Encounter (lebenslang).",
	},
	"kritstrom": {
		"name": "Krit-Strom",
		"desc": "Crit-Chance +10%, Crit-Multiplikator x2.5.",
		"unlock_desc": "Sammle 100 kritische Treffer (lebenslang).",
	},
	"brand_stapel": {
		"name": "Brand-Stapel",
		"desc": "Burn-Effekte stacken statt zu überschreiben.",
		"unlock_desc": "Besiege Boss 'Funken-Tyrann'.",
	},
	"zeitloser_mechanismus": {
		"name": "Zeitloser Mechanismus",
		"desc": "Erster Trigger jedes Items im Battle ist kostenlos.",
		"unlock_desc": "Besiege Boss 'Uhrwerk-Hexe'.",
	},
}

# Letzte Run-Belohnungen (für RunEndScreen-Anzeige)
var last_run_unlocks: Array[String] = []
var last_run_crystals: int = 0

# Alle Charaktere im System (id → meta für Anzeige)
const ALL_CHARACTERS: Dictionary = {
	"fire": {"name": "Pyrotechniker", "unlock_condition": "Default — verfügbar von Anfang an"},
	"pressure": {"name": "Druckmeister", "unlock_condition": "Schließe deinen ersten Encounter ab"},
	"blunt": {"name": "Schmiedin", "unlock_condition": "Besiege den Endboss zum ersten Mal"},
	"reactive": {"name": "Saboteur", "unlock_condition": "Besiege den Endboss dreimal"},
	"gunner": {"name": "Kanonenmeister", "unlock_condition": "Schließe 5 Runs ab (egal ob Sieg oder Niederlage)"},
	"mastermind": {"name": "Mastermind", "unlock_condition": "Besiege den Endboss mit 3 verschiedenen Charakteren"},
}

# Werkstatt-Upgrades (Meta-Progression außerhalb der Kämpfe)
# Spieler kauft permanente Boni mit Resonanzkristallen.
var workshop_upgrades: Dictionary = {}   # id (String) → level (int)

const WORKSHOP_UPGRADES: Dictionary = {
	"starting_gold": {
		"name": "Schmiede-Vorrat",
		"desc": "+5 Startgold pro Stufe",
		"icon": "gold",
		"max_level": 3,
		"costs": [5, 12, 25],
	},
	"tower_hp": {
		"name": "Verstärkter Turm",
		"desc": "+25 Tower-Max-HP pro Stufe",
		"icon": "tower",
		"max_level": 4,
		"costs": [8, 20, 40, 70],
	},
	"reroll_discount": {
		"name": "Marktkenner",
		"desc": "Reroll-Kosten -1 Gold pro Stufe (min. 2)",
		"icon": "market",
		"max_level": 3,
		"costs": [6, 15, 30],
	},
	"shop_extra_item": {
		"name": "Erweitertes Angebot",
		"desc": "+1 Item im Shop-Sortiment",
		"icon": "shop_plus",
		"max_level": 2,
		"costs": [15, 35],
	},
	"auto_heal_boost": {
		"name": "Heiltechnik",
		"desc": "Auto-Heal nach Sieg +5%-Punkte pro Stufe",
		"icon": "heal",
		"max_level": 3,
		"costs": [7, 18, 35],
	},
	"encounter_gold": {
		"name": "Bessere Bergung",
		"desc": "+2 Gold pro Encounter-Sieg pro Stufe",
		"icon": "salvage",
		"max_level": 3,
		"costs": [6, 14, 28],
	},
	"skip_bonus": {
		"name": "Sparsame Schmiedin",
		"desc": "Reward-Skip gibt +5 Gold mehr pro Stufe",
		"icon": "skip",
		"max_level": 2,
		"costs": [8, 20],
	},
	# Neue Upgrades
	"starter_extra_item": {
		"name": "Voll-Werkstatt",
		"desc": "+1 Starter-Item zufällig aus dem Pool zu Beginn",
		"icon": "extra_item",
		"max_level": 2,
		"costs": [18, 45],
	},
	"crit_chance": {
		"name": "Präzisions-Mechanik",
		"desc": "+3%-Punkte Crit-Chance pro Stufe (Basis 5%)",
		"icon": "crit",
		"max_level": 3,
		"costs": [10, 25, 50],
	},
	"elite_gold": {
		"name": "Elite-Beute",
		"desc": "+10 Gold pro Stufe nach Elite-Sieg",
		"icon": "elite_gold",
		"max_level": 2,
		"costs": [12, 28],
	},
	"event_luck": {
		"name": "Wanderer-Glück",
		"desc": "Event-Belohnungen +20% pro Stufe (Gold, HP, Items)",
		"icon": "luck",
		"max_level": 2,
		"costs": [10, 24],
	},
	"discovery_bonus": {
		"name": "Sammler-Auge",
		"desc": "+1 Kristall pro Stufe für neue Item-Entdeckungen",
		"icon": "discovery",
		"max_level": 2,
		"costs": [8, 20],
	},
	"shield_start": {
		"name": "Schutzlauf",
		"desc": "Start jedes Battles mit Stufe×15 Schild-Absorbtion",
		"icon": "shield",
		"max_level": 3,
		"costs": [12, 28, 60],
	},
	"boss_prep_heal": {
		"name": "Endkampf-Vorbereitung",
		"desc": "+10%-Punkte HP-Reserve direkt vor Boss-Kampf",
		"icon": "boss_heal",
		"max_level": 2,
		"costs": [14, 32],
	},
}

const DEFAULT_CHARACTERS: Array[String] = ["fire"]
const DEFAULT_ITEMS: Array[String] = [
	"pressure_hammer", "steam_kettle", "gear_sync", "relief_valve",
	"pressure_gauge", "repair_drone", "spark_spitter", "pendulum_strike",
	"cargo_lift", "forge_hearth", "combustion_chamber",
	"pressure_cannon", "boil_burst", "wind_mill", "spring_trap", "copper_coil",
	"storm_lance", "resonance_crystal", "iron_claw",
	"ice_drill", "vacuum_tube", "belt_drive", "shock_absorber", "resonance_hammer",
	"hydro_pump", "spinneret", "spark_magazine", "oil_canister", "head_lamp",
	"rotary_blade", "flintlock_pistol", "clockwork_bird", "piston_engine", "wrench_thrower",
	"gear_grinder", "flame_lance", "steam_whistle", "bellows_lung", "brass_telescope",
	"chronometer", "brass_horn", "siphon_pump", "iron_helm", "alchemist_flask",
	"firebomb", "ice_diffuser", "steel_aegis", "phosphor_lobber", "aegis_pump",
]

func _ready() -> void:
	load_state()

func load_state() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		_reset_to_defaults()
		save_state()
		return
	runs_attempted = cfg.get_value("stats", "runs_attempted", 0)
	runs_won = cfg.get_value("stats", "runs_won", 0)
	encounters_won_total = cfg.get_value("stats", "encounters_won_total", 0)
	bosses_defeated = cfg.get_value("stats", "bosses_defeated", 0)
	resonance_crystals = cfg.get_value("stats", "resonance_crystals", 0)
	max_heat_unlocked = cfg.get_value("stats", "max_heat_unlocked", 0)
	selected_heat = cfg.get_value("stats", "selected_heat", 0)
	var chars = cfg.get_value("unlocks", "characters", DEFAULT_CHARACTERS)
	characters_unlocked.clear()
	for c in chars:
		characters_unlocked.append(String(c))
	var items = cfg.get_value("unlocks", "items", DEFAULT_ITEMS)
	items_unlocked.clear()
	for i in items:
		items_unlocked.append(String(i))
	# Default-Charakter sicherstellen
	for default_char in DEFAULT_CHARACTERS:
		if default_char not in characters_unlocked:
			characters_unlocked.append(default_char)
	var loaded_daily = cfg.get_value("daily", "records", {})
	daily_records = loaded_daily if loaded_daily is Dictionary else {}
	var unlocked_ach = cfg.get_value("achievements", "unlocked", [])
	achievements.clear()
	for ach_id in unlocked_ach:
		achievements[String(ach_id)] = true
	var loaded_upgrades = cfg.get_value("workshop", "upgrades", {})
	workshop_upgrades.clear()
	if loaded_upgrades is Dictionary:
		for k in loaded_upgrades.keys():
			workshop_upgrades[String(k)] = int(loaded_upgrades[k])
	total_damage_dealt = cfg.get_value("stats", "total_damage_dealt", 0)
	total_damage_taken = cfg.get_value("stats", "total_damage_taken", 0)
	var loaded_placements = cfg.get_value("stats", "item_placements", {})
	item_placements = loaded_placements if loaded_placements is Dictionary else {}
	var loaded_purchases = cfg.get_value("stats", "item_purchases", {})
	item_purchases = loaded_purchases if loaded_purchases is Dictionary else {}
	var loaded_char_wins = cfg.get_value("stats", "character_wins", {})
	character_wins = loaded_char_wins if loaded_char_wins is Dictionary else {}
	var loaded_char_attempts = cfg.get_value("stats", "character_attempts", {})
	character_attempts = loaded_char_attempts if loaded_char_attempts is Dictionary else {}
	# Perks
	lifetime_crits = cfg.get_value("perks", "lifetime_crits", 0)
	lifetime_elites_defeated = cfg.get_value("perks", "lifetime_elites_defeated", 0)
	max_gold_in_run = cfg.get_value("perks", "max_gold_in_run", 0)
	heat3_wins = cfg.get_value("perks", "heat3_wins", 0)
	var loaded_bosses_per_id = cfg.get_value("perks", "bosses_per_id", {})
	bosses_defeated_per_id = loaded_bosses_per_id if loaded_bosses_per_id is Dictionary else {}
	var loaded_unlocked = cfg.get_value("perks", "unlocked", [])
	unlocked_perks.clear()
	for p in loaded_unlocked:
		unlocked_perks.append(String(p))
	var loaded_selected = cfg.get_value("perks", "selected", [])
	selected_perks.clear()
	for p in loaded_selected:
		selected_perks.append(String(p))
	var loaded_discovered = cfg.get_value("stats", "discovered_items", [])
	discovered_items.clear()
	for d in loaded_discovered:
		discovered_items.append(String(d))

func save_state() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("stats", "runs_attempted", runs_attempted)
	cfg.set_value("stats", "runs_won", runs_won)
	cfg.set_value("stats", "encounters_won_total", encounters_won_total)
	cfg.set_value("stats", "bosses_defeated", bosses_defeated)
	cfg.set_value("stats", "resonance_crystals", resonance_crystals)
	cfg.set_value("stats", "max_heat_unlocked", max_heat_unlocked)
	cfg.set_value("stats", "selected_heat", selected_heat)
	cfg.set_value("unlocks", "characters", characters_unlocked)
	cfg.set_value("unlocks", "items", items_unlocked)
	cfg.set_value("daily", "records", daily_records)
	cfg.set_value("achievements", "unlocked", achievements.keys())
	cfg.set_value("workshop", "upgrades", workshop_upgrades)
	cfg.set_value("stats", "total_damage_dealt", total_damage_dealt)
	cfg.set_value("stats", "total_damage_taken", total_damage_taken)
	cfg.set_value("stats", "item_placements", item_placements)
	cfg.set_value("stats", "item_purchases", item_purchases)
	cfg.set_value("stats", "character_wins", character_wins)
	cfg.set_value("stats", "character_attempts", character_attempts)
	cfg.set_value("stats", "discovered_items", discovered_items)
	cfg.set_value("perks", "lifetime_crits", lifetime_crits)
	cfg.set_value("perks", "lifetime_elites_defeated", lifetime_elites_defeated)
	cfg.set_value("perks", "max_gold_in_run", max_gold_in_run)
	cfg.set_value("perks", "heat3_wins", heat3_wins)
	cfg.set_value("perks", "bosses_per_id", bosses_defeated_per_id)
	cfg.set_value("perks", "unlocked", unlocked_perks)
	cfg.set_value("perks", "selected", selected_perks)
	cfg.save(SAVE_PATH)

# --- Stats- und Discovery-API ---

func track_damage_dealt(amount: int) -> void:
	total_damage_dealt += amount

func track_damage_taken(amount: int) -> void:
	total_damage_taken += amount

func track_item_placement(item_id: String) -> void:
	item_placements[item_id] = int(item_placements.get(item_id, 0)) + 1

func track_item_purchase(item_id: String) -> void:
	item_purchases[item_id] = int(item_purchases.get(item_id, 0)) + 1

func track_character_attempt(character_id: String) -> void:
	character_attempts[character_id] = int(character_attempts.get(character_id, 0)) + 1

func track_character_win(character_id: String) -> void:
	character_wins[character_id] = int(character_wins.get(character_id, 0)) + 1

# Discovery-Tracker: erstes Mal ein Item gesehen → +1 Kristall + Toast
signal item_discovered(item_id: String)

func try_discover_item(item_id: String) -> bool:
	if item_id in discovered_items:
		return false
	discovered_items.append(item_id)
	resonance_crystals += 1 + upgrade_level("discovery_bonus")
	item_discovered.emit(item_id)
	save_state()
	return true

# --- Perks-API ---

signal perk_unlocked(perk_id: String)

func has_perk(perk_id: String) -> bool:
	return perk_id in selected_perks

func perk_slots_available() -> int:
	# Slot 1 nach 1. Boss-Sieg, Slot 2 nach 3, Slot 3 nach 6.
	var c: int = 0
	if bosses_defeated >= 1: c += 1
	if bosses_defeated >= 3: c += 1
	if bosses_defeated >= 6: c += 1
	return c

func toggle_perk(perk_id: String) -> void:
	if perk_id in selected_perks:
		selected_perks.erase(perk_id)
	else:
		if selected_perks.size() >= perk_slots_available():
			# Aelteste Auswahl rausschmeissen
			selected_perks.pop_front()
		selected_perks.append(perk_id)
	save_state()

func check_perk_unlocks() -> Array[String]:
	# Wird am Ende jedes Runs aufgerufen — schaltet alle erfuellten Perks frei.
	var newly: Array[String] = []
	for perk_id in PERKS.keys():
		if perk_id in unlocked_perks:
			continue
		if _perk_condition_met(perk_id):
			unlocked_perks.append(perk_id)
			newly.append(perk_id)
			perk_unlocked.emit(perk_id)
	if newly.size() > 0:
		save_state()
	return newly

func _perk_condition_met(perk_id: String) -> bool:
	match perk_id:
		"notvorrat":
			return bosses_defeated >= 1
		"schnellfeuer":
			return int(character_wins.get("fire", 0)) >= 1
		"aetherantrieb":
			return discovered_items.size() >= 15
		"druckverwerter":
			return heat3_wins >= 1 and int(character_wins.get("pressure", 0)) >= 1
		"werkbank_mogul":
			# Alle 14 Upgrades mindestens Stufe 1
			var has_all: bool = true
			for up_id in WORKSHOP_UPGRADES.keys():
				if int(workshop_upgrades.get(up_id, 0)) < 1:
					has_all = false
					break
			return has_all
		"gluecksrad":
			return bosses_defeated >= 4
		"reaktiv_kette":
			return int(character_wins.get("reactive", 0)) >= 1
		"eisenhaut":
			return int(character_wins.get("blunt", 0)) >= 1
		"marktkenner":
			return max_gold_in_run >= 500
		"pluendererglueck":
			return lifetime_elites_defeated >= 5
		"kritstrom":
			return lifetime_crits >= 100
		"brand_stapel":
			return int(bosses_defeated_per_id.get("funken_tyrann", 0)) >= 1
		"zeitloser_mechanismus":
			return int(bosses_defeated_per_id.get("uhrwerk_hexe", 0)) >= 1
	return false

func track_crit() -> void:
	lifetime_crits += 1

func track_elite_defeat() -> void:
	lifetime_elites_defeated += 1

func track_boss_defeat(boss_id: String) -> void:
	bosses_defeated_per_id[boss_id] = int(bosses_defeated_per_id.get(boss_id, 0)) + 1

func track_gold_in_run(gold: int) -> void:
	if gold > max_gold_in_run:
		max_gold_in_run = gold

func track_heat3_win(heat: int) -> void:
	if heat >= 3:
		heat3_wins += 1

func most_placed_item() -> String:
	var top: String = ""
	var top_count: int = 0
	for k in item_placements.keys():
		var c: int = int(item_placements[k])
		if c > top_count:
			top_count = c
			top = String(k)
	return top

func favorite_character() -> String:
	var top: String = ""
	var top_count: int = 0
	for k in character_attempts.keys():
		var c: int = int(character_attempts[k])
		if c > top_count:
			top_count = c
			top = String(k)
	return top

func _reset_to_defaults() -> void:
	runs_attempted = 0
	runs_won = 0
	encounters_won_total = 0
	bosses_defeated = 0
	resonance_crystals = 0
	characters_unlocked = DEFAULT_CHARACTERS.duplicate()
	items_unlocked = DEFAULT_ITEMS.duplicate()
	last_run_unlocks.clear()
	last_run_crystals = 0

# --- Public API ---

func on_run_started() -> void:
	runs_attempted += 1
	last_run_unlocks.clear()
	last_run_crystals = 0
	track_character_attempt(RunState.current_character_id)
	# Kanonenmeister-Unlock auch bei Niederlage moeglich (5 Versuche)
	if runs_attempted >= 5:
		_try_unlock_character("gunner")
	save_state()

func on_encounter_won() -> void:
	encounters_won_total += 1
	resonance_crystals += 1
	last_run_crystals += 1
	# Unlock Druckmeister beim ersten Encounter-Sieg
	_try_unlock_character("pressure")
	evaluate_achievements_on_event("encounter_won")
	save_state()

func on_run_won() -> void:
	runs_won += 1
	bosses_defeated += 1
	track_character_win(RunState.current_character_id)
	resonance_crystals += 10 + selected_heat * 5
	last_run_crystals += 10 + selected_heat * 5
	# Boss-ID tracken fuer perk-spezifische Unlocks
	if RunState.pending_encounter_path != "":
		var enc: EncounterConfig = load(RunState.pending_encounter_path)
		if enc != null:
			track_boss_defeat(String(enc.id))
	# Heat-3-Win tracken
	track_heat3_win(selected_heat)
	# Max gold im Run tracken
	track_gold_in_run(RunState.gold)
	# Unlock Schmiedin nach 1. Boss-Sieg, Saboteur nach 3
	_try_unlock_character("blunt")
	if bosses_defeated >= 3:
		_try_unlock_character("reactive")
	# Kanonenmeister: 5 Run-Versuche (egal Sieg/Niederlage)
	if runs_attempted >= 5:
		_try_unlock_character("gunner")
	# Mastermind: Endboss mit 3 verschiedenen Charakteren besiegt
	var chars_with_win: int = 0
	for k in character_wins.keys():
		if int(character_wins[k]) >= 1:
			chars_with_win += 1
	if chars_with_win >= 3:
		_try_unlock_character("mastermind")
	# Heat freischalten: nach jedem Sieg auf der aktuellen Heat-Stufe wird die nächste verfügbar
	if selected_heat >= max_heat_unlocked and max_heat_unlocked < 10:
		max_heat_unlocked = selected_heat + 1
		last_run_unlocks.append("Heat %d freigeschaltet" % max_heat_unlocked)
		meta_changed.emit()
	evaluate_achievements_on_event("boss_defeated", {
		"hp_at_end": RunState.tower_hp,
		"max_hp": RunState.tower_max_hp,
	})
	save_state()

func set_heat(level: int) -> void:
	selected_heat = clamp(level, 0, max_heat_unlocked)
	save_state()

func _try_unlock_character(char_id: String) -> void:
	if char_id in characters_unlocked:
		return
	characters_unlocked.append(char_id)
	last_run_unlocks.append("Charakter: %s" % ALL_CHARACTERS[char_id]["name"])
	character_unlocked.emit(char_id)
	evaluate_achievements_on_event("character_unlocked")
	meta_changed.emit()

func is_character_unlocked(char_id: String) -> bool:
	return char_id in characters_unlocked

func is_item_unlocked(item_id: String) -> bool:
	return item_id in items_unlocked

func reset_progress() -> void:
	_reset_to_defaults()
	save_state()
	meta_changed.emit()

# --- Workshop API ---

func upgrade_level(id: String) -> int:
	return int(workshop_upgrades.get(id, 0))

func upgrade_max_level(id: String) -> int:
	var info: Dictionary = WORKSHOP_UPGRADES.get(id, {})
	return int(info.get("max_level", 0))

func upgrade_cost(id: String) -> int:
	# Kosten für die NÄCHSTE Stufe, -1 wenn schon max
	var level: int = upgrade_level(id)
	var info: Dictionary = WORKSHOP_UPGRADES.get(id, {})
	var costs: Array = info.get("costs", [])
	if level >= costs.size():
		return -1
	var base: int = int(costs[level])
	# Perk Werkbank-Mogul: -25% Upgrade-Kosten
	if has_perk("werkbank_mogul"):
		base = max(1, int(round(float(base) * 0.75)))
	return base

func can_buy_upgrade(id: String) -> bool:
	var cost: int = upgrade_cost(id)
	if cost < 0:
		return false
	return resonance_crystals >= cost

func buy_upgrade(id: String) -> bool:
	var cost: int = upgrade_cost(id)
	if cost < 0:
		return false
	if resonance_crystals < cost:
		return false
	resonance_crystals -= cost
	workshop_upgrades[String(id)] = upgrade_level(id) + 1
	save_state()
	meta_changed.emit()
	return true

# --- Daily Challenge ---

func current_daily_seed() -> int:
	var d: Dictionary = Time.get_date_dict_from_system(true)
	return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])

func current_daily_key() -> String:
	var d: Dictionary = Time.get_date_dict_from_system(true)
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]

func record_daily_score(encounters: int, won: bool) -> bool:
	var key: String = current_daily_key()
	var existing: int = int(daily_records.get(key, -1))
	var score: int = encounters + (100 if won else 0)
	if score > existing:
		daily_records[key] = score
		save_state()
		return true
	return false

func get_daily_score(date_key: String) -> int:
	return int(daily_records.get(date_key, -1))

# --- Achievements ---

func unlock_achievement(id: String) -> bool:
	if achievements.has(id):
		return false
	achievements[id] = true
	last_run_unlocks.append("Achievement: %s" % ALL_ACHIEVEMENTS.get(id, {}).get("name", id))
	achievement_unlocked.emit(id)
	save_state()
	return true

func has_achievement(id: String) -> bool:
	return achievements.has(id)

func evaluate_achievements_on_event(event_type: String, payload: Dictionary = {}) -> void:
	# Wird von Game-Events aufgerufen, prüft passende Achievements.
	match event_type:
		"encounter_won":
			if encounters_won_total >= 1:
				unlock_achievement("first_blood")
		"boss_defeated":
			unlock_achievement("first_boss")
			if bosses_defeated >= 3:
				unlock_achievement("three_bosses")
			if selected_heat >= 3:
				unlock_achievement("heat_3")
			if MetaState.is_daily_run:
				unlock_achievement("daily_win")
			if payload.get("hp_at_end", 0) >= payload.get("max_hp", 1):
				unlock_achievement("perfect_run")
		"character_unlocked":
			if characters_unlocked.size() >= ALL_CHARACTERS.size():
				unlock_achievement("all_chars")
		"shop_purchase":
			var count: int = int(payload.get("run_shop_purchases", 0))
			if count >= 5:
				unlock_achievement("shop_addict")
