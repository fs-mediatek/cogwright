extends Node

const BASE_HP: int = 200
const BATTLE_SEED: int = 1337

func _ready() -> void:
	print("=== Cogwright MVP Battle Test ===\n")
	var attacker := _build_player_tower()
	var defender := _build_rival_tower()
	_print_tower_setup(attacker)
	_print_tower_setup(defender)
	print("")
	var battle := BattleController.new(attacker, defender, BATTLE_SEED)
	battle.run()
	for line in battle.get_log():
		print(line)
	print("\n=== Test done. Quit in 1s. ===")
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()

func _build_player_tower() -> Tower:
	# „Pressure Build" — synergistische Maschinerie um den Druck-Tag.
	# Fundament: Lasten-Aufzug (boostet Werkstatt) + Druckhammer
	# Werkstatt: Pendel-Schlag + Druckmesser + Reparatur-Drohne
	# Spitze:    Funkenspeier + Druckventil
	var t := Tower.new()
	t.name = "Player"
	t.floors = _load_floors()
	t.max_hp = _compute_max_hp(BASE_HP, t.floors)
	t.hp = t.max_hp
	t.add_slot(_load_item("cargo_lift"), 0, 0)
	t.add_slot(_load_item("pressure_hammer"), 0, 1)
	t.add_slot(_load_item("pendulum_strike"), 1, 0)
	t.add_slot(_load_item("pressure_gauge"), 1, 1)
	t.add_slot(_load_item("repair_drone"), 1, 2)
	t.add_slot(_load_item("spark_spitter"), 2, 0)
	t.add_slot(_load_item("relief_valve"), 2, 1)
	return t

func _build_rival_tower() -> Tower:
	# „Brute Force Build" — mehr Rohschaden, keine Synergien.
	# Fundament: Schmiede-Esse + Druckhammer
	# Werkstatt: Pendel-Schlag + Dampfkessel + Dampfkessel
	# Spitze:    Funkenspeier + Funkenspeier
	var t := Tower.new()
	t.name = "Rival"
	t.floors = _load_floors()
	t.max_hp = _compute_max_hp(BASE_HP, t.floors)
	t.hp = t.max_hp
	t.add_slot(_load_item("forge_hearth"), 0, 0)
	t.add_slot(_load_item("pressure_hammer"), 0, 1)
	t.add_slot(_load_item("pendulum_strike"), 1, 0)
	t.add_slot(_load_item("steam_kettle"), 1, 1)
	t.add_slot(_load_item("steam_kettle"), 1, 2)
	t.add_slot(_load_item("spark_spitter"), 2, 0)
	t.add_slot(_load_item("spark_spitter"), 2, 1)
	return t

func _load_item(id: String) -> Item:
	return load("res://data/items/%s.tres" % id)

func _load_floors() -> Array[FloorConfig]:
	var floors: Array[FloorConfig] = []
	floors.append(load("res://data/floors/foundation.tres"))
	floors.append(load("res://data/floors/workshop.tres"))
	floors.append(load("res://data/floors/pinnacle.tres"))
	return floors

func _compute_max_hp(base: int, floors: Array[FloorConfig]) -> int:
	var total: float = float(base)
	for f in floors:
		total += float(base) * f.hp_modifier
	return int(round(total))

func _print_tower_setup(t: Tower) -> void:
	print("%s (HP %d):" % [t.name, t.max_hp])
	for floor_idx in range(t.floors.size() - 1, -1, -1):
		var floor_name: String = t.floors[floor_idx].display_name
		var items: Array[String] = []
		for s in t.slots_on_floor(floor_idx):
			items.append(s.item.display_name)
		var label: String = ", ".join(items) if items.size() > 0 else "(leer)"
		print("  [%s]  %s" % [floor_name, label])
