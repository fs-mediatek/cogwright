class_name BoostNeighborEffect extends ItemEffect

@export var cooldown_reduction_percent: float = 30.0
@export var duration_seconds: float = 4.0

func apply(battle, source_slot, _payload: Dictionary) -> void:
	for neighbor in battle.get_same_floor_neighbors(source_slot):
		battle.apply_temp_cooldown_modifier(neighbor, cooldown_reduction_percent, duration_seconds)
