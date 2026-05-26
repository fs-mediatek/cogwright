class_name BurnEffect extends ItemEffect

# Brand: Damage-over-Time auf Gegner. Stackt mit anderen Burn-Quellen.

@export var damage_per_second: int = 3
@export var duration_seconds: float = 4.0

func apply(battle, source_slot, _payload: Dictionary) -> void:
	battle.apply_burn_to_enemy(damage_per_second, duration_seconds, source_slot)
