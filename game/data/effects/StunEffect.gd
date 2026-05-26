class_name StunEffect extends ItemEffect

# Stun: friert die Item-Cooldowns des Gegners fuer X Sekunden ein.
# Stark defensiv — der Gegner-Turm feuert in der Zeit gar nicht.

@export var duration_seconds: float = 1.5

func apply(battle, source_slot, _payload: Dictionary) -> void:
	battle.apply_stun_to_enemy(duration_seconds, source_slot)
