class_name MapGenerator extends RefCounted

# Map-Layout: Reihen von unten = 0 nach oben.
# Drei Run-Längen:
#   SHORT (4 Fights):  Start + 3 Combat-Reihen + Boss
#   NORMAL (5 Fights): Start + 4 Combat-Reihen + Boss
#   LONG (8 Fights):   Start + 7 Combat-Reihen + Boss
# Pro Run garantiert: 1-2 Shops, 1-2 Eliten (Boss-Anzahl skaliert auch).
# Optional: Heal-Knoten (max 1-2) und Event-Knoten (max 1-2).

enum RunLength { SHORT, NORMAL, LONG }

const ENCOUNTER_POOLS: Dictionary = {
	1: [
		"res://data/encounters/01_scout.tres",
		"res://data/encounters/01b_skirmisher.tres",
		"res://data/encounters/01c_drifter.tres",
		"res://data/encounters/01d_scrapwing.tres",
	],
	2: [
		"res://data/encounters/02_engineer.tres",
		"res://data/encounters/02b_outrider.tres",
		"res://data/encounters/02c_tinker.tres",
		"res://data/encounters/02d_lever_jack.tres",
	],
	3: [
		"res://data/encounters/03_brigand.tres",
		"res://data/encounters/03b_gunner.tres",
		"res://data/encounters/03c_warden.tres",
		"res://data/encounters/03d_brass_axiom.tres",
	],
	4: [
		"res://data/encounters/04_artisan.tres",
		"res://data/encounters/04b_chronopilot.tres",
		"res://data/encounters/04d_klink_marauder.tres",
	],
}
const BOSS_PATH: String = "res://data/encounters/05_warlord.tres"
const BOSS_POOL: Array[String] = [
	"res://data/encounters/05_warlord.tres",
	"res://data/encounters/boss_uhrwerk_hexe.tres",
	"res://data/encounters/boss_funken_tyrann.tres",
	"res://data/encounters/boss_stiller_maschinist.tres",
	"res://data/encounters/boss_oelbaron_krasnik.tres",
	"res://data/encounters/boss_schwarze_lokomotive.tres",
]

static func get_row_plan(length: int) -> Array:
	match length:
		RunLength.SHORT:
			return [
				{"row": 0, "type": MapNode.NodeType.START, "count": 1},
				{"row": 1, "type": MapNode.NodeType.COMBAT, "count": 5, "difficulty": 1, "may_event": true},
				{"row": 2, "type": MapNode.NodeType.COMBAT, "count": 5, "difficulty": 2, "may_heal": true, "may_shop": true},
				{"row": 3, "type": MapNode.NodeType.COMBAT, "count": 5, "difficulty": 3, "may_heal": true, "may_elite": true},
				{"row": 4, "type": MapNode.NodeType.BOSS, "count": 1},
			]
		RunLength.LONG:
			return [
				{"row": 0, "type": MapNode.NodeType.START, "count": 1},
				{"row": 1, "type": MapNode.NodeType.COMBAT, "count": 5, "difficulty": 1, "may_event": true},
				{"row": 2, "type": MapNode.NodeType.COMBAT, "count": 5, "difficulty": 1, "may_heal": true, "may_shop": true},
				{"row": 3, "type": MapNode.NodeType.COMBAT, "count": 5, "difficulty": 2, "may_event": true, "may_shop": true},
				{"row": 4, "type": MapNode.NodeType.COMBAT, "count": 5, "difficulty": 2, "may_elite": true, "may_heal": true},
				{"row": 5, "type": MapNode.NodeType.COMBAT, "count": 5, "difficulty": 3, "may_heal": true, "may_shop": true},
				{"row": 6, "type": MapNode.NodeType.COMBAT, "count": 5, "difficulty": 3, "may_event": true},
				{"row": 7, "type": MapNode.NodeType.COMBAT, "count": 5, "difficulty": 4, "may_elite": true},
				{"row": 8, "type": MapNode.NodeType.BOSS, "count": 1},
			]
		_:
			# NORMAL
			return [
				{"row": 0, "type": MapNode.NodeType.START, "count": 1},
				{"row": 1, "type": MapNode.NodeType.COMBAT, "count": 5, "difficulty": 1, "may_event": true},
				{"row": 2, "type": MapNode.NodeType.COMBAT, "count": 5, "difficulty": 2, "may_heal": true, "may_shop": true},
				{"row": 3, "type": MapNode.NodeType.COMBAT, "count": 5, "difficulty": 3, "may_heal": true, "may_shop": true, "may_event": true},
				{"row": 4, "type": MapNode.NodeType.COMBAT, "count": 5, "difficulty": 4, "may_elite": true},
				{"row": 5, "type": MapNode.NodeType.BOSS, "count": 1},
			]

static func total_fights_for(length: int) -> int:
	# Anzahl Kampf-Reihen + Boss
	var plan: Array = get_row_plan(length)
	var fights: int = 0
	for p in plan:
		if p["type"] == MapNode.NodeType.COMBAT or p["type"] == MapNode.NodeType.BOSS:
			fights += 1
	return fights

static func generate(seed_value: int, length: int = RunLength.NORMAL) -> RunMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var row_plan: Array = get_row_plan(length)
	# Limits skalieren mit Länge
	var max_shops: int = 1
	var max_heals: int = 1
	var max_events: int = 1
	var max_elites: int = 1
	var heal_chance: float = 0.65
	var event_chance: float = 0.55
	match length:
		RunLength.SHORT:
			max_shops = 1
			max_heals = 1
			max_events = 1
			max_elites = 1
			heal_chance = 0.55
			event_chance = 0.45
		RunLength.LONG:
			max_shops = 2
			max_heals = 2
			max_events = 2
			max_elites = 2
			heal_chance = 0.60
			event_chance = 0.50
	var map := RunMap.new()
	map.total_rows = row_plan.size()

	var next_id: int = 0
	var heals_placed: int = 0
	var shops_placed: int = 0
	var events_placed: int = 0
	var elites_placed: int = 0
	# Shops werden garantiert in N may_shop-Reihen platziert (per Zufall ausgewählt).
	var available_shop_rows: Array[int] = []
	for plan in row_plan:
		if plan.get("may_shop", false):
			available_shop_rows.append(plan["row"])
	available_shop_rows.shuffle()
	var forced_shop_rows: Array[int] = []
	for i in range(min(max_shops, available_shop_rows.size())):
		forced_shop_rows.append(available_shop_rows[i])

	for plan in row_plan:
		var count: int = plan["count"]
		var heal_slot: int = -1
		var shop_slot: int = -1
		var event_slot: int = -1
		var elite_slot: int = -1
		# Shop garantiert in den ausgewürfelten Reihen
		if plan.get("may_shop", false) and plan["row"] in forced_shop_rows and shops_placed < max_shops and count >= 2:
			shop_slot = rng.randi() % count
			shops_placed += 1
		# Heal: bis max_heals/Map, in einer Reihe die noch nicht Shop ist
		if plan.get("may_heal", false) and heals_placed < max_heals and count >= 2 and shop_slot == -1 and rng.randf() < heal_chance:
			heal_slot = rng.randi() % count
			heals_placed += 1
		# Event: bis max_events/Map, in Slot der nicht Shop/Heal ist
		if plan.get("may_event", false) and events_placed < max_events and count >= 2 and shop_slot == -1 and heal_slot == -1 and rng.randf() < event_chance:
			event_slot = rng.randi() % count
			events_placed += 1
		# Elite garantiert in may_elite-Reihen (bis max_elites)
		if plan.get("may_elite", false) and elites_placed < max_elites and count >= 2:
			elite_slot = rng.randi() % count
			elites_placed += 1

		for col in range(count):
			var node := MapNode.new()
			node.id = next_id
			next_id += 1
			node.type = plan["type"]
			node.row = plan["row"]
			node.column = col
			if col == shop_slot:
				node.type = MapNode.NodeType.SHOP
			elif col == heal_slot:
				node.type = MapNode.NodeType.HEAL
			elif col == event_slot:
				node.type = MapNode.NodeType.EVENT
			elif col == elite_slot:
				node.type = MapNode.NodeType.ELITE
			if node.type == MapNode.NodeType.COMBAT:
				var pool: Array = ENCOUNTER_POOLS[plan["difficulty"]]
				node.encounter_path = pool[rng.randi() % pool.size()]
			elif node.type == MapNode.NodeType.ELITE:
				var next_diff: int = plan["difficulty"] + 1
				if not ENCOUNTER_POOLS.has(next_diff):
					next_diff = plan["difficulty"]
				var elite_pool: Array = ENCOUNTER_POOLS[next_diff]
				node.encounter_path = elite_pool[rng.randi() % elite_pool.size()]
			elif node.type == MapNode.NodeType.BOSS:
				node.encounter_path = BOSS_POOL[rng.randi() % BOSS_POOL.size()]
			map.nodes.append(node)

	# Verbindungen — pro Knoten kommt eine Aligned-Kante zur passenden nächsten Spalte,
	# plus mit hoher Wahrscheinlichkeit Links- und Rechts-Nachbar-Edges.
	for n in map.nodes:
		var next_row_nodes: Array[MapNode] = map.get_nodes_in_row(n.row + 1)
		if next_row_nodes.is_empty():
			continue
		next_row_nodes.sort_custom(func(a, b): return a.column < b.column)
		if next_row_nodes.size() == 1:
			n.connections.append(next_row_nodes[0].id)
			continue
		var current_count: int = map.get_nodes_in_row(n.row).size()
		var target_idx: int = 0
		if current_count > 1:
			target_idx = int(round(float(n.column) / float(current_count - 1) * float(next_row_nodes.size() - 1)))
		# Aligned-Kante immer
		n.connections.append(next_row_nodes[target_idx].id)
		# Links-Diagonal: ~55%
		if target_idx > 0 and rng.randf() < 0.55:
			n.connections.append(next_row_nodes[target_idx - 1].id)
		# Rechts-Diagonal: ~55%
		if target_idx < next_row_nodes.size() - 1 and rng.randf() < 0.55:
			n.connections.append(next_row_nodes[target_idx + 1].id)

	# Orphans auflösen
	for row in range(1, row_plan.size()):
		var row_nodes: Array[MapNode] = map.get_nodes_in_row(row)
		for rn in row_nodes:
			var reachable: bool = false
			for prev in map.get_nodes_in_row(row - 1):
				if rn.id in prev.connections:
					reachable = true
					break
			if not reachable and not map.get_nodes_in_row(row - 1).is_empty():
				var prev_nodes: Array[MapNode] = map.get_nodes_in_row(row - 1)
				prev_nodes[rng.randi() % prev_nodes.size()].connections.append(rn.id)

	return map
