class_name TagBonusEffect extends ItemEffect

@export var bonus_tag: StringName = &""
@export var bonus_damage_percent: float = 10.0
@export var duration_seconds: float = 6.0

func apply(battle, _source_slot, _payload: Dictionary) -> void:
	battle.apply_tag_damage_bonus(bonus_tag, bonus_damage_percent, duration_seconds)
