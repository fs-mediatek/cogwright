class_name BattleView extends Control

const SPEED_OPTIONS: Array[float] = [0.5, 1.0, 2.0, 4.0]
const ENCOUNTER_PATHS: Array[String] = [
	"res://data/encounters/01_scout.tres",
	"res://data/encounters/02_engineer.tres",
	"res://data/encounters/03_brigand.tres",
	"res://data/encounters/04_artisan.tres",
	"res://data/encounters/05_warlord.tres",
]
const POST_BATTLE_DELAY: float = 1.5

# Mini-Boss-Gimmick → Anzeige-Text fuer die Status-Zeile.
const GIMMICK_LABELS: Dictionary = {
	"regenerator": "⚙ Regenerator — repariert sich selbst",
	"enrage": "⚙ Berserk — wird mit der Zeit staerker",
	"reflect": "⚙ Dornen — reflektiert Schaden",
	"overclock": "⚙ Uebertaktung — feuert immer schneller",
}

const DAMAGE_FLOAT_COLOR: Color = Color(1.0, 0.55, 0.35)
const CRIT_FLOAT_COLOR: Color = Color(1.0, 0.92, 0.35)
const HEAL_FLOAT_COLOR: Color = Color(0.45, 0.95, 0.50)
const COMBO_FLOAT_COLOR: Color = Color(1.0, 0.78, 0.45)
const COMBO_TICK_WINDOW: int = 1   # selber Tick
const PLAYER_TINT: Color = Color(0.45, 0.85, 0.95)
const RIVAL_TINT: Color = Color(0.95, 0.55, 0.45)
const PROJECTILE_SCENE := preload("res://scripts/view/Projectile.gd")

var _battle: BattleController
var _accumulator: float = 0.0
var _speed: float = 1.0
var _paused: bool = false
var _battle_done: bool = false
var _last_log_count: int = 0
var _shake_remaining: float = 0.0
var _shake_intensity: float = 0.0
var _layout_base_offset: Vector2 = Vector2.ZERO
# Combo-Tracking: sammelt Player-Damage in einem Tick und spawnt Combo-Floater
var _combo_tick: int = -1
var _combo_count: int = 0
var _combo_damage: int = 0
var _combo_target: Variant = null

@onready var _player_view: TowerView = $Layout/Arena/PlayerTower
@onready var _rival_view: TowerView = $Layout/Arena/RivalTower
@onready var _timeline: TimelineStrip = $Layout/Timeline
@onready var _log_label: RichTextLabel = $Layout/LogContainer/LogText
@onready var _status_label: Label = $Layout/Header/StatusLabel
@onready var _tick_label: Label = $Layout/Header/TickLabel
@onready var _speed_label: Label = $Layout/Footer/SpeedLabel
@onready var _restart_button: Button = $Layout/Footer/RestartButton
@onready var _pause_button: Button = $Layout/Footer/PauseButton
@onready var _speed_button: Button = $Layout/Footer/SpeedButton
@onready var _floats_layer: Control = $FloatsLayer
@onready var _projectiles_layer: Node2D = $ProjectilesLayer

func _ready() -> void:
	if not RunState.is_run_active or RunState.pending_encounter_path == "":
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	# Echte Layout-Position erfassen, damit Shake-Reset nicht nach (0,0) snappt
	_layout_base_offset = $Layout.position
	_restart_button.text = "Hauptmenü"
	_restart_button.pressed.connect(_on_restart_pressed)
	_pause_button.pressed.connect(_toggle_pause)
	_speed_button.pressed.connect(_cycle_speed)
	# Persistente Speed übernehmen
	var saved_speed: float = SettingsState.battle_speed
	if saved_speed in SPEED_OPTIONS:
		_speed = saved_speed
	# Perk Aetherantrieb: Default-Speed mind. x2
	if MetaState.has_perk("aetherantrieb") and _speed < 2.0:
		_speed = 2.0
	AudioManager.set_battle_speed(_speed)
	_update_speed_label()
	_pick_and_play_battle_music()
	_apply_boss_backdrop()
	_start_battle()

func _apply_boss_backdrop() -> void:
	# Wenn aktueller Map-Knoten ein Boss ist, Backdrop-Palette anpassen.
	if RunState.current_map == null:
		return
	var cn: MapNode = RunState.current_map.current_node()
	if cn == null or cn.type != MapNode.NodeType.BOSS:
		return
	var enc: EncounterConfig = load(cn.encounter_path)
	if enc == null:
		return
	var backdrop: Node = get_node_or_null("Backdrop")
	if backdrop != null and backdrop.has_method("set_palette_for_boss"):
		backdrop.set_palette_for_boss(String(enc.id))
	if RunState.is_coop:
		CoopManager.transition_committed.connect(_on_coop_transition)
	HintOverlay.show_if_new(self, "first_battle",
		"Erste Schlacht",
		"Items feuern automatisch auf ihren Cooldowns. Du musst nichts klicken — schau zu, wie dein Turm arbeitet.\n\n[b]Tipp:[/b] Mit dem Speed-Knopf rechts kannst du die Geschwindigkeit hochziehen, um schnell zu sehen, wie dein Build performt.")

func _start_battle() -> void:
	# Werkstatt-Upgrade "boss_prep_heal": Vor Boss-Kampf +10%-Punkte Max-HP pro Stufe heilen
	if RunState.current_map != null:
		var pre_cn: MapNode = RunState.current_map.current_node()
		if pre_cn != null and pre_cn.type == MapNode.NodeType.BOSS:
			var prep_lvl: int = MetaState.upgrade_level("boss_prep_heal")
			if prep_lvl > 0:
				var bonus_heal: int = int(round(float(RunState.tower_max_hp) * 0.10 * float(prep_lvl)))
				RunState.tower_hp = min(RunState.tower_max_hp, RunState.tower_hp + bonus_heal)
	var player := RunState.build_player_tower()
	# Vom MapView gesetzt; Fallback auf altes lineares System falls leer
	var encounter_path: String = RunState.pending_encounter_path
	if encounter_path == "":
		encounter_path = ENCOUNTER_PATHS[RunState.current_encounter_idx]
	var encounter: EncounterConfig = load(encounter_path)
	var rival: Tower = encounter.build_tower()
	var battle_seed: int = RunState.run_seed + RunState.current_encounter_idx * 1000
	_battle = BattleController.new(player, rival, battle_seed)
	_battle.player_tower = player
	_battle.player_character_id = RunState.current_character_id
	_battle.enemy_gimmick = encounter.gimmick
	_battle.enemy_gimmick_value = encounter.gimmick_value
	_battle.damage_dealt.connect(_on_damage_dealt)
	_battle.tower_healed.connect(_on_tower_healed)
	_battle.slot_triggered.connect(_on_slot_triggered)
	_battle.crit_dealt.connect(_on_crit_dealt)
	_player_view.bind(player, _battle)
	_rival_view.bind(rival, _battle)
	_player_view.refresh()
	_rival_view.refresh()
	_timeline.bind(_battle)
	_battle.start()
	_log_label.clear()
	_last_log_count = 0
	_accumulator = 0.0
	_paused = false
	_battle_done = false
	_status_label.text = "Encounter %d/%d — %s" % [RunState.current_encounter_idx + 1, RunState.total_encounters, encounter.display_name]
	if String(encounter.gimmick) != "" and GIMMICK_LABELS.has(String(encounter.gimmick)):
		_status_label.text += "   ·   " + GIMMICK_LABELS[String(encounter.gimmick)]
	_pause_button.text = "Pause"
	# Vorhandene Floating Numbers + Projectiles aufräumen
	for c in _floats_layer.get_children():
		c.queue_free()
	for c in _projectiles_layer.get_children():
		c.queue_free()
	_flush_log()

func _toggle_pause() -> void:
	if _battle_done:
		return
	_paused = not _paused
	_pause_button.text = "Weiter" if _paused else "Pause"

func _cycle_speed() -> void:
	var idx: int = SPEED_OPTIONS.find(_speed)
	if idx == -1:
		idx = 1
	idx = (idx + 1) % SPEED_OPTIONS.size()
	_speed = SPEED_OPTIONS[idx]
	# Persistieren + Audio anpassen
	SettingsState.battle_speed = _speed
	SettingsState.save_settings()
	AudioManager.set_battle_speed(_speed)
	_update_speed_label()

func _update_speed_label() -> void:
	_speed_label.text = "Speed ×%.1f" % _speed

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				_toggle_pause()
				get_viewport().set_input_as_handled()
			KEY_F:
				_cycle_speed()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				_on_restart_pressed()
				get_viewport().set_input_as_handled()
			KEY_Q:
				_trigger_active_ability()
				get_viewport().set_input_as_handled()

func _trigger_active_ability() -> void:
	if _battle == null or _battle_done:
		return
	if RunState.active_ability_used:
		return
	var passive: Dictionary = RunState.CHARACTER_PASSIVES.get(RunState.current_character_id, {})
	var ability_id: String = String(passive.get("ability", ""))
	if ability_id == "":
		return
	if _battle.trigger_active_ability(ability_id):
		RunState.active_ability_used = true
		AudioManager.sfx("buff", -2.0)
		_trigger_shake(6.0, 0.20)

func _track_combo(target_tower, amount: int) -> void:
	if _battle == null:
		return
	var current_tick: int = _battle.current_tick
	if current_tick != _combo_tick or _combo_target != target_tower:
		_flush_combo()
		_combo_tick = current_tick
		_combo_target = target_tower
		_combo_count = 1
		_combo_damage = amount
		return
	_combo_count += 1
	_combo_damage += amount

func _flush_combo() -> void:
	if _combo_count >= 3 and _combo_target != null:
		var view: TowerView = _player_view if _combo_target == _battle.attacker else _rival_view
		var pos: Vector2 = _global_center_of(view) - Vector2(80, 40)
		_spawn_float("COMBO x%d  -%d" % [_combo_count, _combo_damage], COMBO_FLOAT_COLOR, pos, false, true)
	_combo_count = 0
	_combo_damage = 0
	_combo_target = null
	_combo_tick = -1

func _on_crit_dealt(target_tower, _source, _slot, amount) -> void:
	AudioManager.sfx("impact_heavy", -2.0)
	AudioManager.sting("crit_ring", -3.0)
	_trigger_shake(8.0, 0.22)
	# Großer goldener CRIT-Floater zusätzlich zum Standard-Damage-Floater
	var view: TowerView = _player_view if target_tower == _battle.attacker else _rival_view
	var pos: Vector2 = _global_center_of(view) - Vector2(0, 24)
	_spawn_float("CRIT! -%d" % amount, CRIT_FLOAT_COLOR, pos, true, false)

func _process(delta: float) -> void:
	_update_shake(delta)
	if _battle == null or _battle_done or _paused:
		return
	_accumulator += delta * _speed
	while _accumulator >= BattleController.TICK_DELTA and not _battle_done:
		_accumulator -= BattleController.TICK_DELTA
		_advance_one_tick()
		# Tick-Wechsel: Combo aus dem vorherigen Tick auswerten + zuruecksetzen
		if _combo_tick != _battle.current_tick:
			_flush_combo()
	_player_view.refresh()
	_rival_view.refresh()
	_tick_label.text = "Tick %d" % _battle.current_tick
	_update_tension_ambient()

func _update_tension_ambient() -> void:
	# Wechselt auf "tension"-Drone wenn Player-HP < 30%, zurueck zu "battle" ueber 40%.
	if _battle == null or _battle.attacker == null or _battle.attacker.max_hp <= 0:
		return
	var ratio: float = float(_battle.attacker.hp) / float(_battle.attacker.max_hp)
	if ratio < 0.30:
		AudioManager.play_ambient("tension", -16.0)
	elif ratio > 0.40:
		AudioManager.play_ambient("battle", -22.0)

func _update_shake(delta: float) -> void:
	if _shake_remaining <= 0.0:
		return
	_shake_remaining -= delta
	if _shake_remaining <= 0.0:
		$Layout.position = _layout_base_offset
		return
	# Random offset, schwächer werdend
	var t: float = _shake_remaining
	var amp: float = _shake_intensity * t
	$Layout.position = _layout_base_offset + Vector2(randf_range(-amp, amp), randf_range(-amp, amp))

func _trigger_shake(intensity: float, duration: float) -> void:
	if duration > _shake_remaining:
		_shake_remaining = duration
	if intensity > _shake_intensity:
		_shake_intensity = intensity

func _advance_one_tick() -> void:
	_battle.tick()
	_flush_log()
	if _battle.outcome != BattleController.Outcome.ONGOING:
		_battle_done = true
		_battle.log_line("BATTLE END: %s | attacker_hp=%d defender_hp=%d" % [_battle.outcome_name(), _battle.attacker.hp, _battle.defender.hp])
		_status_label.text = "Beendet: %s" % _battle.outcome_name()
		_flush_log()
		await get_tree().create_timer(POST_BATTLE_DELAY).timeout
		_handle_battle_end()

func _handle_battle_end() -> void:
	if RunState.is_coop:
		_status_label.text = "Battle beendet — warte auf Mitspieler…"
		CoopManager.propose_transition("battle:done")
	else:
		_do_battle_end_transition()

func _do_battle_end_transition() -> void:
	# HP des Spielers in den Run-State zurückspielen
	RunState.tower_hp = _battle.attacker.hp
	# Battle-Log + Outcome für Auswertung persistieren
	RunState.last_battle_log = _battle.get_log().duplicate()
	RunState.last_battle_outcome = _battle.outcome_name()
	RunState.last_encounter_name = _battle.defender.name
	RunState.last_battle_damage_breakdown = _battle.get_player_damage_breakdown()
	# Telemetrie: optional Battle-Log an Discord-Webhook senden
	_send_telemetry_if_enabled()
	# War das der Boss?
	var was_boss: bool = false
	if RunState.current_map != null:
		var cn: MapNode = RunState.current_map.current_node()
		if cn != null and cn.type == MapNode.NodeType.BOSS:
			was_boss = true
	if _battle.outcome == BattleController.Outcome.ATTACKER_WIN:
		var healed: int = RunState.advance_encounter()
		RunState.last_auto_heal = healed
		# Pre-Boss: nach Elite-Sieg voll heilen (klassische Roguelike-Mechanik)
		var was_elite: bool = false
		if RunState.current_map != null:
			var cn2: MapNode = RunState.current_map.current_node()
			if cn2 != null and cn2.type == MapNode.NodeType.ELITE:
				was_elite = true
		if was_elite:
			var before_pb: int = RunState.tower_hp
			RunState.tower_hp = RunState.tower_max_hp
			RunState.last_auto_heal = max(RunState.last_auto_heal, RunState.tower_hp - before_pb)
		# Aktuellen Knoten als abgeschlossen markieren, pending leeren
		if RunState.current_map != null:
			RunState.current_map.mark_current_completed()
		RunState.pending_encounter_path = ""
		if was_boss:
			if MetaState.is_daily_run:
				MetaState.record_daily_score(RunState.encounters_won, true)
				_post_daily_leaderboard(true)
			RunState.end_run(true)
			get_tree().change_scene_to_file("res://scenes/RunComplete.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/ItemReward.tscn")
	else:
		if MetaState.is_daily_run:
			MetaState.record_daily_score(RunState.encounters_won, false)
			_post_daily_leaderboard(false)
		RunState.end_run(false)
		get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func _on_coop_transition(key: String) -> void:
	if key == "battle:done":
		_do_battle_end_transition()

func _on_restart_pressed() -> void:
	RunState.end_run(false)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _pick_and_play_battle_music() -> void:
	# Pool-basiert mit Pitch-Variation als poor-mans-variants, falls keine
	# dedicated Tracks fuer Elite/Boss vorhanden sind.
	var path: String = "res://assets/audio/music/battle_robotic_city.ogg"
	var pitch: float = 1.0
	var vol: float = -16.0
	if RunState.current_map != null:
		var cn: MapNode = RunState.current_map.current_node()
		if cn != null:
			if cn.type == MapNode.NodeType.BOSS:
				var boss_path: String = "res://assets/audio/music/battle_boss.ogg"
				if ResourceLoader.exists(boss_path):
					path = boss_path
				else:
					pitch = 0.88
					vol = -14.0
			elif cn.type == MapNode.NodeType.ELITE:
				var elite_path: String = "res://assets/audio/music/battle_elite.ogg"
				if ResourceLoader.exists(elite_path):
					path = elite_path
				else:
					pitch = 0.94
					vol = -15.0
	AudioManager.play_music(path, vol, pitch)
	# A3 v2 ist ein subtiler Drone (kein Burst-Pattern) — sehr leise drunter mischen.
	AudioManager.play_ambient("battle", -22.0)

func _exit_tree() -> void:
	# Sounds aus diesem Battle stoppen, bevor die nächste Szene anfängt
	AudioManager.stop_all_sfx()

func _post_daily_leaderboard(victory: bool) -> void:
	if not TelemetryClient.is_active():
		return
	var char_id: String = RunState.current_character_id
	var char_name: String = String(MetaState.ALL_CHARACTERS.get(char_id, {"name": char_id})["name"])
	var score: int = RunState.encounters_won * 10 + MetaState.selected_heat * 5 + (100 if victory else 0)
	TelemetryClient.send_daily_score({
		"alias": SettingsState.player_alias,
		"score": score,
		"date_key": MetaState.current_daily_key(),
		"character": char_name,
		"heat": MetaState.selected_heat,
		"encounters_won": RunState.encounters_won,
		"victory": victory,
	})

func _send_telemetry_if_enabled() -> void:
	if not TelemetryClient.is_active():
		return
	var is_victory: bool = _battle.outcome == BattleController.Outcome.ATTACKER_WIN
	if SettingsState.telemetry_only_on_loss and is_victory:
		return
	# Charakter-Anzeige aus ALL_CHARACTERS
	var char_id: String = RunState.current_character_id
	var char_name: String = String(MetaState.ALL_CHARACTERS.get(char_id, {"name": char_id})["name"])
	# Aktive Perks
	var perks_display: Array[String] = []
	for pid in MetaState.selected_perks:
		var pinfo: Dictionary = MetaState.PERKS.get(pid, {})
		perks_display.append(String(pinfo.get("name", pid)))
	# Tower-Layout textuell pro Etage
	var layout_lines: Array[String] = []
	for floor_idx in range(2, -1, -1):
		var floor_name: String = RunState.floors[floor_idx].display_name if floor_idx < RunState.floors.size() else "?"
		var slot_names: Array[String] = []
		for slot_idx in range(3):
			var idx: int = floor_idx * 3 + slot_idx
			var item: Item = RunState.tower_layout[idx] if idx < RunState.tower_layout.size() else null
			slot_names.append(item.display_name if item != null else "—")
		layout_lines.append("%s: %s" % [floor_name, ", ".join(slot_names)])
	# Log-Auszug: letzte N Zeilen
	var full_log: Array = _battle.get_log()
	var tail: Array = full_log.slice(max(0, full_log.size() - TelemetryClient.MAX_LOG_LINES), full_log.size())
	TelemetryClient.send_battle_log({
		"victory": is_victory,
		"outcome": _battle.outcome_name(),
		"character": char_name,
		"heat": MetaState.selected_heat,
		"encounter_name": _battle.defender.name,
		"player_hp_end": _battle.attacker.hp,
		"player_max_hp": _battle.attacker.max_hp,
		"perks": perks_display,
		"tower_layout_text": "\n".join(layout_lines),
		"log_excerpt": "\n".join(tail),
	})

# --- Signal Handlers ---

func _on_slot_triggered(tower, source_slot, hook) -> void:
	var view: TowerView = _player_view if tower == _battle.attacker else _rival_view
	view.flash_slot(source_slot)
	# Nur den primären Self-Trigger sound abspielen, sonst werden Neighbor-Reaktionen zu laut.
	if hook == ItemEffect.TriggerHook.ON_SELF_TRIGGER:
		AudioManager.play_item_sound(source_slot.item)

func _on_damage_dealt(target_tower, source_tower, source_slot, amount: int) -> void:
	# Stats-Tracking: nur Player-Daten
	if source_tower == _battle.attacker:
		MetaState.track_damage_dealt(amount)
		_track_combo(target_tower, amount)
	if target_tower == _battle.attacker:
		MetaState.track_damage_taken(amount)
	var target_view: TowerView = _player_view if target_tower == _battle.attacker else _rival_view
	var source_view: TowerView = _player_view if source_tower == _battle.attacker else _rival_view
	var slot_view: ItemSlotView = source_view.get_slot_view(source_slot)
	var from_pos: Vector2
	if slot_view != null:
		var r := slot_view.get_global_rect()
		from_pos = r.position + r.size * 0.5
	else:
		from_pos = source_view.get_global_center()
	var to_pos: Vector2 = target_view.get_global_center()
	_spawn_projectile(from_pos, to_pos, source_slot.item.icon, _tint_for_tower(source_tower), target_view, amount)

func _spawn_projectile(from_global: Vector2, to_global: Vector2, icon: Texture2D, tint: Color, target_view: TowerView, damage: int) -> void:
	var proj: Projectile = Projectile.new()
	_projectiles_layer.add_child(proj)
	# Convert global → projectiles_layer local
	var inv := _projectiles_layer.get_global_transform().affine_inverse()
	var from_local: Vector2 = inv * from_global
	var to_local: Vector2 = inv * to_global
	proj.launch(from_local, to_local, icon, tint, _speed)
	proj.impacted.connect(_on_projectile_impact.bind(target_view, damage))

func _on_projectile_impact(target_view: TowerView, damage: int) -> void:
	var pos: Vector2 = _global_center_of(target_view)
	_spawn_float("-%d" % damage, DAMAGE_FLOAT_COLOR, pos)
	# Impact-Sound je nach Schadenshöhe
	var sound_name: String = "impact_light"
	if damage >= 20:
		sound_name = "impact_heavy"
	elif damage >= 10:
		sound_name = "impact_medium"
	AudioManager.sfx(sound_name, -8.0)
	# Screen-Shake bei schweren Treffern auf den Player-Tower (per Setting deaktivierbar)
	if target_view == _player_view and SettingsState.screen_shake_enabled:
		if damage >= 20:
			_trigger_shake(10.0, 0.30)
		elif damage >= 10:
			_trigger_shake(5.0, 0.18)
	# Flash auf der getroffenen TowerView
	if target_view.has_method("flash_damage"):
		target_view.flash_damage(damage)

func _tint_for_tower(tower) -> Color:
	return PLAYER_TINT if tower == _battle.attacker else RIVAL_TINT

func _on_tower_healed(tower, _source_slot, amount: int) -> void:
	if amount <= 0:
		return
	var view: TowerView = _player_view if tower == _battle.attacker else _rival_view
	var pos: Vector2 = _global_center_of(view)
	_spawn_float("+%d" % amount, HEAL_FLOAT_COLOR, pos)
	AudioManager.sfx("heal", -4.0)

func _global_center_of(node: Control) -> Vector2:
	var rect := node.get_global_rect()
	# Spawn-Position oberhalb der Tower-Mitte
	return Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + 60.0)

func _spawn_float(text: String, color: Color, global_pos: Vector2, is_crit: bool = false, is_combo: bool = false) -> void:
	var fn := Label.new()
	fn.set_script(load("res://scripts/view/FloatingNumber.gd"))
	_floats_layer.add_child(fn)
	var local_pos: Vector2 = _floats_layer.get_global_transform().affine_inverse() * global_pos
	fn.show_text(text, color, local_pos, is_crit, is_combo)

func _flush_log() -> void:
	var log := _battle.get_log()
	for i in range(_last_log_count, log.size()):
		_log_label.append_text(log[i] + "\n")
	_last_log_count = log.size()

