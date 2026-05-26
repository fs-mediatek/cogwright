class_name ChainEffect extends ItemEffect

# Chain: loest beim Trigger sofort die Reactive-Trigger der beiden Slot-Nachbarn aus
# (Kettenreaktion). Synergiert massiv mit [reactive]-Builds.

func apply(battle, source_slot, _payload: Dictionary) -> void:
	battle.chain_to_neighbors(source_slot)
