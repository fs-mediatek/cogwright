class_name ItemSlot extends RefCounted

var item: Item
var floor_idx: int
var slot_idx: int

# Restliche „Base-Sekunden" bis zum nächsten Trigger.
# Pro Tick werden delta * current_speed Sekunden verbraucht — Speed-Wechsel
# wirken dadurch sofort statt erst beim nächsten Reset.
var time_until_trigger: float

var temp_cd_modifier: float = 0.0
var temp_cd_remaining: float = 0.0

func _init(_item: Item, _floor_idx: int, _slot_idx: int) -> void:
	item = _item
	floor_idx = _floor_idx
	slot_idx = _slot_idx
	time_until_trigger = item.cooldown_seconds

func current_speed(floor_cooldown_modifier: float) -> float:
	var speed: float = 1.0 + floor_cooldown_modifier
	if temp_cd_remaining > 0.0:
		speed *= (1.0 + temp_cd_modifier / 100.0)
	if speed <= 0.01:
		speed = 0.01
	return speed

func advance(delta: float, floor_cooldown_modifier: float) -> bool:
	if temp_cd_remaining > 0.0:
		temp_cd_remaining = max(0.0, temp_cd_remaining - delta)
	time_until_trigger -= delta * current_speed(floor_cooldown_modifier)
	if time_until_trigger <= 0.0:
		time_until_trigger += item.cooldown_seconds
		return true
	return false

func reset() -> void:
	time_until_trigger = item.cooldown_seconds
	temp_cd_modifier = 0.0
	temp_cd_remaining = 0.0

func force_trigger_next_tick() -> void:
	# Setzt den Cooldown so, dass das Item beim nächsten advance() triggert.
	# Genutzt von aktiven Charakter-Fähigkeiten ("Funken-Wirbel", "Überdruck").
	time_until_trigger = 0.001
