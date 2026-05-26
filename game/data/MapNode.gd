class_name MapNode extends Resource

enum NodeType {
	START,
	COMBAT,
	ELITE,
	BOSS,
	SHOP,
	EVENT,
	HEAL,
}

@export var id: int = 0
@export var type: NodeType = NodeType.COMBAT
@export var row: int = 0
@export var column: int = 0   # horizontale Position innerhalb der Reihe (0..n)
@export var encounter_path: String = ""   # nur für COMBAT/ELITE/BOSS
@export var connections: Array[int] = []   # IDs der erreichbaren nächsten Knoten
@export var completed: bool = false

func type_label() -> String:
	match type:
		NodeType.START: return "Start"
		NodeType.COMBAT: return "Kampf"
		NodeType.ELITE: return "Elite"
		NodeType.BOSS: return "Boss"
		NodeType.SHOP: return "Werkstatt"
		NodeType.EVENT: return "Begegnung"
		NodeType.HEAL: return "Reparatur"
		_: return "?"
