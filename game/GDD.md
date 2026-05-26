# Game Design Document — Cogwright (Arbeitstitel)

Status: Entwurf v1.0 — 2026-05-25. Alle vier Vision-Blöcke abgeschlossen. Bereit für Phase-0-MVP-Implementierung.

---

## 1. Pitch (Elevator)

**Cogwright** ist ein Singleplayer-PvE-**Auto-Battler-Roguelike** für Windows/Steam in einer **Steampunk-Werkstatt-Welt**. Du bist Maschinen-Meister einer schwebenden Werkstatt auf der Suche nach verlorenen Maschinen-Geheimnissen. In jedem Run baust du einen 3-stöckigen Werkstatt-Turm aus 9 mechanischen Items — Zahnräder, Druckkessel, Pendel, Automaten — die mit eigenen Cooldowns auf einer **sichtbaren Echtzeit-Timeline** ticken. Tag-Synergien und Trigger-Hooks erzeugen Build-Vielfalt; Etagen-Affinitäten geben räumliche Strategie. Über eine verzweigte Reisekarte mit 13 Encountern besteigst du Mid- und End-Boss. Bei Tod beginnt ein neuer Run — Meta-Unlocks bleiben.

**Hook (festgelegt 2026-05-25):**
*„Jedes Item ist eine Maschine mit eigenem Takt. Dein Turm ist keine Stat-Sammlung — er ist ein Uhrwerk, das du synchronisierst."*

**Narrative Klammer:** Quest/Expedition — Wanderer-mit-Werkstatt sucht uralte Maschinen-Geheimnisse. Encounter sind Stationen einer Reise. Worldbuilding läuft ausschließlich über Item-Flavor-Text und Encounter-Beschreibungen (keine Dialoge, kein Story-System).

---

## 2. Setting & Tone

**Setting (festgelegt 2026-05-25): Steampunk-Werkstatt-Turm**

Du bist Maschinen-Meister/in einer schwebenden Werkstatt, die durch eine Welt konkurrierender Gilden, Luftpiraten und korrumpierter Automaten reist. Items sind Zahnräder, Dampfkessel, Pendel, mechanische Vögel, Schmiede-Module, Druckventile. Bosse sind Riesen-Automaten oder verschworene Konkurrenz-Werkstätten.

**Vibe:** technisch-verspielt, Bastelfreude, Kupfer/Messing/Mahagoni-Palette, Soundtrack mit Klavier + Mechanik-Percussion + Akkordeon-/Kammer-Elementen. Tone: nicht düster, nicht albern — sondern *fasziniert vom Maschinellen*, leicht melancholisch-romantisch wie Miyazakis *Schloss im Himmel*.

**Art-Style (festgelegt 2026-05-25): 2D-Vektor / Flat-Design**

Saubere Linien, präzise mechanische Geometrie. Items als klar lesbare Vektor-Icons. UI nutzt dieselbe Vektor-Ästhetik (keinen Bruch zwischen Item-Sprite und Menü-Button).

**Implementierungshinweis:** Skelett-Animation statt frame-by-frame (Godot `AnimationPlayer` + `Sprite2D`-Hierarchien; optional Spine/DragonBones-Import via Plugin). Vektor-Assets als SVG oder als hochauflösende PNG/WebP exportieren.

---

## 3. Core Loop

```
[Meta-Menü]
   ↓ Run starten
[Run-Start: Charakter & Starter-Items wählen]
   ↓
[Schleife: Encounter wählen → Auflösen → Belohnung]
   ├─ Kampf-Encounter (Auto-Battler)
   ├─ Shop-Encounter (Items kaufen/verkaufen/upgraden)
   ├─ Event-Encounter (Story-Choice mit Effekt)
   └─ Elite/Boss alle N Encounter
   ↓ N Encounter / Boss besiegt
[Run-Ende]
   ↓ Run-Belohnung (Meta-Währung, ggf. neue Unlocks)
[Meta-Menü] (neue Items/Perks/Charaktere verfügbar)
```

**Run-Länge (festgelegt 2026-05-25):** ~30–45 Minuten brutto (Steam-Median für Roguelikes; lang genug für Build-Aufbau, kurz genug für eine Sitzung).

**Encounter pro Run (festgelegt 2026-05-25):** 13 Knoten (Median von 12–15) — 5 vor Mid-Boss, 5 nach Mid-Boss, + Mid-Boss + End-Boss.

**Map-Struktur (festgelegt 2026-05-25): Branching Map mit Vorschau** (Slay-the-Spire-Style). Jede Reihe hat 1–2 Knoten, Pfade sind sichtbar, Spieler kann seine Route planen.

```
START ─┬─ E1 ──┬─ E2 ──┬─ E3 ──┬─ E4 ──┬─ E5 ──┐
       └─ E1'──┘       └─ E3'──┘       └─ E5'──┤
                                                ├──→ MID-BOSS
       ┌─ E7 ──┬─ E8 ──┬─ E9 ──┬─ E10 ─┬─ E11 ─┤
       └─ E7'──┘       └─ E9'──┘       └─ E11'─┘
                                                └──→ END-BOSS
```

**Map-Generierung:** prozedural pro Run mit festem Seed. Sichergestellt: jeder Spieler-Pfad enthält mindestens 1 Shop und 1 Elite-Möglichkeit pro Akt.

---

## 4. Battle-System

**Pflicht (festgelegt):**
- Vollständig automatisch — kein Spielereingriff während des Kampfes
- Deterministisch (fester Seed pro Run → reproduzierbar)
- Sichtbar/animiert (kein reines Zahlen-Geklicke)

**Kampf-Repräsentation (festgelegt 2026-05-25):**
**Echtzeit-Timeline mit Cooldowns** (Hook D). Jedes Item hat einen Cooldown in Sekunden und triggert seinen Effekt, sobald der Cooldown abgelaufen ist. Trigger-Effekte können andere Items reaktiv triggern (`on_neighbor_trigger`, `on_fire_event`, etc.).

**Tick-System:** fester Schritt (Empfehlung: 30 Hz = 33.3 ms pro Tick). Alle Cooldowns dekrementieren um den Tick-Wert. Trigger-Events werden in eine Event-Queue gepusht und in Reihenfolge abgearbeitet.

**Reentrancy-Schutz:** ein Item darf pro Tick nur eine begrenzte Anzahl reaktiver Trigger auslösen (z. B. max. 3 Re-Trigger pro Tick), sonst Endlosschleifen-Risiko.

**Kampf-Visualisierung (festgelegt 2026-05-25): Hybrid — lokal + global + Rhythmus-Akzent**
- **Lokale Cooldown-Anzeige:** Jedes Item hat einen Cooldown-Ring/Balken direkt am Sprite, der sich füllt. Bei Trigger spielt eine kurze Animation ab.
- **Globale Timeline-Strip:** Horizontale Leiste oben am Bildschirm, zeigt eine Vorschau der nächsten 3–5 Sekunden. Item-Icons gleiten von rechts auf eine „Jetzt"-Markierung zu.
- **Soundtrack im Maschinen-Tempo:** Musik ist nicht strikt rhythmus-synchron, aber im Tempo so abgestimmt, dass Item-Trigger sich „im Beat" anfühlen. BPM-Anker (z. B. 120) erleichtert Cooldown-Design.

**Spieler-Avatar im Kampf (festgelegt 2026-05-25): Der Turm selbst.**
Kein separater Held. Der Turm hat eine Gesamt-HP (siehe Etagen-System unten). Items sind Teil des Turms, nicht eines Avatars davor.

---

## 5. Item-System & Turm-Aufbau

**Pflicht (festgelegt):**
- 50+ Items in Phase 1, 100+ langfristig
- Items sind `Resource`-Dateien (Godot-`.tres`), nicht hartkodiert
- Mind. 4 Rarities (Common/Uncommon/Rare/Legendary)
- Items können in-run **upgraden** (Combine 3-of-a-kind oder Encounter-basiert)

**Slot-Modell (festgelegt 2026-05-25): Turm mit 3 Etagen × 3 Slots = 9 Items max.**

| Etage | Name | HP-Modifier | Cooldown-Modifier | Bonus | Item-Affinität (Tags) |
|---|---|---|---|---|---|
| 3 | Spitze / Observatorium | –20% Etagen-HP | +25% Trigger-Speed | +Sicht-/Scout-Effekte | `[ranged, precision, scout, fire]` |
| 2 | Werkstatt / Mid | neutral | neutral | +5% globaler Trigger-Schaden | `[mechanical, crafting, modifier]` |
| 1 | Fundament | +30% HP-Pool | –15% Trigger-Speed | starke passive Defensiv-Effekte | `[heavy, defensive, support]` |

Items können theoretisch auf jeder Etage platziert werden, aber Items haben **Affinitäts-Tags**: Wenn ein Item auf einer Etage steht, mit der seine Tags matchen, erhält es einen Bonus (z. B. +10% Effekt-Stärke). Items „passen" also natürlich auf bestimmte Etagen, aber kein hartes Constraint.

**Etagen-HP separat oder geteilt?** Vorschlag: **gemeinsame Turm-HP-Leiste**, aber Gegner können „Etagen-Angriffe" ausführen, die Items auf einer Etage temporär deaktivieren. So bleibt HP-Management klar (1 Leiste), aber Etagen haben taktische Relevanz im Kampf.

**Synergie-Mechanik (festgelegt 2026-05-25): Hybrid Tags + Trigger-Hooks**

Items haben **beide** Eigenschaften:

1. **Tags** für passive Synergien:
   - Tag-Counts werden global ausgewertet (z. B. `count[fire] >= 3 → +20% Damage für alle [fire]-Items`)
   - Klar für den Spieler lesbar, Codex zeigt aktive Tag-Synergien
   - Tags wie: `[fire, water, steam, mechanical, blunt, sharp, ranged, defensive, support, crafting, scout, heavy, precision, …]` (Setting-passend, erweiterbar)

2. **Trigger-Hooks** für reaktive Synergien (Event-basiert):
   - `on_combat_start` — einmaliger Init-Effekt
   - `on_self_trigger` — Standard-Effekt beim Cooldown-Trigger
   - `on_neighbor_trigger` — wenn ein Item auf derselben Etage triggert
   - `on_floor_above_trigger` / `on_floor_below_trigger` — Cross-Etagen-Reaktionen
   - `on_tag_event(tag)` — z. B. „bei jedem Fire-Trigger im Turm"
   - `on_enemy_damaged` — bei jedem Schadens-Event auf den Gegner
   - `on_self_damaged` — bei Schaden aufs eigene Item / die eigene Etage
   - `on_combat_end` — Cleanup / Rewards

   Diese Hooks erlauben **Trigger-Kaskaden** und sind die Quelle der „Mastery"-Tiefe.

**Item-Resource-Schema (vorläufig):**
```gdscript
class_name Item extends Resource
@export var id: StringName
@export var display_name: String
@export var description: String
@export var rarity: Rarity # enum: COMMON, UNCOMMON, RARE, LEGENDARY
@export var tags: Array[StringName]
@export var floor_affinity: Array[StringName] # ["foundation"], ["workshop"], ["pinnacle"]
@export var cooldown_seconds: float
@export var base_damage: int
@export var icon: Texture2D
@export var trigger_script: GDScript # optional: kapselt komplexe Trigger-Hooks
```

Trigger-Hooks werden entweder als **GDScript-Methoden** auf einem zugeordneten `ItemBehavior`-Skript implementiert (für komplexe Items) oder über **deklarative Effect-Resources** für einfache Items (z. B. `DealDamageEffect`, `ApplyBuffEffect`).

---

## 6. Encounter-Typen (festgelegt 2026-05-25)

| Typ | Pro Run (~) | Beschreibung |
|---|---|---|
| Standard-Kampf | 6 | Brot-und-Butter, einfache bis mittlere Gegner-Türme |
| Elite-Kampf | 2 | 1 pro Akt, schwerer/spezialisiert, bessere Belohnung |
| Shop / Werkstatt | 2 | 1 pro Akt, Items kaufen/verkaufen/upgraden, Reroll-Option |
| Event | 2 | Story-Choice ohne Kampf, trägt Vibe-Achse über Flavor-Text |
| Heilstation | 1 | Im 2. Akt, Run-Recovery (HP wiederherstellen + ggf. ein Item reparieren) |
| Boss | 2 | 1 Mid-Boss (zwischen Akten) + 1 End-Boss |

**Phase-1-Scope:** alle obigen Typen.
**Aus Phase 1 ausgeschlossen** (Erweiterungen für Phase 1.5+): Treasure-Räume, Modul-Upgrade-Stationen, Random-Events mit Long-Term-Konsequenzen.

**Boss-Struktur (festgelegt 2026-05-25):** 1 Mid-Boss + 1 End-Boss pro Run. **Endless-Modus** als Mastery-Belohnung in Phase 1.5+ (alle X Encounter ein neuer Boss, kein Run-Ende, Skalierungs-Schwierigkeit, Leaderboard-tauglich).

---

## 7. Progression

### In-Run
- Items werden in Encountern gefunden, in Shops gekauft, durch Combine-Upgrade (3-of-a-kind) verstärkt
- Combo-Discovery: neue Synergien werden im **Codex** eingetragen, sobald sie im Spiel erlebt wurden
- Run-Currency („Zahnräder") wird zwischen Encountern ausgegeben (Shops, Re-Rolls, Heilstation-Upgrades)
- HP wird ausschließlich an Heilstationen oder durch spezielle Items wiederhergestellt — sonst persistiert zwischen Encountern

### Meta (über Runs hinweg)

**Meta-Aggressivität (festgelegt 2026-05-25): Mittel.** Run #1 startet mit ~40% des Itempools verfügbar und nur dem Basis-Charakter. Über die ersten 10–20 Runs schalten sich weitere Items, Perks, Charaktere, Heat-Stufen, kosmetische Variants frei. Niemals blocking — Run #1 ist gewinnbar.

- **Meta-Currency:** „Resonanzkristalle" oder ähnlich (Setting-passend) — wird run-übergreifend gesammelt, sowohl bei Siegen als auch (kleinere Menge) bei Niederlagen
- Freischaltungen:
  - Neue Items in den Loot-Pool
  - Neue Perks (passive Modifier, die zwischen Runs gewählt werden können)
  - Neue Charaktere (Phase 1: 3 Charaktere → Phase 1.5: 4–5)
  - Heat-Stufen (Phase 1.5+)
  - Cosmetics (Charakter-Skins, Turm-Designs)
- **Achievements (Steam)** triggern oft Unlocks (sichtbarer Belohnungs-Loop)

### Mastery-Skalierung (gestaffelt)

| Phase | Mastery-System |
|---|---|
| 1.0 | Standard-Schwierigkeit (eine Schwierigkeitsstufe für alle) |
| 1.5 | **Heat-System** (Hades-Style): Modifier-Stufen 0–25+, Spieler wählt vor Run, Belohnungen skalieren |
| 1.5 | **Endless-Modus**: kein Run-Ende, skalierende Schwierigkeit, lokaler Highscore |
| 2.0 | **Daily Challenges**: täglicher fester Seed für alle Spieler, **Steam-Leaderboard** via Steamworks-API |

### Charakter-System (gestaffelt)

| Phase | Charaktere |
|---|---|
| 0 (MVP) | 1 Charakter (Der Maschinist) |
| 1.0 (Launch) | 3 Charaktere: Schmiedin, Uhrmacher, Chemiker — jeweils mit eigenen Starter-Items, Klassenfähigkeit, kleinem exklusiven Itempool |
| 1.5+ | 4–5 Charaktere (z. B. Pilotin, Saboteur ergänzen) |

Jeder Charakter hat:
- 3 Starter-Items
- Eine passive **Klassenfähigkeit** (z. B. „Schmiedin: alle Items mit Tag [blunt] +15% Schaden")
- Einen HP-Modifier
- Einen kleinen exklusiven Itempool (~5 Items pro Charakter), der Spielstil verstärkt
- Bevorzugtes Etagen-Layout (Empfehlung im UI, kein Constraint)

---

## 8. USP / Differenzierung

Aktueller Markt: *Oaken Tower*, *Backpack Battles*, *Super Auto Pets*, *The Bazaar*. Alle vier sind PvP-fokussiert oder Multiplayer. **Unsere Lücke:** ein **PvE-Auto-Battler-Roguelike mit Echtzeit-Timeline-Kampf** — *The Bazaar*-Mechanik, aber rein Singleplayer und Mastery-orientiert. Kombiniert mit einem stilsicheren Steampunk-Setting und 2D-Vektor-Ästhetik gibt es aktuell keinen direkten Konkurrenten.

**Strategischer Fokus (festgelegt 2026-05-25):**

Drei Achsen wurden priorisiert, in **Implementierungsreihenfolge:**
1. **A — Strategie / Optimierung** (zuerst): tiefes Item-System, klare Synergien, lesbare Stats, Codex
2. **B — Atmosphäre / Vibe** (sobald Core läuft): Soundtrack, Polish, Worldbuilding über Item-Flavor und Encounter-Texte
3. **D — Wiederspielbarkeit / Mastery** (zuletzt, Phase 1.5+): Schwierigkeitsmodifier, Daily Runs, ggf. Steam-Leaderboard

**Story (C) wurde explizit ausgeschlossen** — kein narrativer Bogen, keine Dialoge, kein „Ending". Welt-Worldbuilding läuft ausschließlich über Item-Flavor-Text und Encounter-Beschreibungen.

---

## 9. Phase-0-MVP (Vertical Slice)

**Ziel:** in 2–4 Wochen ein Build, der *einen kompletten Run* erlaubt — klein, aber funktional komplett.

**Scope:**
- 1 Charakter („Der Maschinist") mit 3 Starter-Items
- ~15 Items (verschiedene Tags, einfache Trigger-Hooks)
- Turm-System (3 Etagen × 3 Slots = 9 Item-Slots, Etagen-Modifier funktional)
- Battle-Loop: deterministisches Tick-System (30 Hz), Cooldown-Trigger, Trigger-Hook-Reaktionen, Schaden-Berechnung, Win/Lose-State
- Battle-UI: lokale Cooldown-Ringe + globale Timeline-Strip (vereinfacht), Turm-HP-Leiste
- Map-System: 13-Knoten Branching Map (vereinfacht: nur Standard-Kampf, Shop, Mid-Boss, End-Boss)
- 1 Mid-Boss + 1 End-Boss als Encounter-Instanzen
- Shop-Encounter (Items kaufen/verkaufen)
- Save/Load (Run + Meta)
- 2D-Vektor-Platzhalter-Icons (Kenney.nl Vector-Pack, eigene simple SVGs)

**Was im MVP NICHT drin ist:** Sound, Event-Encounter, Heilstation, Elite-Kämpfe, Codex, Achievements, Settings-Menü, Lokalisierung, Meta-Unlocks (außer Test-Stub: 1 Item das beim ersten Sieg freischaltet).

---

## 10. Roadmap (Vision)

| Phase | Inhalt | Ziel |
|---|---|---|
| **0 — Vertical Slice** | siehe oben | 2–4 Wochen, ein vollständiger Run mit funktionalem Kern |
| **1.0 — PvE Core Launch** | 3 Charaktere, 50+ Items, alle Encounter-Typen, Mid+End-Boss, Codex, Meta-Progression, Settings-Menü, Soundtrack | 4–6 Monate nach Phase 0 |
| **1.5 — Mastery Update** | 4–5 Charaktere, Heat-System, Endless-Modus, mehr Items, mehr Bosse | 2–3 Monate nach 1.0 |
| **2.0 — Community Update** | Daily Challenges + Steam-Leaderboard, Steam-Achievements, Cosmetics, Lokalisierung (DE/EN) | 1–2 Monate nach 1.5 |

**Steam-Strategie:**
- Coming-Soon-Page möglichst früh (idealerweise mit Phase 0 in der Hand, also in ~1–2 Monaten)
- Wishlist-Sammlung über mehrere Monate
- Early Access ggf. mit Phase 1.0; voller Launch mit Phase 2.0
- Trademark-Check für „Cogwright" vor Coming-Soon-Page
