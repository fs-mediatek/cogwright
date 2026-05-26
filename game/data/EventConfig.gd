class_name EventConfig extends Resource

# Ein narratives Map-Event mit 2-3 Auswahl-Optionen, jede mit Outcome-Effekt.

@export var id: StringName = &""
@export var title: String = ""
@export_multiline var description: String = ""

# Choices als parallele Arrays — Godot-Resource-Inspector-freundlich.
@export var choice_labels: Array[String] = []
@export var choice_descriptions: Array[String] = []
# Outcome-Strings im Format "type:value", z.B. "heal:30", "damage:20", "gold:25", "gold:-10"
@export var choice_outcomes: Array[String] = []
