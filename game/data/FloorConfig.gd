class_name FloorConfig extends Resource

@export var id: StringName = &""
@export var display_name: String = ""

@export_range(-1.0, 1.0, 0.01) var hp_modifier: float = 0.0
@export_range(-1.0, 1.0, 0.01) var cooldown_speed_modifier: float = 0.0
@export_range(-1.0, 1.0, 0.01) var damage_modifier: float = 0.0

@export var affinity_tags: Array[StringName] = []

@export var slot_count: int = 3
