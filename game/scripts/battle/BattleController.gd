class_name BattleController extends RefCounted

signal slot_triggered(tower, source_slot, hook)
signal damage_dealt(target_tower, source_tower, source_slot, amount)
signal tower_healed(tower, source_slot, amount)
signal tag_bonus_applied(tower, tag, bonus_percent, duration)
signal battle_ended(outcome)
signal status_changed(tower, status_type, value)   # für UI: burn/slow/shield wechselte
signal crit_dealt(target_tower, source_tower, source_slot, amount)

const TICK_HZ: int = 30
const TICK_DELTA: float = 1.0 / float(TICK_HZ)
const MAX_REENTRANCY_PER_SLOT_PER_TICK: int = 3
const MAX_TICKS_PER_BATTLE: int = 30000
const AFFINITY_BONUS: float = 0.15  # Item auf passender Etage: +15% Schaden
const BASE_CRIT_CHANCE: float = 0.05  # 5% Standard-Crit-Chance pro Treffer
const CRIT_MULTIPLIER: float = 2.0    # Crits doppelter Schaden

enum Outcome { ONGOING, ATTACKER_WIN, DEFENDER_WIN, TIMEOUT }

var attacker: Tower
var defender: Tower

var rng: DeterministicRng
var current_tick: int = 0
var outcome: Outcome = Outcome.ONGOING

var _reentrancy_count: Dictionary = {}
var _event_queue: Array[Dictionary] = []
var _log: Array[String] = []
# Boss-Phase: nur fuer Schwarze Lokomotive — wird bei HP<50% einmalig getriggert
var _boss_phase2_triggered: bool = false
# Perk Eisenhaut: einmaliges Schild-Trigger pro Battle bei HP<30%
var _eisenhaut_triggered: bool = false
# Relikt Uhrwerk-Herz: jeder 5. Player-Treffer ist garantierter Crit
var _player_hit_counter: int = 0

# Mini-Boss-Gimmick: Sonderverhalten des Gegner-Turms (von BattleView aus EncounterConfig gesetzt).
# Werte: "regenerator", "enrage", "reflect", "overclock" — leer = kein Gimmick.
var enemy_gimmick: StringName = &""
var enemy_gimmick_value: float = 0.0
var _gimmick_accumulator: float = 0.0   # sammelt Sekunden fuer intervallbasierte Gimmicks
var _enrage_bonus_pct: float = 0.0      # eskalierender Gegner-Schadensbonus (Gimmick "enrage")

signal boss_phase_changed(tower, phase: int)

# Tag-Damage-Bonus pro Tower: { tower: { tag: { "bonus": percent, "remaining": seconds } } }
var _tag_bonuses: Dictionary = {}

# Status-Effekte pro Tower
var _burn_stacks: Dictionary = {}  # tower -> Array of {dps, remaining, accumulator}
var _slow_state: Dictionary = {}   # tower -> {percent, remaining}
var _stun_state: Dictionary = {}   # tower -> remaining seconds (Item-CDs eingefroren)
var _mark_state: Dictionary = {}   # tower -> {percent, remaining} (nimmt +% Schaden)
var _shield_value: Dictionary = {} # tower -> {amount, remaining}

# Player-spezifische Mods (kommen aus RunState)
var player_character_id: String = ""   # gesetzt von BattleView vor start()
var player_tower: Tower                # Pointer auf den Spieler-Turm (für Character-Passive)
var set_bonuses: Dictionary = {}       # tower -> {tag: percent_bonus} permanent für ganzen Battle

# Damage-Tracking pro Player-Item (für Nachkampf-Auswertung)
# Key: Slot-Index 0..8 → {item_id, item_name, damage_total, trigger_count}
var _player_item_damage: Dictionary = {}

func _init(_attacker: Tower, _defender: Tower, seed_value: int) -> void:
	attacker = _attacker
	defender = _defender
	rng = DeterministicRng.new(seed_value)
	for s in attacker.slots + defender.slots:
		s.reset()
	# Perk Zeitloser Mechanismus: Player-Items triggern direkt im ersten Tick
	if MetaState.has_perk("zeitloser_mechanismus"):
		for s in attacker.slots:
			if s.item != null:
				s.time_until_trigger = 0.05

func get_log() -> Array[String]:
	return _log

func log_line(line: String) -> void:
	_log.append("[t=%05d] %s" % [current_tick, line])

func start() -> void:
	log_line("BATTLE START: %s (%d HP) vs %s (%d HP)" % [attacker.name, attacker.hp, defender.name, defender.hp])
	_compute_set_bonuses()
	_apply_meta_start_buffs()
	_fire_combat_start()

func _apply_meta_start_buffs() -> void:
	# Werkstatt-Upgrade "shield_start": Player startet Battle mit 15×Stufe Schild-Absorbtion
	if player_tower == null:
		return
	var shield_amount: int = MetaState.upgrade_level("shield_start") * 15
	# Relikt Notschild-Generator: +25 Schild zu Kampfbeginn
	if RunState.has_relic("notschild_generator"):
		shield_amount += 25
	if shield_amount > 0:
		_shield_value[player_tower] = {"amount": shield_amount, "remaining": 9999.0}
		log_line("META: %s startet mit %d Schild-Absorbtion" % [player_tower.name, shield_amount])
		status_changed.emit(player_tower, "shield", shield_amount)
	# Heat-Twist (Heat>=2): Gegner-Turm startet mit Schild
	var enemy: Tower = defender if player_tower == attacker else attacker
	if MetaState.selected_heat >= 2 and enemy != null:
		var enemy_shield: int = 20 + (MetaState.selected_heat - 2) * 10
		_shield_value[enemy] = {"amount": enemy_shield, "remaining": 9999.0}
		log_line("HEAT %d: %s startet mit %d Schild" % [MetaState.selected_heat, enemy.name, enemy_shield])
		status_changed.emit(enemy, "shield", enemy_shield)

func _compute_set_bonuses() -> void:
	# Pro Tower: Tag-Counts zählen, ab 3 gleichen Tags Set-Bonus aktiv.
	# Liste der bekannten Set-Boni (Tag → Bonus-Wert in % auf Items mit dem Tag)
	var SET_BONUS: Dictionary = {
		&"fire":      {"threshold": 3, "bonus": 20.0, "name": "Inferno"},
		&"mechanical":{"threshold": 3, "bonus": 15.0, "name": "Uhrwerk"},
		&"pressure":  {"threshold": 3, "bonus": 18.0, "name": "Hochdruck"},
		&"blunt":     {"threshold": 3, "bonus": 18.0, "name": "Wuchtschlag"},
		&"steam":     {"threshold": 3, "bonus": 15.0, "name": "Dampfdruck"},
		&"support":   {"threshold": 3, "bonus": 15.0, "name": "Werkstatt-Verbund"},
		&"precision": {"threshold": 3, "bonus": 18.0, "name": "Präzision"},
	}
	for tower in [attacker, defender]:
		var counts: Dictionary = {}
		for slot in tower.slots:
			for tag in slot.item.tags:
				counts[tag] = int(counts.get(tag, 0)) + 1
		var active: Dictionary = {}
		for tag in SET_BONUS.keys():
			var info: Dictionary = SET_BONUS[tag]
			if int(counts.get(tag, 0)) >= int(info["threshold"]):
				active[tag] = float(info["bonus"])
				log_line("SET-BONUS aktiv: %s — %s +%.0f%% Schaden" % [tower.name, info["name"], info["bonus"]])
		set_bonuses[tower] = active

func run() -> Outcome:
	start()
	while outcome == Outcome.ONGOING and current_tick < MAX_TICKS_PER_BATTLE:
		tick()
	if outcome == Outcome.ONGOING:
		outcome = Outcome.TIMEOUT
		log_line("BATTLE TIMEOUT after %d ticks" % current_tick)
	log_line("BATTLE END: %s | attacker_hp=%d defender_hp=%d" % [outcome_name(), attacker.hp, defender.hp])
	return outcome

func outcome_name() -> String:
	match outcome:
		Outcome.ATTACKER_WIN: return "ATTACKER_WIN"
		Outcome.DEFENDER_WIN: return "DEFENDER_WIN"
		Outcome.TIMEOUT: return "TIMEOUT"
		_: return "ONGOING"

func tick() -> void:
	current_tick += 1
	_reentrancy_count.clear()
	_advance_tag_bonuses(attacker)
	_advance_tag_bonuses(defender)
	_advance_status(attacker)
	_advance_status(defender)
	_advance_gimmick()
	_advance_tower(attacker, defender)
	if outcome != Outcome.ONGOING:
		return
	_advance_tower(defender, attacker)

func _advance_tower(tower: Tower, opponent: Tower) -> void:
	# Stun: Tower-Cooldowns sind eingefroren, keine Trigger.
	if _is_stunned(tower):
		return
	var slow_mod: float = _get_slow_modifier(tower)   # 0.0 = normal, 0.30 = 30% langsamer
	for slot in tower.slots:
		var floor_mod := _floor_cooldown_modifier(tower, slot.floor_idx)
		# Slow reduziert effektive Speed: floor_mod = (1 + floor_mod) * (1 - slow_mod) - 1
		var effective_mod: float = floor_mod - slow_mod * (1.0 + floor_mod)
		# Klassen-CD-Penalty (z.B. Kanonenmeister: [reactive] +20% CD)
		effective_mod -= _character_cd_penalty(tower, slot)
		# Perk Schnellfeuer: -15% CD auf [ranged]-Items (nur Player)
		if tower == player_tower and slot.item != null and slot.item.tags.has(&"ranged") and MetaState.has_perk("schnellfeuer"):
			effective_mod += 0.15
		# Relikt Kühlrippen: -10% CD auf alle Player-Items
		if tower == player_tower and slot.item != null and RunState.has_relic("kuehlrippen"):
			effective_mod += 0.10
		# Heat-Twist (Heat>=4): deine Item-Cooldowns +10% laenger
		if tower == player_tower and MetaState.selected_heat >= 4:
			effective_mod -= 0.10
		# Inschrift Flink/Wuchtig: Cooldown-Faktor dieses Items in Speed-Mod umrechnen
		if slot.item != null and String(slot.item.inscription) != "":
			var cd_mult: float = InscriptionDB.cooldown_mult(slot.item.inscription)
			if cd_mult > 0.0:
				effective_mod += (1.0 / cd_mult - 1.0)
		if slot.advance(TICK_DELTA, effective_mod):
			_enqueue_self_trigger(tower, opponent, slot)
	_drain_event_queue()
	_check_outcome()

func _check_boss_phase_transition(tower: Tower) -> void:
	# Schwarze Lokomotive: bei HP<50% einmalig „Volle Fahrt": -25% CD auf alle eigenen Slots
	# + dauerhafter [mechanical]+10% Damage-Buff
	if _boss_phase2_triggered or tower != defender:
		return
	if tower.name != "Schwarze Lokomotive Kraschnit":
		return
	if tower.max_hp <= 0:
		return
	var ratio: float = float(tower.hp) / float(tower.max_hp)
	if ratio >= 0.50:
		return
	_boss_phase2_triggered = true
	log_line("PHASE 2: Schwarze Lokomotive — Volle Fahrt! Alle Cooldowns -25%, [mechanical] +10% Schaden.")
	for slot in tower.slots:
		if slot.item != null:
			slot.temp_cd_modifier = 25.0
			slot.temp_cd_remaining = 9999.0
	if not _tag_bonuses.has(tower):
		_tag_bonuses[tower] = {}
	_tag_bonuses[tower][&"mechanical"] = {"bonus": 10.0, "remaining": 9999.0}
	boss_phase_changed.emit(tower, 2)

func _enemy_tower() -> Tower:
	# Der Nicht-Spieler-Turm. Fallback: defender (Player ist normalerweise attacker).
	if player_tower == null:
		return defender
	return defender if player_tower == attacker else attacker

func _advance_gimmick() -> void:
	# Mini-Boss-Gimmicks: zeit-/intervallbasiertes Sonderverhalten des Gegners.
	if String(enemy_gimmick) == "":
		return
	var enemy: Tower = _enemy_tower()
	if enemy == null or not enemy.is_alive():
		return
	match String(enemy_gimmick):
		"regenerator":
			# Heilt enemy_gimmick_value HP/Sekunde (per Tick anteilig).
			_gimmick_accumulator += TICK_DELTA
			if _gimmick_accumulator >= 1.0:
				_gimmick_accumulator -= 1.0
				var heal: int = max(1, int(round(enemy_gimmick_value)))
				enemy.hp = min(enemy.max_hp, enemy.hp + heal)
				log_line("GIMMICK Regenerator: %s heilt +%d HP (hp %d)" % [enemy.name, heal, enemy.hp])
				status_changed.emit(enemy, "heal", heal)
		"enrage":
			# Alle 5s dauerhaft +enemy_gimmick_value% Schaden (eskalierend).
			_gimmick_accumulator += TICK_DELTA
			if _gimmick_accumulator >= 5.0:
				_gimmick_accumulator -= 5.0
				_enrage_bonus_pct += enemy_gimmick_value
				log_line("GIMMICK Berserk: %s jetzt +%.0f%% Schaden" % [enemy.name, _enrage_bonus_pct])
		"overclock":
			# Alle 5s -5% Cooldown auf alle Gegner-Slots (eskalierend, additiv).
			_gimmick_accumulator += TICK_DELTA
			if _gimmick_accumulator >= 5.0:
				_gimmick_accumulator -= 5.0
				for slot in enemy.slots:
					if slot.item != null:
						slot.temp_cd_modifier += 5.0
						slot.temp_cd_remaining = 9999.0
				log_line("GIMMICK Uebertaktung: %s feuert schneller" % enemy.name)
		# "reflect" wirkt passiv in deal_damage_to_enemy, nicht hier.

func _check_eisenhaut_perk(tower: Tower) -> void:
	# Perk Eisenhaut: bei Player-HP<30% einmalig +30 Schild bis Battle-Ende
	if _eisenhaut_triggered or tower != player_tower:
		return
	if not MetaState.has_perk("eisenhaut"):
		return
	if tower.max_hp <= 0:
		return
	var ratio: float = float(tower.hp) / float(tower.max_hp)
	if ratio >= 0.30:
		return
	_eisenhaut_triggered = true
	if not _shield_value.has(tower):
		_shield_value[tower] = {"amount": 0, "remaining": 9999.0}
	_shield_value[tower]["amount"] = int(_shield_value[tower]["amount"]) + 30
	_shield_value[tower]["remaining"] = 9999.0
	log_line("  PERK Eisenhaut: +30 Schild (Player unter 30%% HP)")
	status_changed.emit(tower, "shield", _shield_value[tower]["amount"])

func _character_cd_penalty(tower: Tower, slot: ItemSlot) -> float:
	# CD-Penalty aus der Char-Passive — nur fuer den Player-Tower.
	if tower != player_tower or slot.item == null:
		return 0.0
	var passive: Dictionary = RunState.CHARACTER_PASSIVES.get(RunState.current_character_id, {})
	var penalty_tag: StringName = passive.get("cd_penalty_tag", &"")
	var penalty_amount: float = passive.get("cd_penalty_amount", 0.0)
	if penalty_tag == &"" or penalty_amount <= 0.0:
		return 0.0
	if slot.item.tags.has(penalty_tag):
		return penalty_amount
	return 0.0

func _enqueue_self_trigger(tower: Tower, opponent: Tower, slot: ItemSlot) -> void:
	_event_queue.append({
		"hook": ItemEffect.TriggerHook.ON_SELF_TRIGGER,
		"tower": tower,
		"opponent": opponent,
		"source_slot": slot,
		"payload": {},
	})

func _drain_event_queue() -> void:
	while _event_queue.size() > 0 and outcome == Outcome.ONGOING:
		var ev = _event_queue.pop_front()
		_process_event(ev)

func _process_event(ev: Dictionary) -> void:
	var slot: ItemSlot = ev["source_slot"]
	var slot_key := _slot_key(ev["tower"], slot)
	var count = _reentrancy_count.get(slot_key, 0)
	if count >= MAX_REENTRANCY_PER_SLOT_PER_TICK:
		log_line("REENTRANCY CAP: %s on %s" % [slot.item.display_name, ev["tower"].name])
		return
	_reentrancy_count[slot_key] = count + 1

	var tower: Tower = ev["tower"]
	var opponent: Tower = ev["opponent"]
	var hook: int = ev["hook"]

	if hook == ItemEffect.TriggerHook.ON_SELF_TRIGGER:
		log_line("FIRE: %s/%s (floor %d)" % [tower.name, slot.item.display_name, slot.floor_idx])
		slot_triggered.emit(tower, slot, hook)
		_dispatch_effects(slot, hook, ev["payload"], tower, opponent)
		_cascade_neighbor_triggers(tower, opponent, slot)
		_cascade_floor_triggers(tower, opponent, slot)
	else:
		slot_triggered.emit(tower, slot, hook)
		_dispatch_effects(slot, hook, ev["payload"], tower, opponent)

func _dispatch_effects(slot: ItemSlot, hook: int, payload: Dictionary, tower: Tower, opponent: Tower) -> void:
	_active_tower = tower
	_active_opponent = opponent
	for eff in slot.item.effects:
		if eff.hook != hook:
			continue
		if hook == ItemEffect.TriggerHook.ON_TAG_EVENT and eff.tag_filter != payload.get("tag", &""):
			continue
		eff.apply(self, slot, payload)
	_active_tower = null
	_active_opponent = null

func _cascade_neighbor_triggers(tower: Tower, opponent: Tower, source: ItemSlot) -> void:
	# Relikt Zwillingszahnrad: Reactive-Trigger feuern ein zusaetzliches Mal (Player)
	var repeat: int = 1
	if tower == player_tower and RunState.has_relic("zwillingszahnrad"):
		repeat = 2
	for s in tower.slots_on_floor(source.floor_idx):
		if s == source:
			continue
		if _has_hook(s.item, ItemEffect.TriggerHook.ON_NEIGHBOR_TRIGGER):
			for _r in range(repeat):
				_event_queue.append({
					"hook": ItemEffect.TriggerHook.ON_NEIGHBOR_TRIGGER,
					"tower": tower,
					"opponent": opponent,
					"source_slot": s,
					"payload": {"originator": source},
				})
	# Perk Reaktiv-Kette: zusaetzlich diagonal-Nachbarn auf den Etagen darueber/darunter
	if tower == player_tower and MetaState.has_perk("reaktiv_kette"):
		for offset in [-1, 1]:
			var diag_floor: int = source.floor_idx + offset
			if diag_floor < 0 or diag_floor >= tower.floors.size():
				continue
			for s in tower.slots_on_floor(diag_floor):
				if s.slot_idx == source.slot_idx:
					continue  # genau darueber/darunter ist nicht diagonal
				if _has_hook(s.item, ItemEffect.TriggerHook.ON_NEIGHBOR_TRIGGER):
					_event_queue.append({
						"hook": ItemEffect.TriggerHook.ON_NEIGHBOR_TRIGGER,
						"tower": tower,
						"opponent": opponent,
						"source_slot": s,
						"payload": {"originator": source},
					})

func _cascade_floor_triggers(tower: Tower, opponent: Tower, source: ItemSlot) -> void:
	for s in tower.slots:
		if s.floor_idx == source.floor_idx + 1 and _has_hook(s.item, ItemEffect.TriggerHook.ON_FLOOR_BELOW_TRIGGER):
			_event_queue.append({
				"hook": ItemEffect.TriggerHook.ON_FLOOR_BELOW_TRIGGER,
				"tower": tower,
				"opponent": opponent,
				"source_slot": s,
				"payload": {"originator": source},
			})
		if s.floor_idx == source.floor_idx - 1 and _has_hook(s.item, ItemEffect.TriggerHook.ON_FLOOR_ABOVE_TRIGGER):
			_event_queue.append({
				"hook": ItemEffect.TriggerHook.ON_FLOOR_ABOVE_TRIGGER,
				"tower": tower,
				"opponent": opponent,
				"source_slot": s,
				"payload": {"originator": source},
			})

func _fire_combat_start() -> void:
	for tower_pair in [[attacker, defender], [defender, attacker]]:
		for slot in tower_pair[0].slots:
			if _has_hook(slot.item, ItemEffect.TriggerHook.ON_COMBAT_START):
				_event_queue.append({
					"hook": ItemEffect.TriggerHook.ON_COMBAT_START,
					"tower": tower_pair[0],
					"opponent": tower_pair[1],
					"source_slot": slot,
					"payload": {},
				})
	_drain_event_queue()

func _has_hook(item: Item, hook: int) -> bool:
	for eff in item.effects:
		if eff.hook == hook:
			return true
	return false

func _floor_cooldown_modifier(tower: Tower, floor_idx: int) -> float:
	if floor_idx >= 0 and floor_idx < tower.floors.size():
		return tower.floors[floor_idx].cooldown_speed_modifier
	return 0.0

func _floor_damage_modifier(tower: Tower, floor_idx: int) -> float:
	if floor_idx >= 0 and floor_idx < tower.floors.size():
		return tower.floors[floor_idx].damage_modifier
	return 0.0

func _affinity_bonus_for_slot(tower: Tower, slot: ItemSlot) -> float:
	if slot.floor_idx < 0 or slot.floor_idx >= tower.floors.size():
		return 0.0
	var floor_id: StringName = tower.floors[slot.floor_idx].id
	if slot.item.floor_affinity.has(floor_id):
		return AFFINITY_BONUS
	return 0.0

func _slot_key(tower: Tower, slot: ItemSlot) -> String:
	return "%s::%d::%d" % [tower.name, slot.floor_idx, slot.slot_idx]

func _check_outcome() -> void:
	if not attacker.is_alive():
		outcome = Outcome.DEFENDER_WIN
	elif not defender.is_alive():
		outcome = Outcome.ATTACKER_WIN


# --- Public API used by ItemEffect implementations ---

var _active_tower: Tower
var _active_opponent: Tower

func deal_damage_to_enemy(amount: int, source_slot: ItemSlot) -> void:
	if _active_opponent == null:
		return
	var dmg_mod := _floor_damage_modifier(_active_tower, source_slot.floor_idx)
	var tag_bonus := _get_tag_bonus_for_item(_active_tower, source_slot.item)
	var affinity_bonus := _affinity_bonus_for_slot(_active_tower, source_slot)
	var set_bonus := _get_set_bonus_for_item(_active_tower, source_slot.item)
	var char_bonus := _get_character_bonus_for_item(_active_tower, source_slot.item)
	# Perk Druckverwerter: +20% Schaden auf [pressure]-Items (nur Player)
	var perk_dmg_bonus: float = 0.0
	if _active_tower == player_tower and MetaState.has_perk("druckverwerter") and source_slot.item.tags.has(&"pressure"):
		perk_dmg_bonus = 0.20
	# Relikt-Schadensboni (nur Player)
	var relic_dmg: float = 0.0
	if _active_tower == player_tower:
		if source_slot.floor_idx == 0 and RunState.has_relic("fundament_anker"):
			relic_dmg += 0.25
		if RunState.has_relic("schmiedesegen") and _is_tower_full(player_tower):
			relic_dmg += 0.15
	# Mark: markiertes Ziel nimmt zusaetzlichen Schaden
	var mark_bonus: float = _get_mark_bonus(_active_opponent) / 100.0
	# Gimmick Berserk: eskalierender Schadensbonus, nur fuer den Gegner-Turm
	var enrage_bonus: float = (_enrage_bonus_pct / 100.0) if _active_tower != player_tower else 0.0
	var multiplier: float = 1.0 + dmg_mod + (tag_bonus + set_bonus + char_bonus) / 100.0 + affinity_bonus + perk_dmg_bonus + relic_dmg + mark_bonus + enrage_bonus
	# Inschrift: multiplikativer Schadensfaktor dieses Items (1.0 wenn keine)
	var insc_dmg_mult: float = InscriptionDB.damage_mult(source_slot.item.inscription)
	# Event-Konsequenz (Segen/Fluch): globaler Run-Schadensfaktor (nur Player)
	var run_mult: float = RunState.run_damage_mult if _active_tower == player_tower else 1.0
	var final_damage: int = max(0, int(round(float(amount) * multiplier * insc_dmg_mult * run_mult)))
	# Crit-Roll — Werkstatt-Upgrade "crit_chance" addiert +3%-Punkte pro Stufe (nur Player)
	var crit_chance: float = BASE_CRIT_CHANCE
	var crit_mult: float = CRIT_MULTIPLIER
	var force_crit: bool = false
	# Inschrift Praezise: +Crit-Chance dieses Items
	crit_chance += InscriptionDB.crit_bonus(source_slot.item.inscription)
	if _active_tower == player_tower:
		crit_chance += float(MetaState.upgrade_level("crit_chance")) * 0.03
		# Perk Krit-Strom: +10% Chance, x2.5 Multiplikator
		if MetaState.has_perk("kritstrom"):
			crit_chance += 0.10
			crit_mult = 2.5
		# Relikt Resonanzkern: Crit-Multiplikator x2.5
		if RunState.has_relic("resonanzkern"):
			crit_mult = max(crit_mult, 2.5)
		# Relikt Uhrwerk-Herz: jeder 5. Player-Treffer = garantierter Crit
		if RunState.has_relic("uhrwerk_herz"):
			_player_hit_counter += 1
			if _player_hit_counter % 5 == 0:
				force_crit = true
	else:
		# Heat-Twist (Heat>=3): auch Gegner koennen kritische Treffer landen
		if MetaState.selected_heat >= 3:
			crit_chance = BASE_CRIT_CHANCE
	var is_crit: bool = false
	if force_crit or rng.randf() < crit_chance:
		final_damage = int(round(float(final_damage) * crit_mult))
		is_crit = true
	# Shield: erst Schild reduzieren, dann HP
	var dmg_to_hp: int = final_damage
	if _shield_value.has(_active_opponent):
		var shield_amt: int = int(_shield_value[_active_opponent]["amount"])
		if shield_amt > 0:
			var absorbed: int = min(shield_amt, dmg_to_hp)
			_shield_value[_active_opponent]["amount"] = shield_amt - absorbed
			dmg_to_hp -= absorbed
			log_line("  SHIELD absorbiert %d (rest: %d)" % [absorbed, _shield_value[_active_opponent]["amount"]])
			status_changed.emit(_active_opponent, "shield", _shield_value[_active_opponent]["amount"])
	if dmg_to_hp > 0:
		_active_opponent.take_damage(dmg_to_hp)
		_check_boss_phase_transition(_active_opponent)
		_check_eisenhaut_perk(_active_opponent)
		# Gimmick Dornen: Gegner reflektiert einen Teil des Schadens zurueck an den Player
		if String(enemy_gimmick) == "reflect" and _active_tower == player_tower and _active_opponent == _enemy_tower():
			var reflected: int = max(1, int(round(float(dmg_to_hp) * enemy_gimmick_value / 100.0)))
			player_tower.take_damage(reflected)
			log_line("  GIMMICK Dornen: %d Schaden reflektiert -> %s (hp %d)" % [reflected, player_tower.name, player_tower.hp])
	if is_crit:
		log_line("  CRIT: %s deals %d -> %s (hp now %d)" % [source_slot.item.display_name, final_damage, _active_opponent.name, _active_opponent.hp])
		crit_dealt.emit(_active_opponent, _active_tower, source_slot, final_damage)
		if _active_tower == player_tower:
			MetaState.track_crit()
	else:
		log_line("  DMG: %s deals %d -> %s (hp now %d)" % [source_slot.item.display_name, final_damage, _active_opponent.name, _active_opponent.hp])
	# Damage-Tracking: nur Player-Slots zählen für Nachkampf-Auswertung
	if _active_tower == player_tower and player_tower != null:
		var slot_key: int = source_slot.floor_idx * 3 + source_slot.slot_idx
		var entry: Dictionary = _player_item_damage.get(slot_key, {
			"item_id": String(source_slot.item.id),
			"item_name": source_slot.item.display_name,
			"icon": source_slot.item.icon,
			"damage_total": 0,
			"trigger_count": 0,
			"crits": 0,
		})
		entry["damage_total"] = int(entry["damage_total"]) + final_damage
		entry["trigger_count"] = int(entry["trigger_count"]) + 1
		if is_crit:
			entry["crits"] = int(entry["crits"]) + 1
		_player_item_damage[slot_key] = entry
	damage_dealt.emit(_active_opponent, _active_tower, source_slot, final_damage)

func get_player_damage_breakdown() -> Array[Dictionary]:
	# Sortierte Liste der Player-Items mit Damage-Total. Top zuerst.
	var result: Array[Dictionary] = []
	for k in _player_item_damage.keys():
		result.append(_player_item_damage[k])
	result.sort_custom(func(a, b): return int(a["damage_total"]) > int(b["damage_total"]))
	return result

func heal_active_tower(amount: int, source_slot: ItemSlot = null) -> void:
	if _active_tower == null:
		return
	# Affinity-Bonus auch fürs Heal — Reparatur-Drohne auf Werkstatt heilt mehr.
	var final_amount: int = amount
	if source_slot != null:
		var affinity_bonus := _affinity_bonus_for_slot(_active_tower, source_slot)
		final_amount = int(round(float(amount) * (1.0 + affinity_bonus)))
	var before: int = _active_tower.hp
	_active_tower.hp = min(_active_tower.max_hp, _active_tower.hp + final_amount)
	var healed: int = _active_tower.hp - before
	log_line("  HEAL: %s +%d hp (now %d/%d)" % [_active_tower.name, healed, _active_tower.hp, _active_tower.max_hp])
	tower_healed.emit(_active_tower, source_slot, healed)

func get_same_floor_neighbors(source: ItemSlot) -> Array[ItemSlot]:
	if _active_tower == null:
		var empty: Array[ItemSlot] = []
		return empty
	var result: Array[ItemSlot] = []
	for s in _active_tower.slots_on_floor(source.floor_idx):
		if s != source:
			result.append(s)
	return result

func get_slots_on_floor(floor_idx: int) -> Array[ItemSlot]:
	if _active_tower == null:
		var empty: Array[ItemSlot] = []
		return empty
	return _active_tower.slots_on_floor(floor_idx)

func apply_temp_cooldown_modifier(target: ItemSlot, percent: float, duration: float) -> void:
	target.temp_cd_modifier = percent
	target.temp_cd_remaining = duration
	log_line("  BUFF: %s -> +%.0f%% speed for %.1fs" % [target.item.display_name, percent, duration])

func apply_tag_damage_bonus(tag: StringName, bonus_percent: float, duration: float) -> void:
	if _active_tower == null:
		return
	if not _tag_bonuses.has(_active_tower):
		_tag_bonuses[_active_tower] = {}
	_tag_bonuses[_active_tower][tag] = {"bonus": bonus_percent, "remaining": duration}
	log_line("  TAG-BUFF: %s +%.0f%% dmg for [%s] (%.1fs)" % [_active_tower.name, bonus_percent, String(tag), duration])
	tag_bonus_applied.emit(_active_tower, tag, bonus_percent, duration)

func _advance_tag_bonuses(tower: Tower) -> void:
	if not _tag_bonuses.has(tower):
		return
	var entry: Dictionary = _tag_bonuses[tower]
	var to_remove: Array[StringName] = []
	for tag in entry.keys():
		entry[tag]["remaining"] -= TICK_DELTA
		if entry[tag]["remaining"] <= 0.0:
			to_remove.append(tag)
	for tag in to_remove:
		entry.erase(tag)

## Berechnet, welche Slot-Trigger in den nächsten `seconds` Sekunden zu erwarten sind.
## Read-only: verändert keinen Battle-State. Berücksichtigt Floor-Speed-Mod, ignoriert
## reaktive Cross-Effekte (Cooldown-Buffs durch Sync, Neighbor-Trigger). Für UI-Vorschau ausreichend.
func predict_upcoming_triggers(seconds: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for tower_pair in [[attacker, defender], [defender, attacker]]:
		var tower: Tower = tower_pair[0]
		for slot in tower.slots:
			if slot.item.cooldown_seconds >= 90.0:
				# Reaktive Items wie Druckventil triggern nicht von alleine
				continue
			var floor_mod := _floor_cooldown_modifier(tower, slot.floor_idx)
			var speed: float = 1.0 + floor_mod
			if speed <= 0.01:
				speed = 0.01
			var first_trigger_at: float = max(0.0, slot.time_until_trigger) / speed
			var cycle: float = slot.item.cooldown_seconds / speed
			var t: float = first_trigger_at
			while t <= seconds and cycle > 0.0:
				result.append({
					"time": t,
					"tower": tower,
					"slot": slot,
				})
				t += cycle
				if cycle < 0.05:
					break
	result.sort_custom(func(a, b): return a["time"] < b["time"])
	return result

func _get_tag_bonus_for_item(tower: Tower, item: Item) -> float:
	if not _tag_bonuses.has(tower):
		return 0.0
	var entry: Dictionary = _tag_bonuses[tower]
	var sum: float = 0.0
	for tag in item.tags:
		if entry.has(tag):
			sum += entry[tag]["bonus"]
	return sum

func _get_set_bonus_for_item(tower: Tower, item: Item) -> float:
	if not set_bonuses.has(tower):
		return 0.0
	var entry: Dictionary = set_bonuses[tower]
	var sum: float = 0.0
	for tag in item.tags:
		if entry.has(tag):
			sum += float(entry[tag])
	return sum

func _get_character_bonus_for_item(tower: Tower, item: Item) -> float:
	# Charakter-Passive nur für den Player-Tower
	if tower != player_tower or player_character_id == "":
		return 0.0
	var passive: Dictionary = RunState.CHARACTER_PASSIVES.get(player_character_id, {})
	var bonus: float = 0.0
	# Mastermind "Universalist": +X% pro einzigartigem Tag im Turm (gilt fuer alle Items)
	var diversity: float = float(passive.get("tag_diversity_bonus", 0.0))
	if diversity > 0.0:
		bonus += float(_unique_tag_count(tower)) * diversity * 100.0
	# Standard-Tag-Bonus (z.B. Pyrotechniker [fire] +10%)
	var pass_tag: StringName = passive.get("damage_tag", &"")
	var pass_bonus: float = float(passive.get("damage_bonus", 0.0))
	if pass_tag != &"" and pass_bonus > 0.0 and item.tags.has(pass_tag):
		bonus += pass_bonus * 100.0
	return bonus

func _unique_tag_count(tower: Tower) -> int:
	var seen: Dictionary = {}
	for slot in tower.slots:
		if slot.item != null:
			for t in slot.item.tags:
				seen[t] = true
	return seen.size()

func _is_tower_full(tower: Tower) -> bool:
	var filled: int = 0
	for slot in tower.slots:
		if slot.item != null:
			filled += 1
	return filled >= 9

# --- Status-Effekt-API ---

func apply_burn_to_enemy(dps: int, duration: float, _source_slot) -> void:
	if _active_opponent == null:
		return
	# Perk Brand-Stapel: 50% laengere Brand-Dauer
	if _active_tower == player_tower and MetaState.has_perk("brand_stapel"):
		duration *= 1.5
	# Relikt Brandstifter-Kohle: +100% Brand-Schaden (Player)
	if _active_tower == player_tower and RunState.has_relic("brandstifter_kohle"):
		dps = int(round(float(dps) * 2.0))
	# Inschrift Gluehend: +Brand-Schaden dieses Items
	if _source_slot != null and _source_slot.item != null:
		dps = int(round(float(dps) * InscriptionDB.burn_mult(_source_slot.item.inscription)))
	var stacks: Array = _burn_stacks.get(_active_opponent, [])
	stacks.append({"dps": dps, "remaining": duration, "accumulator": 0.0})
	_burn_stacks[_active_opponent] = stacks
	log_line("  BURN: %s -> %d DPS für %.1fs" % [_active_opponent.name, dps, duration])
	status_changed.emit(_active_opponent, "burn", dps)

func apply_slow_to_enemy(percent: float, duration: float, _source_slot) -> void:
	if _active_opponent == null:
		return
	var current: Dictionary = _slow_state.get(_active_opponent, {"percent": 0.0, "remaining": 0.0})
	# Stärkster Slow überschreibt schwächeren; gleicher Slow erneuert Dauer.
	if percent >= float(current.get("percent", 0.0)):
		current["percent"] = percent / 100.0
		current["remaining"] = duration
		_slow_state[_active_opponent] = current
		log_line("  SLOW: %s -> -%.0f%% Speed für %.1fs" % [_active_opponent.name, percent, duration])
		status_changed.emit(_active_opponent, "slow", percent)

func apply_shield_to_self(amount: int, duration: float, _source_slot) -> void:
	if _active_tower == null:
		return
	var current: Dictionary = _shield_value.get(_active_tower, {"amount": 0, "remaining": 0.0})
	# Stapeln
	current["amount"] = int(current.get("amount", 0)) + amount
	current["remaining"] = max(float(current.get("remaining", 0.0)), duration)
	_shield_value[_active_tower] = current
	log_line("  SHIELD: %s +%d Absorbtion (%.1fs)" % [_active_tower.name, amount, duration])
	status_changed.emit(_active_tower, "shield", current["amount"])

func apply_stun_to_enemy(duration: float, _source_slot) -> void:
	if _active_opponent == null:
		return
	var current: float = float(_stun_state.get(_active_opponent, 0.0))
	_stun_state[_active_opponent] = max(current, duration)
	log_line("  STUN: %s eingefroren fuer %.1fs" % [_active_opponent.name, duration])
	status_changed.emit(_active_opponent, "stun", int(round(duration * 10)))

func apply_mark_to_enemy(percent: float, duration: float, _source_slot) -> void:
	if _active_opponent == null:
		return
	var current: Dictionary = _mark_state.get(_active_opponent, {"percent": 0.0, "remaining": 0.0})
	if percent >= float(current.get("percent", 0.0)):
		current["percent"] = percent
		current["remaining"] = duration
		_mark_state[_active_opponent] = current
		log_line("  MARK: %s markiert (+%.0f%% Schaden, %.1fs)" % [_active_opponent.name, percent, duration])
		status_changed.emit(_active_opponent, "mark", int(percent))

func chain_to_neighbors(source_slot: ItemSlot) -> void:
	# Loest die Reactive-Trigger der Slot-Nachbarn auf derselben Etage aus.
	if _active_tower == null:
		return
	_cascade_neighbor_triggers(_active_tower, _active_opponent, source_slot)

func _is_stunned(tower: Tower) -> bool:
	return float(_stun_state.get(tower, 0.0)) > 0.0

func _get_mark_bonus(tower: Tower) -> float:
	if not _mark_state.has(tower):
		return 0.0
	return float(_mark_state[tower].get("percent", 0.0))

func _get_slow_modifier(tower: Tower) -> float:
	if not _slow_state.has(tower):
		return 0.0
	return float(_slow_state[tower].get("percent", 0.0))

func _advance_status(tower: Tower) -> void:
	# Burn: pro Tick Schaden anteilig akkumulieren, bei vollem Damage-Wert anwenden.
	if _burn_stacks.has(tower):
		var stacks: Array = _burn_stacks[tower]
		var still_active: Array = []
		for stack in stacks:
			stack["remaining"] = float(stack["remaining"]) - TICK_DELTA
			stack["accumulator"] = float(stack["accumulator"]) + float(stack["dps"]) * TICK_DELTA
			# Wenn akkumulierter Schaden >= 1, anwenden
			if float(stack["accumulator"]) >= 1.0:
				var burn_dmg: int = int(floor(float(stack["accumulator"])))
				stack["accumulator"] = float(stack["accumulator"]) - float(burn_dmg)
				_apply_raw_damage(tower, burn_dmg)
				log_line("  BURN-TICK: %s nimmt %d Brandschaden (hp %d)" % [tower.name, burn_dmg, tower.hp])
			if float(stack["remaining"]) > 0.0:
				still_active.append(stack)
		_burn_stacks[tower] = still_active
		if still_active.is_empty():
			status_changed.emit(tower, "burn", 0)
	# Slow
	if _slow_state.has(tower):
		_slow_state[tower]["remaining"] = float(_slow_state[tower]["remaining"]) - TICK_DELTA
		if float(_slow_state[tower]["remaining"]) <= 0.0:
			_slow_state.erase(tower)
			status_changed.emit(tower, "slow", 0)
	# Stun
	if _stun_state.has(tower):
		_stun_state[tower] = float(_stun_state[tower]) - TICK_DELTA
		if float(_stun_state[tower]) <= 0.0:
			_stun_state.erase(tower)
			status_changed.emit(tower, "stun", 0)
	# Mark
	if _mark_state.has(tower):
		_mark_state[tower]["remaining"] = float(_mark_state[tower]["remaining"]) - TICK_DELTA
		if float(_mark_state[tower]["remaining"]) <= 0.0:
			_mark_state.erase(tower)
			status_changed.emit(tower, "mark", 0)
	# Shield
	if _shield_value.has(tower):
		_shield_value[tower]["remaining"] = float(_shield_value[tower]["remaining"]) - TICK_DELTA
		if float(_shield_value[tower]["remaining"]) <= 0.0 or int(_shield_value[tower]["amount"]) <= 0:
			_shield_value.erase(tower)
			status_changed.emit(tower, "shield", 0)

func _apply_raw_damage(target_tower: Tower, amount: int) -> void:
	# Wird von Burn-Ticks genutzt: respektiert Shield, kein Crit-Roll, kein Tag-Modifier.
	if _shield_value.has(target_tower):
		var shield_amt: int = int(_shield_value[target_tower]["amount"])
		if shield_amt > 0:
			var absorbed: int = min(shield_amt, amount)
			_shield_value[target_tower]["amount"] = shield_amt - absorbed
			amount -= absorbed
			if amount <= 0:
				return
	target_tower.take_damage(amount)

# Status-Getter für UI
func get_burn_total(tower: Tower) -> int:
	if not _burn_stacks.has(tower):
		return 0
	var total: int = 0
	for stack in _burn_stacks[tower]:
		total += int(stack["dps"])
	return total

func get_slow_percent(tower: Tower) -> float:
	if not _slow_state.has(tower):
		return 0.0
	return float(_slow_state[tower]["percent"]) * 100.0

func get_shield_amount(tower: Tower) -> int:
	if not _shield_value.has(tower):
		return 0
	return int(_shield_value[tower]["amount"])

func get_stun_remaining(tower: Tower) -> float:
	return float(_stun_state.get(tower, 0.0))

func get_mark_percent(tower: Tower) -> float:
	if not _mark_state.has(tower):
		return 0.0
	return float(_mark_state[tower].get("percent", 0.0))

# Aktive Fähigkeit: Charakter-Action triggern
func trigger_active_ability(ability_id: String) -> bool:
	if _active_tower == null:
		_active_tower = player_tower
		_active_opponent = (defender if player_tower == attacker else attacker)
	match ability_id:
		"spark_swirl":
			# Alle fire-Items des Spielers feuern sofort
			for slot in player_tower.slots:
				if slot.item.tags.has(&"fire"):
					slot.force_trigger_next_tick()
			log_line("ABILITY: Funken-Wirbel — alle [fire]-Items triggern")
		"overpressure":
			# Alle Items feuern sofort
			for slot in player_tower.slots:
				slot.force_trigger_next_tick()
			log_line("ABILITY: Überdruck — alle Items triggern")
		"emergency_repair":
			var before: int = player_tower.hp
			player_tower.hp = min(player_tower.max_hp, player_tower.hp + 50)
			var healed: int = player_tower.hp - before
			log_line("ABILITY: Notfall-Reparatur — +%d HP (now %d)" % [healed, player_tower.hp])
			tower_healed.emit(player_tower, null, healed)
		"sabotage":
			var enemy: Tower = (defender if player_tower == attacker else attacker)
			_active_opponent = enemy
			apply_slow_to_enemy(40.0, 5.0, null)
			apply_burn_to_enemy(4, 5.0, null)
			log_line("ABILITY: Sabotage — Gegner verlangsamt + Brand")
		_:
			return false
	return true
