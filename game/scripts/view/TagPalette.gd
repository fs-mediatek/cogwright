class_name TagPalette extends RefCounted

# Farbpaletten pro Tag. Jeder Tag bekommt einen Hintergrund und eine Textfarbe.
# Wird von TagChips zum Stylen der Pillen verwendet.

const PALETTE: Dictionary = {
	&"mechanical": {"bg": Color(0.42, 0.36, 0.28), "fg": Color(1, 0.95, 0.85)},
	&"pressure": {"bg": Color(0.72, 0.52, 0.20), "fg": Color(1, 0.98, 0.88)},
	&"blunt": {"bg": Color(0.38, 0.28, 0.18), "fg": Color(1, 0.92, 0.75)},
	&"sharp": {"bg": Color(0.50, 0.50, 0.55), "fg": Color(1, 1, 1)},
	&"fire": {"bg": Color(0.78, 0.32, 0.18), "fg": Color(1, 0.95, 0.85)},
	&"steam": {"bg": Color(0.36, 0.55, 0.65), "fg": Color(0.95, 1, 1)},
	&"ranged": {"bg": Color(0.48, 0.30, 0.62), "fg": Color(1, 0.95, 1)},
	&"precision": {"bg": Color(0.30, 0.55, 0.60), "fg": Color(0.92, 1, 1)},
	&"heavy": {"bg": Color(0.28, 0.24, 0.22), "fg": Color(0.95, 0.92, 0.82)},
	&"defensive": {"bg": Color(0.32, 0.42, 0.58), "fg": Color(0.95, 0.98, 1)},
	&"support": {"bg": Color(0.32, 0.55, 0.36), "fg": Color(0.92, 1, 0.92)},
	&"crafting": {"bg": Color(0.55, 0.40, 0.22), "fg": Color(1, 0.95, 0.85)},
	&"modifier": {"bg": Color(0.55, 0.40, 0.62), "fg": Color(1, 0.95, 1)},
	&"sync": {"bg": Color(0.65, 0.58, 0.22), "fg": Color(1, 1, 0.85)},
	&"scout": {"bg": Color(0.45, 0.62, 0.32), "fg": Color(0.95, 1, 0.88)},
	&"reactive": {"bg": Color(0.72, 0.32, 0.52), "fg": Color(1, 0.92, 0.98)},
	&"water": {"bg": Color(0.25, 0.45, 0.70), "fg": Color(0.95, 0.98, 1)},
}

const FALLBACK_BG: Color = Color(0.30, 0.27, 0.23)
const FALLBACK_FG: Color = Color(0.95, 0.92, 0.85)

# Tag-Beschreibungen: was bedeutet jeder Tag? Wird in Tooltips + Codex angezeigt.
const TAG_DESCRIPTIONS: Dictionary = {
	&"mechanical": "Mechanik. Grundlagen-Tag der meisten Werkstatt-Items. Wirkt mit [sync] und [modifier] zusammen.",
	&"pressure":   "Druckluft. Schwere Maschinen, oft mit Verzögerung aber wuchtigem Treffer. Druckmesser verstärkt sie.",
	&"blunt":      "Wucht. Hammer und ähnliches. Langsamer, hoher Single-Hit. Schmiede-Esse verstärkt [blunt].",
	&"sharp":      "Klingen-/Stich-Items. Präziser Damage, häufig auf Spitze.",
	&"fire":       "Feuer. Schnelle, leichte Treffer mit Hitze. Brennkammer verstärkt alle [fire]-Items.",
	&"steam":      "Dampf. Weiche, oft supportende Items. Stillstand-Sicherung und Cooldown-Boost.",
	&"ranged":     "Distanz. Items mit Wurf-/Schuss-Mechanik. Geeignet auf Spitze.",
	&"precision":  "Präzision. Geringe Streuung, mehr Crit-Potenzial. Späher-Lampe verstärkt sie.",
	&"heavy":      "Schwer. Massiv, langsam, viel Damage. Selten reaktiv.",
	&"defensive":  "Verteidigung. Schild- und Absorbtions-Items.",
	&"support":    "Unterstützung. Heal, Buffs, Cooldown-Boost. Selten direkter Damage.",
	&"crafting":   "Werkbank-Items. Funktional, kein direkter Kampfeffekt.",
	&"modifier":   "Modifizierer. Verändert andere Items oder Tag-Bonus-Logik.",
	&"sync":       "Synchron. Triggert Nachbar-Items oder buffed sie zeitlich.",
	&"scout":      "Späher. Sieht das Schlachtfeld besser, oft Buff-First-Strike.",
	&"reactive":   "Reaktiv. Triggert auf Events (Nachbar-Trigger, Selbst-Damage). Kein eigener Cooldown im üblichen Sinn.",
	&"water":      "Wasser. Kühlt, löscht, hat oft AOE-Charakter.",
}

# Rarität-Borderfarben: Common=Grau-Bronze, Uncommon=Grün, Rare=Blau, Legendary=Lila
const RARITY_BORDERS: Array[Color] = [
	Color(0.55, 0.48, 0.36),  # Common
	Color(0.49, 0.76, 0.47),  # Uncommon
	Color(0.36, 0.70, 0.85),  # Rare
	Color(0.82, 0.50, 0.96),  # Legendary
]
const RARITY_NAMES: Array[String] = ["Gewöhnlich", "Ungewöhnlich", "Selten", "Legendär"]

static func rarity_color(rarity: int) -> Color:
	if rarity < 0 or rarity >= RARITY_BORDERS.size():
		return RARITY_BORDERS[0]
	return RARITY_BORDERS[rarity]

static func rarity_name(rarity: int) -> String:
	if rarity < 0 or rarity >= RARITY_NAMES.size():
		return "?"
	return RARITY_NAMES[rarity]

static func bg(tag: StringName) -> Color:
	return PALETTE.get(tag, {}).get("bg", FALLBACK_BG)

static func fg(tag: StringName) -> Color:
	return PALETTE.get(tag, {}).get("fg", FALLBACK_FG)

# Ersetzt alle "[tag]"-Vorkommen im Text durch BBCode mit der Tag-Farbe.
# Nutzt eine etwas hellere Variante der Bg-Farbe für gute Lesbarkeit auf dunklem Hintergrund.
static func colorize_tags(text: String) -> String:
	var result: String = text
	for tag_key in PALETTE.keys():
		var tag_str: String = String(tag_key)
		var pattern: String = "[%s]" % tag_str
		if not result.contains(pattern):
			continue
		var bg_color: Color = PALETTE[tag_key]["bg"]
		# Hellere, kräftige Variante für Display auf dunklem Hintergrund
		var display: Color = bg_color.lerp(Color(1, 1, 1), 0.35)
		var html: String = "#%02x%02x%02x" % [int(display.r * 255), int(display.g * 255), int(display.b * 255)]
		var replacement: String = "[b][color=%s]%s[/color][/b]" % [html, pattern]
		result = result.replace(pattern, replacement)
	return result
