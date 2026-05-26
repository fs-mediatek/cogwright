class_name ShieldEffect extends ItemEffect

# Schild: absorbiert N Damage auf den eigenen Turm, läuft nach X Sekunden ab.

@export var shield_amount: int = 25
@export var duration_seconds: float = 6.0

func apply(battle, source_slot, _payload: Dictionary) -> void:
	battle.apply_shield_to_self(shield_amount, duration_seconds, source_slot)
