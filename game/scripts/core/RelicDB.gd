extends Node

# Relikte: passive Run-Modifier (Slay-the-Spire-Stil).
# Gefunden in Bossen + bestimmten Events. Gelten den gesamten Run lang.
# Effekte werden an den relevanten Code-Stellen via RunState.has_relic("id") geprueft.

const RELICS: Dictionary = {
	"uhrwerk_herz": {
		"name": "Uhrwerk-Herz",
		"desc": "Jeder 5. Treffer eines Items ist ein garantierter kritischer Treffer.",
		"flavor": "Es schlaegt im Takt der Zahnraeder - und manchmal doppelt so hart.",
		"rarity": 2,
	},
	"brandstifter_kohle": {
		"name": "Brandstifter-Kohle",
		"desc": "Brand-Effekte richten +100% Schaden an.",
		"flavor": "Glueht nie aus, brennt nie nieder.",
		"rarity": 1,
	},
	"fundament_anker": {
		"name": "Fundament-Anker",
		"desc": "Items auf dem Fundament: +25% Schaden.",
		"flavor": "Was unten steht, traegt alles darueber.",
		"rarity": 1,
	},
	"druckspeicher": {
		"name": "Druckspeicher",
		"desc": "Start mit +60 maximaler Turm-HP.",
		"flavor": "Reserven fuer den langen Kampf.",
		"rarity": 1,
	},
	"zwillingszahnrad": {
		"name": "Zwillingszahnrad",
		"desc": "Reactive-Trigger feuern ein zusaetzliches Mal.",
		"flavor": "Ein Zahnrad dreht, das zweite folgt.",
		"rarity": 3,
	},
	"messing_kleeblatt": {
		"name": "Messing-Kleeblatt",
		"desc": "Item-Belohnungen zeigen +1 Option.",
		"flavor": "Vier Blaetter aus gehaemmertem Messing.",
		"rarity": 1,
	},
	"kuehlrippen": {
		"name": "Kühlrippen",
		"desc": "Alle Item-Cooldowns -10%.",
		"flavor": "Kuehler Kopf, schnellere Hand.",
		"rarity": 2,
	},
	"resonanzkern": {
		"name": "Resonanzkern",
		"desc": "Kritische Treffer machen x2.5 statt x2 Schaden.",
		"flavor": "Die richtige Frequenz zerbricht alles.",
		"rarity": 2,
	},
	"schmiedesegen": {
		"name": "Schmiede-Segen",
		"desc": "+15% Schaden, solange alle 9 Turm-Slots belegt sind.",
		"flavor": "Ein voller Turm ist ein gesegneter Turm.",
		"rarity": 2,
	},
	"notschild_generator": {
		"name": "Notschild-Generator",
		"desc": "Zu Kampfbeginn +25 Schild auf den eigenen Turm.",
		"flavor": "Der erste Schlag prallt immer ab.",
		"rarity": 1,
	},
}

func get_relic(id: String) -> Dictionary:
	return RELICS.get(id, {})

func relic_name(id: String) -> String:
	return String(RELICS.get(id, {"name": id})["name"])

# Liefert eine zufaellige Auswahl noch-nicht-besessener Relikte.
func random_unowned(owned: Array, count: int, rng: RandomNumberGenerator) -> Array[String]:
	var pool: Array[String] = []
	for id in RELICS.keys():
		if id not in owned:
			pool.append(id)
	# Fisher-Yates mit gegebenem RNG (deterministisch pro Run)
	for i in range(pool.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: String = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	return pool.slice(0, min(count, pool.size()))
