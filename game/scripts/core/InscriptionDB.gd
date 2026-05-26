extends Node

# Inschriften (Item-Veredelung): pro Item-Instanz max. eine Inschrift.
# Werden an Schmiede-/Graviermeister-Events vergeben und auf der Item-Instanz
# (Item.inscription) gespeichert. Wirkung wird im BattleController pro Treffer
# bzw. beim Cooldown-Vorlauf des jeweiligen Slots geprueft.

const INSCRIPTIONS: Dictionary = {
	"scharf": {
		"name": "Scharf",
		"desc": "+25% Schaden dieses Items.",
		"flavor": "Eine geschliffene Kante schneidet tiefer.",
		"damage_mult": 1.25,
		"cooldown_mult": 1.0,
		"crit_bonus": 0.0,
		"burn_mult": 1.0,
	},
	"wuchtig": {
		"name": "Wuchtig",
		"desc": "+45% Schaden, aber +30% laengerer Cooldown.",
		"flavor": "Schwer in der Hand, schwer fuer den Feind.",
		"damage_mult": 1.45,
		"cooldown_mult": 1.30,
		"crit_bonus": 0.0,
		"burn_mult": 1.0,
	},
	"flink": {
		"name": "Flink",
		"desc": "-20% Cooldown dieses Items.",
		"flavor": "Geoeltes Uhrwerk kennt keine Pause.",
		"damage_mult": 1.0,
		"cooldown_mult": 0.80,
		"crit_bonus": 0.0,
		"burn_mult": 1.0,
	},
	"gluehend": {
		"name": "Glühend",
		"desc": "Brand-Effekte dieses Items +75%.",
		"flavor": "Die Glut frisst sich durch jedes Metall.",
		"damage_mult": 1.0,
		"cooldown_mult": 1.0,
		"crit_bonus": 0.0,
		"burn_mult": 1.75,
	},
	"praezise": {
		"name": "Präzise",
		"desc": "+18% kritische Trefferchance dieses Items.",
		"flavor": "Wer ruhig zielt, trifft den Riss im Panzer.",
		"damage_mult": 1.0,
		"cooldown_mult": 1.0,
		"crit_bonus": 0.18,
		"burn_mult": 1.0,
	},
}

func get_inscription(id: String) -> Dictionary:
	return INSCRIPTIONS.get(id, {})

func inscription_name(id: String) -> String:
	if id == "":
		return ""
	return String(INSCRIPTIONS.get(id, {"name": id})["name"])

func inscription_desc(id: String) -> String:
	return String(INSCRIPTIONS.get(id, {"desc": ""}).get("desc", ""))

func damage_mult(id: StringName) -> float:
	return float(INSCRIPTIONS.get(String(id), {}).get("damage_mult", 1.0))

func cooldown_mult(id: StringName) -> float:
	return float(INSCRIPTIONS.get(String(id), {}).get("cooldown_mult", 1.0))

func crit_bonus(id: StringName) -> float:
	return float(INSCRIPTIONS.get(String(id), {}).get("crit_bonus", 0.0))

func burn_mult(id: StringName) -> float:
	return float(INSCRIPTIONS.get(String(id), {}).get("burn_mult", 1.0))

# Liefert eine zufaellige Auswahl an Inschrift-IDs (deterministisch per rng).
func random_choices(count: int, rng: RandomNumberGenerator) -> Array[String]:
	var pool: Array[String] = []
	for id in INSCRIPTIONS.keys():
		pool.append(id)
	for i in range(pool.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: String = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	return pool.slice(0, min(count, pool.size()))
