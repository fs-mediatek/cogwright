class_name SlowEffect extends ItemEffect

# Verlangsamung: Gegner-Cooldowns laufen langsamer. 30% Slow = 30% mehr Zeit.

@export var slow_percent: float = 30.0
@export var duration_seconds: float = 3.0

func apply(battle, source_slot, _payload: Dictionary) -> void:
	battle.apply_slow_to_enemy(slow_percent, duration_seconds, source_slot)
