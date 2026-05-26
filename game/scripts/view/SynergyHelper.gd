class_name SynergyHelper extends RefCounted

# Bewertet ein Kandidaten-Item daraufhin, wie gut es zum aktuellen Inventar passt.
# Höherer Score = bessere Synergie. Negativer Score = wirkungslos.
static func score_for_build(candidate: Item) -> float:
	var score: float = 1.0
	# Sammle alle Tags, die der Spieler bereits im Inventar hat
	var player_tag_counts: Dictionary = {}
	for it in RunState.inventory:
		for tag in it.tags:
			player_tag_counts[tag] = int(player_tag_counts.get(tag, 0)) + 1
	# Tag-Bonus-Buffs, die der Spieler bereits hat
	var active_buff_targets: Dictionary = {}
	for it in RunState.inventory:
		for eff in it.effects:
			if eff is TagBonusEffect:
				active_buff_targets[eff.bonus_tag] = true
	# Wenn das Item selbst ein TagBonusEffect ist: Treffer im Build?
	for eff in candidate.effects:
		if eff is TagBonusEffect:
			# DUPLICATE-CHECK: Ist genau dieser Tag-Buff schon im Inventar?
			# Tag-Buffs überschreiben sich, addieren sich nicht — zweiter wäre nutzlos.
			if active_buff_targets.has(eff.bonus_tag):
				score -= 5.0
				continue
			var matches: int = int(player_tag_counts.get(eff.bonus_tag, 0))
			if matches > 0:
				score += 3.0 + float(matches) * 0.5
			else:
				score -= 3.0  # wirkungslos
	# Synergie: Hat das Kandidaten-Item Tags, die durch existierende Buffs gepusht werden?
	for tag in candidate.tags:
		if active_buff_targets.has(tag):
			score += 2.0
	# Bonus: Item hat Tags, die der Spieler schon hat (gleicher Build-Strang)
	var shared_tags: int = 0
	for tag in candidate.tags:
		if player_tag_counts.has(tag):
			shared_tags += 1
	score += float(shared_tags) * 0.5
	# Duplikat-Penalty: gleiches Item bereits im Inventar
	for it in RunState.inventory:
		if it.id == candidate.id:
			score -= 1.0
			break
	return score

# True, wenn das Item für den aktuellen Build wirkungslos ist (z.B. Tag-Bonus auf
# einen Tag, den der Spieler nicht hat, oder Duplikat eines schon aktiven Buffs).
static func is_dead_for_build(candidate: Item) -> bool:
	for eff in candidate.effects:
		if eff is TagBonusEffect:
			# Schon ein anderes Item im Inventar bufft denselben Tag — Buff überschreibt sich.
			for it in RunState.inventory:
				for it_eff in it.effects:
					if it_eff is TagBonusEffect and it_eff.bonus_tag == eff.bonus_tag:
						if not _has_damage_effect(candidate):
							return true
			var has_target_tag: bool = false
			for it in RunState.inventory:
				if eff.bonus_tag in it.tags:
					has_target_tag = true
					break
			# Wenn das Item KEINE eigenen Damage-Effekte hat und der Tag nicht im Build ist:
			if not has_target_tag and not _has_damage_effect(candidate):
				return true
	return false

# Welcher Tag-Buff ist bereits im Inventar aktiv? Liefert Tag-Liste.
static func active_buff_tags() -> Array[StringName]:
	var result: Array[StringName] = []
	for it in RunState.inventory:
		for eff in it.effects:
			if eff is TagBonusEffect and eff.bonus_tag not in result:
				result.append(eff.bonus_tag)
	return result

# True, wenn das Item einen Tag-Buff hat, der schon im Inventar existiert.
static func has_duplicate_buff(candidate: Item) -> bool:
	var existing := active_buff_tags()
	for eff in candidate.effects:
		if eff is TagBonusEffect and eff.bonus_tag in existing:
			return true
	return false

static func _has_damage_effect(item: Item) -> bool:
	for eff in item.effects:
		if eff is DealDamageEffect or eff is BoostNeighborEffect or eff is BoostFloorEffect or eff is HealSelfEffect:
			return true
	return false


# Liefert Synergie-Informationen für ein Item, basierend auf dem aktuellen
# RunState-Inventar. Genutzt von ItemReward und TowerBuilder, um zu zeigen,
# welche Items im Inventar das neue/markierte Item buffen würden.

# Gibt eine Liste von Tags zurück, die durch andere Items im Inventar via
# TagBonusEffect aktiv geboostet werden.
static func boosted_tags_in_inventory() -> Array[StringName]:
	var result: Array[StringName] = []
	for item in RunState.inventory:
		for eff in item.effects:
			if eff is TagBonusEffect:
				if eff.bonus_tag not in result:
					result.append(eff.bonus_tag)
	return result

# Liefert die Namen der Items, die einen bestimmten Tag buffen.
static func items_boosting_tag(tag: StringName) -> Array[String]:
	var result: Array[String] = []
	for item in RunState.inventory:
		for eff in item.effects:
			if eff is TagBonusEffect and eff.bonus_tag == tag:
				if item.display_name not in result:
					result.append(item.display_name)
	return result

# Items im Inventar, die einen bestimmten Tag tragen.
static func count_inventory_items_with_tag(tag: StringName) -> int:
	var n: int = 0
	for item in RunState.inventory:
		if tag in item.tags:
			n += 1
	return n

# Welche Tags des candidate-Items werden durch bereits vorhandene Inventar-Items geboostet?
static func tags_boosted_for_candidate(candidate: Item) -> Array[StringName]:
	var boosted := boosted_tags_in_inventory()
	var result: Array[StringName] = []
	for tag in candidate.tags:
		if tag in boosted:
			result.append(tag)
	return result

# Liefert eine Beschreibung des candidate-Items als Synergie-String,
# z.B. "Druckmesser im Inventar pumpt [pressure] auf — Funkenspeier profitiert nicht."
# Wenn keine relevanten Synergien: leerer String.
static func synergy_summary(candidate: Item) -> String:
	var hits: Array[String] = []
	for tag in candidate.tags:
		var boosters: Array[String] = items_boosting_tag(tag)
		if boosters.size() > 0:
			hits.append("[%s] wird durch %s im Inventar verstärkt" % [String(tag), ", ".join(boosters)])
	# Wenn das candidate-Item selbst ein TagBonusEffect hat, zeige wie viele Items im Inventar davon profitieren
	for eff in candidate.effects:
		if eff is TagBonusEffect:
			var n: int = count_inventory_items_with_tag(eff.bonus_tag)
			if n > 0:
				hits.append("Buffed %d Item%s im Inventar mit [%s]" % [n, "" if n == 1 else "s", String(eff.bonus_tag)])
	if hits.is_empty():
		return ""
	return "\n".join(hits)
