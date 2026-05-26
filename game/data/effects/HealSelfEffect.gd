class_name HealSelfEffect extends ItemEffect

@export var amount: int = 8

func apply(battle, source_slot, _payload: Dictionary) -> void:
	battle.heal_active_tower(amount, source_slot)
