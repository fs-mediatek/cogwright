# Cogwright — Expansion-Konzept v1

**Stand:** 2026-05-26
**Inhalt:** Neue Klasse · 13 Perks · 6. Boss · Sandbox-Modus · Asset-Prompts

---

## 1. Neue Klasse — **Kanonenmeister**

**ID:** `gunner` · **Tags-Familie:** [ranged] · [mechanical] · [heavy] · **Antithese:** Burst-DPS statt Reactive-Chains

### Vision

Wo Schmiedin auf Wuchtschlag setzt und Pyrotechniker auf Burn-Stacks, ist der Kanonenmeister der **Kaliber-Strategist**: kalkulierte Salven, Reichweite, mechanische Synchronisation. Er lebt in einem fahrenden Kasematten-Wagen, jede Etage ist eine eigene Geschützplattform.

**Theme-Sprache:** Brass-Geschützrohre, Munitions-Ketten, schwere Stoßdämpfer, Visiergeräte. Keine Schmiede-Glut, keine Steam-Bursts — kühles Messing-Grau und Kupfer-Akzente.

### Character-Passive

```gdscript
"gunner": {
    "ranged_damage_bonus": 20,    # +20% Schaden für [ranged]-Items
    "reactive_cd_penalty": 20,    # +20% Cooldown für [reactive]-Items
}
```

Begründung: starker Pull Richtung Burst-Ranged-Builds, Reactive-Synergien sind absichtlich schwächer um Klassen-Identität zu schärfen.

### Starter-Set "Kasematten-Wagen"

| Slot | Item | Tags | CD | Wirkung |
|------|------|------|----|---------| 
| Pinnacle | **Drillingsgeschütz** | ranged, heavy, mechanical | 3.5s | 3 Treffer á 6 Damage in Folge (Burst) |
| Workshop | **Munitionsband** | mechanical, sync, support | 4.0s | Alle [ranged]-Items im Tower bekommen –30% CD für 4s |
| Foundation | **Panzerung** | defensive, heavy | 5.0s | +30 Schild für 8s (eigener Tower) |

### Weitere Klassen-affine Items (im normalen Pool, drop-rate erhöht für `gunner`)

| Item | Tags | CD | Wirkung |
|------|------|----|---------| 
| **Wurfanker** | sharp, ranged, mechanical | 4.5s | 12 Damage + Slow –25% für 2.5s |
| **Stabilisator-Strebe** | mechanical, support | 3.0s | Etage darunter –25% CD für 6s |
| **Granat-Werfer** | heavy, ranged, sharp | 5.5s | 18 Damage + Burn 2/s für 3s |

### Floor-Vorlieben

- Pinnacle: ranged, heavy (Drillingsgeschütz, Granat-Werfer)
- Workshop: mechanical, support, sync (Munitionsband, Stabilisator-Strebe)
- Foundation: defensive, heavy (Panzerung, Wurfanker)

### Unlock-Condition

Standard — direkt verfügbar im Char-Select (analog Druckmeister/Pyrotechniker). Optional: nach 5 Run-Versuchen.

---

## 2. Perk-System — 13 Perks

### Mechanik

- Bis zu **3 Perk-Slots** pro Run aktivierbar (Spieler wählt 0–3 aus den freigeschalteten)
- **Slot 1 freigeschaltet** nach erstem Boss-Sieg (egal welche Klasse)
- **Slot 2 freigeschaltet** nach 3 Boss-Siegen
- **Slot 3 freigeschaltet** nach 6 Boss-Siegen (oder: alle 5 Klassen mindestens 1× gewonnen)
- UI: zusätzliche Zeile auf [RunStart.tscn](game/scenes/RunStart.tscn) zwischen Heat-Row und SetsContainer — eine Perk-Slot-Row, klick öffnet Auswahl-Popup mit unlock-State

### Perk-Liste

| ID | Name | Effekt | Unlock |
|----|------|--------|--------|
| **P1** | **Notvorrat** | Start mit +50 max Tower-HP | 1. Boss-Sieg (egal welcher Char) |
| **P2** | **Schnellfeuer** | Alle [ranged]-Items im Tower: –15% CD | Run mit Pyrotechniker gewinnen |
| **P3** | **Aetherantrieb** | Battle-Speed-Default startet auf ×1.5 (visuell + mechanisch) | 15 Items im Codex entdecken |
| **P4** | **Druckverwerter** | Alle [pressure]-Items: +20% Damage | Heat-3-Run mit Druckmeister gewinnen |
| **P5** | **Werkbank-Mogul** | Werkstatt-Upgrades kosten 25% weniger Resonanzkristalle | Alle 14 Werkstatt-Upgrades mind. Stufe 1 |
| **P6** | **Glücksrad** | Item-Reward zeigt 4 Optionen statt 3 (mehr Auswahl) | Run mit 4 Boss-Siegen abschließen |
| **P7** | **Reaktiv-Kette** | Reactive-Trigger feuern zusätzlich auf diagonal-Nachbarn (nicht nur Etage) | Run mit Saboteur ohne Reparatur-Halt-Besuch gewinnen |
| **P8** | **Eisenhaut** | Bei Player-HP < 30 % aktiviert sich permanent +30 Schild bis Battle-Ende | Run mit Schmiedin ohne Heilung im Map-Pfad gewinnen |
| **P9** | **Marktkenner** | Shop-Items kosten 30 % weniger Gold | 500 Gold in einem einzigen Run sammeln |
| **P10** | **Plündererglück** | Elite-Kämpfe droppen zusätzlich 1 zufälliges Item | 5 Elite-Encounter im Lebenszeit-Total besiegen |
| **P11** | **Krit-Strom** | Crit-Chance +10 % · Crit-Multiplikator ×2.5 (statt ×2.0) | 100 kritische Treffer im Lebenszeit-Total |
| **P12** | **Brand-Stapel** | Burn-Effekte stacken: jeder Auslöser addiert sich zur Gesamtrate (statt zu überschreiben) | Boss „Funken-Tyrann" besiegen |
| **P13** | **Zeitloser Mechanismus** | Erster Item-Trigger jedes Items im Battle ist kostenlos (kein Cooldown-Verbrauch) | Boss „Uhrwerk-Hexe" besiegen |

### Speicher-Schema

```gdscript
# In MetaState.gd ergaenzen
var unlocked_perks: Array[StringName] = []         # frei gespielt
var selected_perks: Array[StringName] = []         # fuer naechsten Run aktiv
var perk_slots_available: int = 0                  # 0/1/2/3, abhaengig von Lifetime-Stats
```

### Balance-Hinweise

- **P3 (Aetherantrieb)** + **P11 (Krit-Strom)** = mögliches OP-Combo. Akzeptabel, da beide hohe Unlock-Hürden haben.
- **P13 (Zeitloser Mechanismus)** ist mächtig — schenkt jedem Item ein Gratis-Trigger. Nur 1 Slot bedeutet: Choice statt Powercreep.
- **P7 (Reaktiv-Kette)** ist hochsynergetisch mit Saboteur — bewusst, belohnt Klassen-Mastery.

---

## 3. Neuer Boss — **Schwarze Lokomotive Kraschnit**

**ID:** `schwarze_lokomotive` · **HP:** 380 · **Encounter-Slot:** Boss-Pool

### Lore

> „Sie kommt nicht. Sie wird angekündigt. Erst der Boden zittert, dann der Horizont schwärzt. Wenn die Lokomotive das Tal erreicht hat, ist es zu spät zu fliehen — und zu spät, sich vorzubereiten."

Wandernde Lokomotive, deren Waggons in Geschützplattformen umgebaut wurden. Der Lokführer ist längst tot — die Maschine fährt sich selbst. Jede Achse trägt schwere Mechanik, jede Wand ist mit Munitionsketten verzogen.

### Tower-Loadout

| Floor | Slot 1 | Slot 2 | Slot 3 |
|-------|--------|--------|--------|
| Pinnacle (2) | Drillingsgeschütz | Granat-Werfer | Druckkanone |
| Workshop (1) | Munitionsband | Schmieröl-Kanister | Stabilisator-Strebe |
| Foundation (0) | Eisenklaue | Stoßdämpfer | Wurfanker |

### Set-Bonus

**„Schwerer Geleitzug":** Alle [mechanical] + [heavy]-Items +25 % Damage. Konstant aktiv.

### Spezial-Mechanik (Phase 2)

Bei HP < 50 % aktiviert sich **„Volle Fahrt"**: alle Cooldowns –25 %, Set-Bonus steigt auf +35 %. Visuell: Backdrop bekommt rote Tönung, Music-Pitch +0.05.

Implementation: BattleController emittiert `boss_phase_changed(phase: int)`-Signal bei HP-Schwellen, BattleView reagiert.

### Place im Boss-Pool

In [MapGenerator.gd](game/scripts/core/MapGenerator.gd) zu der Boss-Liste hinzufügen — 1/6-Chance neben den existierenden 5.

---

## 4. Sandbox-Modus — **„Schmiede-Probe"**

### Vision

Endlos-Werkstatt zum Testen + Sammeln. Keine Klasse, kein Set-Bonus per Default, freie Item-Wahl. Hoher Wiederspielwert durch Build-Experimentierung.

### Mechanik

1. **Item-Pool**: alle entdeckten Items des Codex sind verfügbar (Codex-Discovery = Voraussetzung)
2. **Start-Setup**:
   - Spieler wählt **5 Start-Items** (statt 3 wie in Standard-Runs)
   - Spieler wählt optional einen **Tag-Bonus** aus 6 Optionen: `+15% [fire]`, `+15% [pressure]`, etc. (selbst gewählter Set-Bonus)
   - Spieler wählt **1 Perk** (falls freigeschaltet) — Sandbox-Slot ist separat von Standard-Slots
3. **Run-Struktur**: 12 Encounter ohne festen Boss-Pfad — Map gleicht Endlos-Mode
4. **Reward**: alle X Encounter eine Item-Auswahl (3 Optionen), Items dürfen sich wiederholen (Werkbank-Upgrade aktiv)
5. **Ende**: Spieler entscheidet selbst wann er „beendet" — Button „Run beenden" gibt MetaState-Rewards (proportional zur Fortschritts-Tiefe)

### Unlock-Condition

Verfügbar nach **3 Boss-Siegen** (egal welcher Klasse). Sonst zu früh für Sandbox-Experimente.

### UI-Slot

Neuer Button in MainMenu nach „Daily Challenge": **„Schmiede-Probe"** (oder „Sandbox" / „Freie Probe"). Eigene Szene `SandboxStart.tscn` für Item-Auswahl.

### Achievement / Stats

Eigene Stat-Kategorie: „Sandbox-Runs". Achievements wie „100 Encounter in einem Sandbox-Run", „Mit 5 [reactive]-Items 50 Encounter überleben".

---

## 5. Asset-Liste

> **Workflow:** Pro Asset einen frischen ChatGPT-Chat. Block aus „Copy block" 1:1 reinkopieren. Anti-Collage-Guard ist in jedem Prompt.

**Target-Pfade:**
- Char-Portrait → `game/assets/characters/`
- Items → `game/assets/items/` (weißer Hintergrund, BG-Removal nötig)
- Boss → `game/assets/bosses/`
- Perk-Icons → `game/assets/ui/perks/` (weißer Hintergrund, BG-Removal nötig)
- Sandbox-Hero → `game/assets/backgrounds/`

---

### A5: `char_gunner.png` — Kanonenmeister

**Target:** `assets/characters/char_gunner.png` · **Größe:** 1536×1920 (4:5)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images, not a grid layout. One subject, one frame,
exactly the requested aspect ratio.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG, KEIN transparenter Hintergrund, KEIN Alpha-Channel-Tweak.
- Aspektverhältnis exakt 4:5 einhalten.
- Mindestens 1536 px Kantenlänge.
- KEIN Schachbrett-Hintergrund.

Bild-Prompt:
Portrait of a steampunk gunnery officer, mid-30s veteran with weathered features and steel-grey eyes, standing in three-quarter pose inside the interior of a fortified casemate wagon. He wears a dark leather greatcoat with brass buttons, a heavy ammunition bandolier across his chest, a fingerless leather glove on his right hand, and a brass-rimmed monocle on his left eye. Behind him: rows of polished brass cannon mounts, a triple-barreled small cannon on a stabilized swivel, ammunition crates stacked, brass conduits running along the walls. Warm amber lantern light from upper left, cool blue-grey daylight from a small ventilation slit to the right. Confident but tired expression, steady gaze toward the viewer.

Stil: warm dark amber and cool steel-grey lighting, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, dignified veteran energy, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 4:5
```

---

### C7: `triple_cannon.png` — Drillingsgeschütz

**Target:** `assets/items/triple_cannon.png` · **Größe:** 1024×1024 (1:1) · **BG-Removal: ja**

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett. Mindestens 1024×1024 px.
- Klare zentrale Silhouette, gut lesbar auch klein (48 px).

Bild-Prompt:
Single icon on plain solid white background: a small triple-barreled steampunk brass cannon mounted on a polished iron swivel base, three short cannon barrels arranged in a triangular cluster, brass fittings and rivets visible along the breech, a small ammunition feed running into the side. Front-facing slightly tilted three-quarter view. Warm metallic gleam, slight steam wisp curling from one barrel. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and iron steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

---

### C8: `ammo_belt.png` — Munitionsband

**Target:** `assets/items/ammo_belt.png` · **Größe:** 1024×1024 (1:1) · **BG-Removal: ja**

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett. Mindestens 1024×1024 px.
- Klare zentrale Silhouette, gut lesbar auch klein (48 px).

Bild-Prompt:
Single icon on plain solid white background: a coiled steampunk ammunition belt of polished brass shells linked by riveted copper plates, the chain forming a tight horizontal "S" shape in the center of the frame, each shell with a small primer cap visible. Front-facing slight isometric tilt for readability. Warm metallic gleam. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

---

### C9: `armor_plate.png` — Panzerung

**Target:** `assets/items/armor_plate.png` · **Größe:** 1024×1024 (1:1) · **BG-Removal: ja**

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett. Mindestens 1024×1024 px.
- Klare zentrale Silhouette, gut lesbar auch klein (48 px).

Bild-Prompt:
Single icon on plain solid white background: a heavy riveted brass-and-iron armor plate, rectangular with rounded corners, covered in raised hex-pattern reinforcement, large iron rivets at each corner, brass edge trim, a small inscribed maker's mark in the center. Front-facing slightly tilted three-quarter view. Warm metallic surface with visible patina and wear. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and iron steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

---

### C10: `grappling_hook.png` — Wurfanker

**Target:** `assets/items/grappling_hook.png` · **Größe:** 1024×1024 (1:1) · **BG-Removal: ja**

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett. Mindestens 1024×1024 px.
- Klare zentrale Silhouette, gut lesbar auch klein (48 px).

Bild-Prompt:
Single icon on plain solid white background: a brass-and-iron grappling hook with four curved claws, mounted on a thick coiled cable wrapped around a small brass drum, the hook poised dramatically in mid-frame. Brass fittings, iron sharp claws, leather grip on the drum handle. Slight isometric tilt for readability. Warm metallic gleam. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and iron steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

---

### C11: `stabilizer_brace.png` — Stabilisator-Strebe

**Target:** `assets/items/stabilizer_brace.png` · **Größe:** 1024×1024 (1:1) · **BG-Removal: ja**

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett. Mindestens 1024×1024 px.
- Klare zentrale Silhouette, gut lesbar auch klein (48 px).

Bild-Prompt:
Single icon on plain solid white background: a heavy brass stabilizer brace shaped like an X-cross truss, with thick brass beams meeting in a central pivot hub, large iron bolts at each end, small dampener springs visible at the joints. Front-facing slightly tilted view. Solid mechanical look — clearly weight-bearing structural part. Warm metallic gleam. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and iron steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

---

### C12: `grenade_launcher.png` — Granat-Werfer

**Target:** `assets/items/grenade_launcher.png` · **Größe:** 1024×1024 (1:1) · **BG-Removal: ja**

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett. Mindestens 1024×1024 px.
- Klare zentrale Silhouette, gut lesbar auch klein (48 px).

Bild-Prompt:
Single icon on plain solid white background: a stout steampunk shoulder-fired grenade launcher with a single wide brass barrel, a heavy iron underbarrel chamber for the round, wooden grip and stock, a brass sight rail with engraved markings on top. Side view at slight three-quarter angle, the barrel pointing toward upper-right of the frame. Warm metallic gleam, slight steam wisp from the chamber breech. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and iron steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

---

### B5: `boss_schwarze_lokomotive.png` — Schwarze Lokomotive Kraschnit

**Target:** `assets/bosses/boss_schwarze_lokomotive.png` · **Größe:** 1536×1920 (4:5)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images, not a grid layout. One subject, one frame,
exactly the requested aspect ratio.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG, KEIN transparenter Hintergrund, KEIN Alpha-Channel-Tweak.
- Aspektverhältnis exakt 4:5 einhalten.
- Mindestens 1536 px Kantenlänge.
- KEIN Schachbrett-Hintergrund.

Bild-Prompt:
A monstrous wandering steampunk warlocomotive viewed from a low angle three-quarter front: an enormous blackened iron and brass locomotive engine has been heavily militarized — multiple brass cannon barrels protrude from armored side casemates, twin riveted gun turrets atop the boiler dome, ammunition belt-feeds running visibly along the flanks, a tall ribbed smokestack belching dense black smoke. The cowcatcher at the front is reinforced with iron spikes and clawed brass plates. No conductor is visible — windows of the cabin are dark and empty. It rolls on heavy iron wheels along weathered rails that disappear into a smoke-shrouded ruined cityscape behind. Warm orange ember glow leaks from gaps in the boiler plating, contrasting with cold blue-grey dawn light. Heavy, oppressive, mechanical, intimidating but impressive — a fortress on rails.

Stil: warm orange ember glow contrasted with cold blue-grey dawn, blackened iron with brass and copper highlights, heavy patina and battle damage, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, oppressive mechanical menace, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 4:5
```

---

### Z11: `bg_sandbox.png` — Schmiede-Probe (Werkstatt-Halle ohne Charakter)

**Target:** `assets/backgrounds/bg_sandbox.png` · **Größe:** 1920×1080 (16:9)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 16:9 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG, KEIN transparenter Hintergrund.
- Aspektverhältnis exakt 16:9.
- Mindestens 1920 px Breite.
- KEIN Schachbrett.

Bild-Prompt:
Wide cinematic interior of a vast empty steampunk workshop hall: rows of long wooden workbenches stretch into the middle distance, each piled with assorted brass items, tools, gears, and unfinished mechanisms. Tall arched windows along the upper walls let in cool blue-grey daylight from outside. Warm amber lantern light hangs from the iron ceiling beams above the benches. Pipes and conduits run along the walls. The center of the room is intentionally open and uncluttered (the workshop floor) so UI panels can overlay it; rich visual detail sits along both side walls and the upper edges (lantern fixtures, conduits, hanging tool racks). Sense of possibility — every item the maker could imagine is here, waiting. No human figures.

Stil: warm amber lantern light from above with cool blue-grey daylight accent through windows, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, sense of creative possibility, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 16:9
```

---

### P1–P13: Perk-Icons (13 Anfragen)

Quadratisch, schmuckartig, jeweils ein klares zentrales Hauptmotiv. Sie erscheinen als 48–64-px-Icons auf dem Perk-Auswahl-Screen.

#### P1: `perk_notvorrat.png` — Notvorrat

**Target:** `assets/ui/perks/perk_notvorrat.png` · **1024×1024** · **BG-Removal: ja**

```
Generate exactly ONE single image. Not a sheet, not a collage. One subject, one frame, 1:1 aspect.
TECHNISCHE VORGABEN:
- Plain solid white background (NOT transparent). KEIN Schachbrett. 1024×1024 px.
- Klare zentrale Silhouette, gut lesbar bei 48 px.

Bild-Prompt:
Single icon on plain solid white background: an open brass-bound wooden supply chest brimming with bandages, vials of red restorative tonic, copper repair clamps, and a single glowing health-sigil engraved on the lid. Slight isometric tilt. Warm metallic gleam. The area around the icon is plain solid white.

Stil: warm dark amber lighting, brass and copper steampunk materials with patina, hand-painted illustration like Bastion concept art, no logos, no text, NOT photorealistic, NOT cartoon.
--ar 1:1
```

#### P2: `perk_schnellfeuer.png` — Schnellfeuer

```
Generate exactly ONE single image. Not a sheet, not a collage. One subject, one frame, 1:1 aspect.
[Standard TECHNISCHE VORGABEN]

Bild-Prompt:
Single icon on plain solid white background: three crossed brass cannon barrels in dynamic motion-blur lines, with small puffs of smoke at each muzzle, suggesting rapid sequential firing. Slight isometric tilt. Warm metallic gleam. The area around the icon is plain solid white.
[Standard Stil]
--ar 1:1
```

#### P3: `perk_aetherantrieb.png` — Aetherantrieb

```
Single icon on plain solid white background: a fast-spinning brass turbine disc with motion lines radiating outward, glowing blue aether-energy at the center, copper coils wrapped around the rim. Front-facing view. The area around the icon is plain solid white.
```

#### P4: `perk_druckverwerter.png` — Druckverwerter

```
Single icon on plain solid white background: a stylized pressure gauge with the needle pinned to red-zone maximum, a stream of compressed steam shooting upward from the top valve, brass body with engraved scale markings. The area around the icon is plain solid white.
```

#### P5: `perk_werkbank_mogul.png` — Werkbank-Mogul

```
Single icon on plain solid white background: a small pile of stacked resonance crystals (cyan-blue glow) on top of a brass workbench surface with crossed wrenches behind, and a discount-tag with a percentage symbol on a leather string in the foreground. The area around the icon is plain solid white.
```

#### P6: `perk_gluecksrad.png` — Glücksrad

```
Single icon on plain solid white background: a brass-rimmed roulette-style wheel of fortune with four item-slot pictograms (cannon, gear, vial, shield) on its rim, central pointer needle, ornate scrollwork around the edge. Front-facing view. The area around the icon is plain solid white.
```

#### P7: `perk_reaktiv_kette.png` — Reaktiv-Kette

```
Single icon on plain solid white background: three brass cog-gears arranged in a triangle, connected by glowing copper-conduit chains that arc diagonally between them, sparks at each connection point. Slight isometric tilt. The area around the icon is plain solid white.
```

#### P8: `perk_eisenhaut.png` — Eisenhaut

```
Single icon on plain solid white background: a heavy heraldic-style shield made of riveted iron plates with brass studs and a central glowing red-gem heart symbol indicating "low-HP activation". Front-facing view. The area around the icon is plain solid white.
```

#### P9: `perk_marktkenner.png` — Marktkenner

```
Single icon on plain solid white background: a leather coin-purse with a few gold coins spilling out, beside a brass merchant's scale with the pans balanced, a small parchment tag showing a discount stroke through. The area around the icon is plain solid white.
```

#### P10: `perk_pluendererglueck.png` — Plündererglück

```
Single icon on plain solid white background: a small open chest of mixed items (a vial, a gear, a cog) with a four-leaf brass clover charm hanging from its lid, slight golden sparkle aura. The area around the icon is plain solid white.
```

#### P11: `perk_kritstrom.png` — Krit-Strom

```
Single icon on plain solid white background: a stylized crosshair-target made of brass with an arrow striking the bullseye, golden energy bolts radiating outward from the impact, a small "×2.5" engraved marking visible on the brass rim. The area around the icon is plain solid white.
```

#### P12: `perk_brand_stapel.png` — Brand-Stapel

```
Single icon on plain solid white background: three stacked stylized brass flame-icons piled on top of each other, with a small upward-arrow indicating accumulation, warm orange flame glow at the tips. Front-facing view. The area around the icon is plain solid white.
```

#### P13: `perk_zeitloser_mechanismus.png` — Zeitloser Mechanismus

```
Single icon on plain solid white background: an ornate brass pocket watch with the cover open, the watch face frozen on twelve-o'clock and the hour hand glowing faintly blue with aether-energy, decorative scrollwork around the casing. Front-facing view. The area around the icon is plain solid white.
```

---

## 6. Implementations-Reihenfolge (Vorschlag)

1. **Kanonenmeister** (Klasse + 6 Items + Char-Passive) — kleinste self-contained Erweiterung, gibt Spielern sofort was Neues
2. **Schwarze Lokomotive** (Boss + Set-Bonus + Phase-2-Mechanik) — nutzt teilweise die neuen Items
3. **Perk-System** (UI + 13 Perks + Unlock-Tracking) — größte Code-Veränderung, beeinflusst alle Klassen
4. **Sandbox-Modus** (eigene Scene + Item-Picker) — entkoppelt, kann zuletzt
5. **Asset-Generation** — parallel zu jedem Schritt

---

## 7. Asset-Total für diese Expansion

**Anfragen total: 22**
- A: 1 (Char-Portrait)
- C: 6 (neue Items)
- B: 1 (neuer Boss)
- Z: 1 (Sandbox-Hintergrund)
- P: 13 (Perk-Icons)

---

**Stand:** 2026-05-26 · **Konzept-Version:** v1
