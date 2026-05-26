class_name ItemEffect extends Resource

enum TriggerHook {
	ON_COMBAT_START,
	ON_SELF_TRIGGER,
	ON_NEIGHBOR_TRIGGER,
	ON_FLOOR_ABOVE_TRIGGER,
	ON_FLOOR_BELOW_TRIGGER,
	ON_TAG_EVENT,
	ON_ENEMY_DAMAGED,
	ON_SELF_DAMAGED,
	ON_COMBAT_END,
}

@export var hook: TriggerHook = TriggerHook.ON_SELF_TRIGGER
@export var tag_filter: StringName = &""

func apply(_battle, _source_slot, _payload: Dictionary) -> void:
	push_warning("ItemEffect.apply() not overridden in %s" % resource_path)
