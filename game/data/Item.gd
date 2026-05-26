class_name Item extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_multiline var flavor_text: String = ""

@export var rarity: Rarity = Rarity.COMMON
@export var tags: Array[StringName] = []
@export var floor_affinity: Array[StringName] = []

@export_range(0.1, 30.0, 0.1) var cooldown_seconds: float = 2.0

@export var effects: Array[ItemEffect] = []

@export var icon: Texture2D

const _RARITY_LABEL: Dictionary = {
	0: "Gewöhnlich",
	1: "Ungewöhnlich",
	2: "Selten",
	3: "Legendär",
}

const _FLOOR_LABEL: Dictionary = {
	&"foundation": "Fundament",
	&"workshop": "Werkstatt",
	&"pinnacle": "Observatorium",
}

func tooltip_text() -> String:
	# Einheitlicher Hover-Tooltip — überall im Spiel auf Item-Anzeigen einsetzbar.
	var lines: PackedStringArray = PackedStringArray()
	lines.append("%s  ·  %s" % [display_name, _RARITY_LABEL.get(int(rarity), "?")])
	if tags.size() > 0:
		var tag_strs: PackedStringArray = PackedStringArray()
		for t in tags:
			tag_strs.append("[%s]" % String(t))
		lines.append("  ".join(tag_strs))
	lines.append("")
	lines.append("Cooldown: %.1fs" % cooldown_seconds)
	if floor_affinity.size() > 0:
		var floor_strs: PackedStringArray = PackedStringArray()
		for f in floor_affinity:
			floor_strs.append(String(_FLOOR_LABEL.get(f, String(f))))
		lines.append("Beste Etage: %s (+15%%)" % ", ".join(floor_strs))
	if effects.size() > 0:
		lines.append("")
		lines.append("Wirkung:")
		for e in effects:
			var l: String = _effect_line(e)
			if l != "":
				lines.append("  " + l)
	if description != "":
		lines.append("")
		lines.append(description)
	if flavor_text != "":
		lines.append("")
		lines.append("» " + flavor_text + " «")
	return "\n".join(lines)

func _effect_line(e: ItemEffect) -> String:
	if e == null:
		return ""
	var hook_tag: String = "[Reaktiv] " if int(e.hook) == 2 else "[Trigger] "
	var body: String = ""
	if e is DealDamageEffect:
		body = "%d Schaden" % (e as DealDamageEffect).amount
	elif e is BurnEffect:
		var b: BurnEffect = e as BurnEffect
		body = "Brand: %d/s · %.1fs" % [b.damage_per_second, b.duration_seconds]
	elif e is HealSelfEffect:
		body = "Heilung: +%d HP" % (e as HealSelfEffect).amount
	elif e is TagBonusEffect:
		var t: TagBonusEffect = e as TagBonusEffect
		body = "[%s] +%.0f%% Schaden für %.1fs" % [String(t.bonus_tag), t.bonus_damage_percent, t.duration_seconds]
	elif e is ShieldEffect:
		var sh: ShieldEffect = e as ShieldEffect
		body = "Schild: %d HP für %.1fs" % [sh.shield_amount, sh.duration_seconds]
	elif e is SlowEffect:
		var sl: SlowEffect = e as SlowEffect
		body = "Slow: -%.0f%% Speed für %.1fs" % [sl.slow_percent, sl.duration_seconds]
	elif e is BoostNeighborEffect:
		var n: BoostNeighborEffect = e as BoostNeighborEffect
		body = "Nachbar-CD -%.0f%% für %.1fs" % [n.cooldown_reduction_percent, n.duration_seconds]
	elif e is BoostFloorEffect:
		var f: BoostFloorEffect = e as BoostFloorEffect
		var dir_label: String = "Etage darüber" if f.floor_offset > 0 else "Etage darunter"
		body = "%s CD -%.0f%% für %.1fs" % [dir_label, f.cooldown_reduction_percent, f.duration_seconds]
	if body == "":
		return ""
	return hook_tag + body

# Kompakte Schaden-/Wirkungs-Zusammenfassung für Item-Cards (eine Zeile).
# Beispiele: "⚔ 6 / Reaktiv 8" oder "🔥 3/s" oder "🛡 25".
func primary_effect_label() -> String:
	if effects.is_empty():
		return ""
	var dmg_self: int = -1
	var dmg_react: int = -1
	var burn_dps: int = -1
	var heal_amt: int = -1
	var shield_amt: int = -1
	var slow_pct: float = -1.0
	var tag_pct: float = -1.0
	for e in effects:
		if e is DealDamageEffect:
			if int(e.hook) == 2:
				dmg_react = (e as DealDamageEffect).amount
			else:
				dmg_self = (e as DealDamageEffect).amount
		elif e is BurnEffect:
			burn_dps = (e as BurnEffect).damage_per_second
		elif e is HealSelfEffect:
			heal_amt = (e as HealSelfEffect).amount
		elif e is ShieldEffect:
			shield_amt = (e as ShieldEffect).shield_amount
		elif e is SlowEffect:
			slow_pct = (e as SlowEffect).slow_percent
		elif e is TagBonusEffect:
			tag_pct = (e as TagBonusEffect).bonus_damage_percent
	var parts: PackedStringArray = PackedStringArray()
	if dmg_self >= 0 and dmg_react >= 0:
		parts.append("⚔ %d / %d" % [dmg_self, dmg_react])
	elif dmg_self >= 0:
		parts.append("⚔ %d" % dmg_self)
	elif dmg_react >= 0:
		parts.append("⚔ ↻%d" % dmg_react)
	if burn_dps >= 0:
		parts.append("🔥 %d/s" % burn_dps)
	if shield_amt >= 0:
		parts.append("🛡 %d" % shield_amt)
	if slow_pct >= 0:
		parts.append("❄ %.0f%%" % slow_pct)
	if heal_amt >= 0:
		parts.append("❤ +%d" % heal_amt)
	if tag_pct >= 0 and parts.is_empty():
		parts.append("✦ +%.0f%%" % tag_pct)
	return "  ".join(parts)
