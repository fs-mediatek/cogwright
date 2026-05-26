class_name MarkEffect extends ItemEffect

# Mark: markiert den Gegner. Markierte Tuerme nehmen +X% Schaden fuer die Dauer.
# Offensiver Verstaerker — synergiert mit Burst-Buildss.

@export var bonus_percent: float = 25.0
@export var duration_seconds: float = 4.0

func apply(battle, source_slot, _payload: Dictionary) -> void:
	battle.apply_mark_to_enemy(bonus_percent, duration_seconds, source_slot)
