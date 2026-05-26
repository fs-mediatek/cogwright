class_name DealDamageEffect extends ItemEffect

@export var amount: int = 1

func apply(battle, source_slot, _payload: Dictionary) -> void:
	battle.deal_damage_to_enemy(amount, source_slot)
