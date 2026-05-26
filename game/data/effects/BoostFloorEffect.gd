class_name BoostFloorEffect extends ItemEffect

# Welche Etage relativ zum Source-Item geboostet wird.
# +1 = eine Etage höher, -1 = eine Etage tiefer.
@export var floor_offset: int = 1

@export var cooldown_reduction_percent: float = 25.0
@export var duration_seconds: float = 5.0

func apply(battle, source_slot, _payload: Dictionary) -> void:
	var target_floor: int = source_slot.floor_idx + floor_offset
	for s in battle.get_slots_on_floor(target_floor):
		battle.apply_temp_cooldown_modifier(s, cooldown_reduction_percent, duration_seconds)
