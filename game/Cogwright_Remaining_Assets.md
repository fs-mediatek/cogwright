# Cogwright — Verbleibende Assets (v3, anti-collage)

> **Workflow:** Pro Asset **einen frischen ChatGPT-Chat**. Den Block unter "Copy block" 1:1 reinkopieren. Eine Anfrage = ein Bild.

**Warum:** Wenn du mehrere Prompts in einer Nachricht schickst, packt ChatGPT alle in ein Sheet. Jeder Block hier hat oben einen expliziten Anti-Collage-Guard.

**Post-Processing pro Asset-Typ (nach Download):**
- **Charaktere / Bosse / City-Backgrounds / Partikel**: PNG direkt nutzen (Hintergrund ist Teil des Bildes)
- **Items / Map-Icons / UI-Frames / Tower-Floors**: weißen Hintergrund mit `Remove-WhiteBackground` entfernen, dann reimport

**Filename strict einhalten** — beim Download in den Browser die Datei umbenennen falls nötig.

**Target-Pfade:**
- Items → `assets/items/`
- Charaktere → `assets/characters/`
- Bosse → `assets/bosses/`
- Backgrounds → `assets/backgrounds/`
- UI-Frames → `assets/ui/frames/`
- Map-Knoten → `assets/ui/map_nodes/`
- Partikel → `assets/particles/`
- Tower → `assets/tower/`

---

## Reihenfolge der Anfragen

Empfohlen: A → B → C → D → E → F → G → H. Jede Sektion einzeln durchziehen, dann nächste.

Nach jedem Asset: PNG ins richtige `assets/`-Unterverzeichnis kopieren. Nach einem Sektions-Pass: `--import --quit` für Reimport.

---

# A — Charakter-Portraits (3 Anfragen)

## A1: `char_pressure.png` — Druckmeister

**Target:** `assets/characters/char_pressure.png` · **Größe:** 1536×1920 (4:5)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images, not a grid layout. One subject, one frame,
exactly the requested aspect ratio.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG, KEIN transparenter Hintergrund, KEIN Alpha-Channel-Tweak.
- Aspektverhältnis exakt 4:5 einhalten.
- Mindestens 1536 px Kantenlänge.
- KEIN Schachbrett-Hintergrund, KEIN halbtransparenter Look.

Bild-Prompt:
Steampunk character portrait: an androgynous slim middle-aged pressure-master engineer, brass multi-lens goggles pushed up onto the forehead revealing calculating blue-grey eyes, fitted dark green vest over off-white shirt with rolled sleeves, brass pressure gauge clipped to the belt, holding a polished brass adjustable wrench across the chest, analytical methodical expression. Set against a dark warm steampunk workshop interior background with subtle brass pipes and pressure tubes in the back, soft amber glow from off-frame furnace. Chest-up framing, looking slightly off-camera. The workshop background fills the entire frame.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 4:5
```

## A2: `char_blunt.png` — Schmiedin

**Target:** `assets/characters/char_blunt.png` · **Größe:** 1536×1920 (4:5)

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
Steampunk character portrait: a sturdy female blacksmith with strong shoulders, leather apron over a brown work blouse, sleeves rolled to the elbows showing muscular forearms, a large iron forge hammer casually resting on one shoulder, a single brass earring, soot-smudged cheeks, determined stoic expression. Background: a dark forge interior with glowing orange embers, rising sparks, and a brass-rimmed anvil visible in the back. Chest-up framing. The forge background fills the entire frame.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 4:5
```

## A3: `char_reactive.png` — Saboteur

**Target:** `assets/characters/char_reactive.png` · **Größe:** 1536×1920 (4:5)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images, not a grid layout. One subject, one frame,
exactly the requested aspect ratio.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG, KEIN transparenter Hintergrund.
- Aspektverhältnis exakt 4:5.
- Mindestens 1536 px Kantenlänge.

Bild-Prompt:
Steampunk character portrait: an androgynous lean hooded saboteur half in shadow, wearing a brass mechanical half-mask over the lower face revealing only watchful intense eyes above, dark canvas hood pulled forward, fingerless leather gloves, holding a primed steel spring-trap device in one hand. Background: a dark alleyway or workshop backroom with faint steam wisps and a single brass pipe-valve glowing dimly. Chest-up framing, partially backlit silhouette. The dark background fills the entire frame.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 4:5
```

---

# B — Boss-Illustrationen (4 Anfragen)

## B1: `boss_uhrwerk_hexe.png` — Uhrwerk-Hexe

**Target:** `assets/bosses/boss_uhrwerk_hexe.png` · **Größe:** 1536×1920 (4:5)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images, not a grid layout. One subject, one frame,
exactly the requested aspect ratio.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG, KEIN transparenter Hintergrund.
- Aspektverhältnis exakt 4:5.
- Mindestens 1536 px Kantenlänge.

Bild-Prompt:
Steampunk boss illustration: a distorted clockwork witch figure standing in a dark hall, an enormous antique brass clock face replaces where her head should be with several independently-rotating mechanical hands and exposed gears behind cracked glass. Torn dark violet robe revealing visible gear-mechanism innards in chest and abdomen. Long thin brass tentacle-like fingers. Cold blue magical sparks crackle around her. Eerie unsettling pose. Background: gothic clocktower interior with hanging brass pendulums and dim cold blue light source from one side. Imposing dominant silhouette. The clocktower background fills the entire frame.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 4:5
```

## B2: `boss_funken_tyrann.png` — Funken-Tyrann

**Target:** `assets/bosses/boss_funken_tyrann.png` · **Größe:** 1536×1920 (4:5)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images, not a grid layout. One subject, one frame,
exactly the requested aspect ratio.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG, KEIN transparenter Hintergrund.
- Aspektverhältnis exakt 4:5.
- Mindestens 1536 px Kantenlänge.

Bild-Prompt:
Steampunk boss illustration: a hulking war-robot tyrant towering over the ground, assembled from welded scrap industrial items, mismatched brass armor plating with rivets and visible weld seams. Burning amber eye-lenses glare from a heavy slot-visor. Continuous showers of sparks and embers fall from joints. Heavy industrial limbs end in claw-like grasping hands. Background: a dark scrap-yard furnace hall with intense orange fire glow from open furnace doors behind him. Intimidating wide-stanced posture. The furnace background fills the entire frame.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 4:5
```

## B3: `boss_stiller_maschinist.png` — Stiller Maschinist

**Target:** `assets/bosses/boss_stiller_maschinist.png` · **Größe:** 1536×1920 (4:5)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images, not a grid layout. One subject, one frame,
exactly the requested aspect ratio.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG, KEIN transparenter Hintergrund.
- Aspektverhältnis exakt 4:5.
- Mindestens 1536 px Kantenlänge.

Bild-Prompt:
Steampunk boss illustration: an eerily calm humanoid figure standing motionless in worn mechanic overalls and oil-stained leather apron. The face is completely featureless — replaced by a single bright glowing miner's lamp where the head should be, casting a downward cone of warm white light. Faint steam wisps trail from the collar. Gloved hands hold a small wrench in one and a long pipe-wrench weapon in the other. Background: dark abandoned factory floor with faint pipes and machinery in the shadows, only the lamp-head provides illumination. Unsettlingly still silhouette. The factory background fills the entire frame.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 4:5
```

## B4: `boss_oelbaron_krasnik.png` — Ölbaron Krasnik

**Target:** `assets/bosses/boss_oelbaron_krasnik.png` · **Größe:** 1536×1920 (4:5)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images, not a grid layout. One subject, one frame,
exactly the requested aspect ratio.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG, KEIN transparenter Hintergrund.
- Aspektverhältnis exakt 4:5.
- Mindestens 1536 px Kantenlänge.

Bild-Prompt:
Steampunk boss illustration: an opulent overweight oil baron in a glossy oil-stained dark robe with brass embellishments and gold trim. Multiple thick mechanical brass tentacle-arms emerge from his back, ending in claws and tools, some dripping dark oil. Stacked monocles on his face. Decadent menacing expression with a greasy smirk. Background: a dimly-lit oil-baron's office with brass-rimmed barrels of oil, a sickly green-yellow lantern lighting him from below creating long shadows upward. Imposing wide silhouette dominating the frame. The office background fills the entire frame.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 4:5
```

---

# C — Items (6 Anfragen) — **Weißer Hintergrund, wird hinterher entfernt**

## C1: `alchemist_flask.png`

**Target:** `assets/items/alchemist_flask.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett. Die Fläche um das Objekt ist sauberes Weiß.
- Mindestens 1024×1024 px.

Bild-Prompt:
Single item icon on plain solid white background: a round-bottomed laboratory glass flask with a long thin neck and brass-rimmed stopper, glowing purple-green bubbling liquid inside, small wisps of vapor escaping the top, an antique gilded brass label ring around the neck, dramatic glass refraction picking up warm amber rim light from upper right. Centered composition. The area around the flask is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## C2: `firebomb.png`

**Target:** `assets/items/firebomb.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.

Bild-Prompt:
Single item icon on plain solid white background: a small round brass-cased throwable bomb with a short burning fuse showering bright orange sparks, a riveted seam around the equator, dark soot stains on the brass. Slight motion blur on the sparks suggesting it has just been thrown. Centered composition. The area around the bomb is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## C3: `ice_diffuser.png`

**Target:** `assets/items/ice_diffuser.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.

Bild-Prompt:
Single item icon on plain solid white background: a vertical brass canister with horizontal cooling fins along the body, pale cold blue mist exhaling from a top nozzle, small ice crystals forming on the lower fins, a frosted glass viewport on the front showing internal coolant. Centered composition. The area around the canister is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## C4: `steel_aegis.png`

**Target:** `assets/items/steel_aegis.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.

Bild-Prompt:
Single item icon on plain solid white background: a forged steel kite shield with bronze banding around the edges, large rivets along the inner border, a faintly glowing engraved cogwheel emblem in the center, scratched and battle-worn surface. Centered composition. The area around the shield is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## C5: `phosphor_lobber.png`

**Target:** `assets/items/phosphor_lobber.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.

Bild-Prompt:
Single item icon on plain solid white background: a grenade-shaped throwable projectile with riveted brass casing and a glowing yellow-green inner phosphor compound visible through small viewports, a leather-wrapped grip-handle, slight emanating sickly green haze. Centered composition. The area around the projectile is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## C6: `aegis_pump.png`

**Target:** `assets/items/aegis_pump.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.

Bild-Prompt:
Single item icon on plain solid white background: a brass pressure pump device with a vertical cylindrical chamber and a deployable horizontal shield plate hinged on top, a pressure gauge showing reading, steam venting from side valves, scratched mechanical look. Centered composition. The area around the pump is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

---

# D — City-Backgrounds (3 Anfragen) — Bild komplett füllen

## D1: `bg_city_far_buildings.png`

**Target:** `assets/backgrounds/bg_city_far_buildings.png` · **Größe:** 2048×1024 (2:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One scene, one frame, 2:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG, das gesamte Bild ist gefüllt.
- KEINE Transparenz, KEIN Schachbrett.
- Aspektverhältnis exakt 2:1.
- Mindestens 2048 px Breite.
- Horizontale Tile-Edge: linke und rechte Bildkante sollen nahtlos aneinanderpassen.

Bild-Prompt:
Steampunk industrial parallax background, FAR distance layer: distant city silhouette of tall factory chimneys, brass-domed buildings, ornate factory rooftops, layered atmospheric haze. Faint warm window lights tiny in the distance. Very dark warm tone overall — silhouettes against a slightly lighter hazy sky. Horizontally tilable seamless edges. The entire frame is filled with the cityscape and sky.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 2:1
```

## D2: `bg_city_mid_buildings.png`

**Target:** `assets/backgrounds/bg_city_mid_buildings.png` · **Größe:** 2048×1024 (2:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One scene, one frame, 2:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG, das gesamte Bild ist gefüllt.
- KEINE Transparenz, KEIN Schachbrett.
- Aspektverhältnis exakt 2:1.
- Mindestens 2048 px Breite.
- Horizontale Tile-Edge: linke und rechte Bildkante nahtlos.

Bild-Prompt:
Steampunk industrial parallax background, MID distance layer: mid-distance Victorian-industrial brick buildings with brass-detailed window frames and glowing warm windows, ornate brass signage hanging from poles, rooftop pipes and steam vents emitting small wisps. Warmer and more detailed than the far layer, with visible brick texture and brass trim. Horizontally tilable seamless edges. The entire frame is filled with buildings and a sky strip at the top.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 2:1
```

## D3: `bg_city_foreground.png`

**Target:** `assets/backgrounds/bg_city_foreground.png` · **Größe:** 2048×1024 (2:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One scene, one frame, 2:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG, das gesamte Bild ist gefüllt.
- KEINE Transparenz, KEIN Schachbrett.
- Aspektverhältnis exakt 2:1.
- Mindestens 2048 px Breite.
- Horizontale Tile-Edge: linke und rechte Bildkante nahtlos.

Bild-Prompt:
Steampunk industrial parallax background, FOREGROUND layer: close-up of thick brass-trimmed pipes running horizontally, riveted steel struts, occasional small steam vents and oil-stained brick masonry. Dark warm tones, the darkest of the three parallax layers. The lower 2/3 of the frame is the foreground structure, the upper 1/3 fades into the layer behind. Horizontally tilable seamless edges. The entire frame is filled.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 2:1
```

---

# E — Map-Knoten-Icons (7 Anfragen) — **Weißer Hintergrund**

## E1: `map_start.png`

**Target:** `assets/ui/map_nodes/map_start.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.

Bild-Prompt:
Single small icon on plain solid white background: an ornate brass directional arrow pointing forward and slightly up, with a partially open brass workshop gate hatch behind it suggesting departure. Designed to fit centered inside a circular frame at small sizes. Must be instantly readable when scaled down to 48x48 pixels. Centered composition. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## E2: `map_combat.png`

**Target:** `assets/ui/map_nodes/map_combat.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.

Bild-Prompt:
Single small icon on plain solid white background: crossed brass wrench and forge hammer mechanical tools at a slight X angle, simple readable silhouette. Designed to fit centered inside a circular frame at small sizes. Must be instantly readable when scaled down to 48x48 pixels. Centered composition. The area around the tools is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## E3: `map_elite.png`

**Target:** `assets/ui/map_nodes/map_elite.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.

Bild-Prompt:
Single small icon on plain solid white background: an ominous mechanical skull made of dark iron with brass plating, rivets along the seams, hollow glowing red eye-sockets. Designed to fit centered inside a circular frame at small sizes. Must be instantly readable when scaled down to 48x48 pixels. Centered composition. The area around the skull is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## E4: `map_boss.png`

**Target:** `assets/ui/map_nodes/map_boss.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.

Bild-Prompt:
Single small icon on plain solid white background: an ornate brass crown with an embedded antique clock face at the center, faint dangerous red inner glow emanating from the clock face. Regal but threatening. Designed to fit centered inside a circular frame at small sizes. Must be instantly readable when scaled down to 48x48 pixels. Centered composition. The area around the crown is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## E5: `map_shop.png`

**Target:** `assets/ui/map_nodes/map_shop.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.

Bild-Prompt:
Single small icon on plain solid white background: a large brass cogwheel with a single gold coin standing in front of it leaning slightly to one side, friendly merchant feel. Designed to fit centered inside a circular frame at small sizes. Must be instantly readable when scaled down to 48x48 pixels. Centered composition. The area around the cog and coin is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## E6: `map_heal.png`

**Target:** `assets/ui/map_nodes/map_heal.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.

Bild-Prompt:
Single small icon on plain solid white background: a mechanical red heart framed by brass cogwheel-mechanism segments, a small wrench or screwdriver crossed diagonally behind it suggesting repair/maintenance. Warm red and brass glow. Designed to fit centered inside a circular frame at small sizes. Must be instantly readable when scaled down to 48x48 pixels. Centered composition. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## E7: `map_event.png`

**Target:** `assets/ui/map_nodes/map_event.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.

Bild-Prompt:
Single small icon on plain solid white background: a question mark shape formed entirely from interlocking brass pipes and rivets, with a small steam wisp escaping from the top of the question mark. Mysterious mood. Designed to fit centered inside a circular frame at small sizes. Must be instantly readable when scaled down to 48x48 pixels. Centered composition. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

---

# F — Tower-Etagen (3 Anfragen) — **Weißer Hintergrund**

## F1: `tower_floor_foundation.png`

**Target:** `assets/tower/tower_floor_foundation.png` · **Größe:** 1536×768 (2:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 2:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1536 px Breite.

Bild-Prompt:
Single horizontal architectural sprite on plain solid white background: the foundation floor of a steampunk workshop tower. Solid stone masonry with large brass rivets along the seams, heavy reinforcement struts, impression of weight and stability. Three slot apertures visible across the front for item placement (small recessed brass-rimmed dark openings, evenly spaced). Symmetrical front-on view. Centered composition. The area around the structure is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 2:1
```

## F2: `tower_floor_workshop.png`

**Target:** `assets/tower/tower_floor_workshop.png` · **Größe:** 1536×768 (2:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 2:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1536 px Breite.

Bild-Prompt:
Single horizontal architectural sprite on plain solid white background: the workshop floor of a steampunk tower. Dark wooden panels with workbenches, exposed brass pipes and fittings, productive activity feel. Three slot apertures visible across the front for item placement (recessed brass-rimmed openings, evenly spaced). Faint orange glow from internal furnace mechanisms. Symmetrical front-on view. Centered composition. The area around the structure is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 2:1
```

## F3: `tower_floor_top.png`

**Target:** `assets/tower/tower_floor_top.png` · **Größe:** 1536×768 (2:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 2:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1536 px Breite.

Bild-Prompt:
Single horizontal architectural sprite on plain solid white background: the observatory top floor of a steampunk tower. Lighter wooden construction with brass-framed glass observatory window and small telescope platform. Airy and observant feel. Three slot apertures visible across the front for item placement (recessed brass-rimmed openings, evenly spaced). A copper chimney with small steam wisps rising from the very top. Symmetrical front-on view. Centered composition. The area around the structure is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 2:1
```

---

# G — UI-Frames (7 Anfragen, 9-slice-tauglich) — **Weißer Hintergrund**

## G1: `ui_button_default.png`

**Target:** `assets/ui/frames/ui_button_default.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.
- 9-slice-tauglich: Ecken detailreich, Mittelteil stretch-fähig (gleichmäßiges Muster).

Bild-Prompt:
Single UI button design on plain solid white background: a brass-bordered rectangular panel in DEFAULT state, with small rivets at each of the four corners, dark wood face in the center, slightly inset clean look. Designed for 9-slice scaling: the middle area is a consistent stretchable pattern, the corners are ornate. Centered composition. The area around the button is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## G2: `ui_button_hover.png`

**Target:** `assets/ui/frames/ui_button_hover.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.
- 9-slice-tauglich.

Bild-Prompt:
Single UI button design on plain solid white background: a brass-bordered rectangular panel in HOVER state, with rivets at corners, warmly highlighted dark wood face, subtle warm amber glow around the brass border, slightly raised look compared to the default state. Designed for 9-slice scaling: the middle area stretchable, the corners ornate. Centered composition. The area around the button is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## G3: `ui_button_pressed.png`

**Target:** `assets/ui/frames/ui_button_pressed.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.
- 9-slice-tauglich.

Bild-Prompt:
Single UI button design on plain solid white background: a brass-bordered rectangular panel in PRESSED state, with rivets at corners, deeply inset depressed dark wood face, soft inner shadow making it look pushed-in compared to the default state. Designed for 9-slice scaling: the middle area stretchable, the corners ornate. Centered composition. The area around the button is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## G4: `ui_frame_common.png`

**Target:** `assets/ui/frames/ui_frame_common.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.
- 9-slice-tauglich.

Bild-Prompt:
Single card frame design on plain solid white background, COMMON rarity tier: a rectangular frame with a grey-bronze metallic border, small rivets and simple gear motifs in the corners, restrained ornamentation, dark wooden interior visible through the center cutout. Designed for 9-slice scaling: the corners ornate, the middle border-edge stretchable. Centered composition. The area outside the frame is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## G5: `ui_frame_uncommon.png`

**Target:** `assets/ui/frames/ui_frame_uncommon.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.
- 9-slice-tauglich.

Bild-Prompt:
Single card frame design on plain solid white background, UNCOMMON rarity tier: a rectangular frame with a greenish-bronze metallic border, rivets and gear motifs in the corners, slightly more ornament than common, subtle green metallic patina visible on the metal, dark wooden interior visible through the center cutout. Designed for 9-slice scaling. Centered composition. The area outside the frame is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## G6: `ui_frame_rare.png`

**Target:** `assets/ui/frames/ui_frame_rare.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.
- 9-slice-tauglich.

Bild-Prompt:
Single card frame design on plain solid white background, RARE rarity tier: a rectangular frame with a blue-bronze metallic border, detailed brass filigree and gear motifs in the corners, a subtle inner blue glow tracing the inside edge, dark wooden interior visible through the center cutout. Designed for 9-slice scaling. Centered composition. The area outside the frame is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## G7: `ui_frame_legendary.png`

**Target:** `assets/ui/frames/ui_frame_legendary.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.
- 9-slice-tauglich.

Bild-Prompt:
Single card frame design on plain solid white background, LEGENDARY rarity tier: a rectangular frame with a royal purple and gold metallic border, elaborate brass filigree and small jewel-like crystal accents in the corners, soft outer purple glow halo, dark wooden interior with subtle inner light visible through the center cutout. Designed for 9-slice scaling. Centered composition. The area outside the frame is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

---

# H — Partikel-Texturen (5 Anfragen) — **Solider mittel-grauer Hintergrund (RGB 80,80,80)**

Hintergrund NICHT entfernen — Partikel werden im Spiel additiv geblendet, der mittelgraue Background verschwindet dadurch automatisch.

## H1: `particle_spark.png`

**Target:** `assets/particles/particle_spark.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid medium-grey RGB(80,80,80).
- KEINE Transparenz, KEIN weißer Hintergrund, KEIN Schachbrett.
- Mindestens 512×512 px (besser 1024×1024).

Bild-Prompt:
Single small particle sprite on plain solid medium-grey background (RGB 80,80,80): a single bright warm amber spark with cross-shaped light rays radiating outward, soft outer falloff, suitable for additive blending in a particle system. Centered composition. The area around the spark is solid medium-grey, not white.

Stil: warm amber glow, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon.

--ar 1:1
```

## H2: `particle_steam.png`

**Target:** `assets/particles/particle_steam.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid medium-grey RGB(80,80,80).
- KEINE Transparenz, KEIN weißer Hintergrund.
- Mindestens 512×512 px.

Bild-Prompt:
Single small particle sprite on plain solid medium-grey background (RGB 80,80,80): a soft white-blue steam cloud puff with diffuse fluffy edges, slight inner highlight, suitable for additive or multiplied blending. Centered composition. The area around the puff is solid medium-grey, not white.

Stil: soft white-blue tones, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon.

--ar 1:1
```

## H3: `particle_smoke.png`

**Target:** `assets/particles/particle_smoke.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid medium-grey RGB(80,80,80).
- KEINE Transparenz, KEIN weißer Hintergrund.
- Mindestens 512×512 px.

Bild-Prompt:
Single small particle sprite on plain solid medium-grey background (RGB 80,80,80): a grayish-brown smoke puff with diffuse irregular edges, warm undertone, slightly darker than steam, suitable for use in a particle system. Centered composition. The area around the smoke is solid medium-grey, not white.

Stil: warm grey-brown tones, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon.

--ar 1:1
```

## H4: `particle_oil_drop.png`

**Target:** `assets/particles/particle_oil_drop.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid medium-grey RGB(80,80,80).
- KEINE Transparenz, KEIN weißer Hintergrund.
- Mindestens 512×512 px.

Bild-Prompt:
Single small particle sprite on plain solid medium-grey background (RGB 80,80,80): a dark glossy oil droplet teardrop shape with a single bright highlight, slightly viscous reflective appearance. Centered composition. The area around the droplet is solid medium-grey, not white.

Stil: dark glossy reflective surface, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon.

--ar 1:1
```

## H5: `particle_splinter.png`

**Target:** `assets/particles/particle_splinter.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid medium-grey RGB(80,80,80).
- KEINE Transparenz, KEIN weißer Hintergrund.
- Mindestens 512×512 px.

Bild-Prompt:
Single small particle sprite on plain solid medium-grey background (RGB 80,80,80): a small angular metallic shard with sharp pointed ends, slight reflective highlight, dark metallic gray with subtle warm tone. Centered composition. The area around the shard is solid medium-grey, not white.

Stil: dark metallic reflective, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon.

--ar 1:1
```

---

# Z — Hero-Backgrounds (zusätzlich) — **Vollbild, KEIN BG-Removal**

## Z4: `bg_workshop.png` — Werkstatt-Hintergrund (Meta-Progression)

**Target:** `assets/backgrounds/bg_workshop.png` · **Größe:** 1920×1080 (16:9)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 16:9 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG, KEIN transparenter Hintergrund.
- Aspektverhältnis exakt 16:9.
- Mindestens 1920 px Breite.
- KEIN Schachbrett, KEIN halbtransparenter Look.

Bild-Prompt:
Wide cinematic establishing shot of an interior steampunk workshop, viewed from the center as if standing inside: massive brass-pipework along the side walls, a tall ornate workbench in the middle distance with a glowing forge-anvil and clockwork tools laid out, dangling ceiling chains with hanging gears, blueprint papers pinned to side beams, soft warm amber-orange light radiating from the forge, deep brown wooden floor planks, faint floating dust motes in the air. Atmospheric, inviting, slightly mysterious. The composition leaves the center-middle area visually calmer (less detail) so UI cards can be overlaid in front; visual weight is concentrated at the lower-left and upper-right corners.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 16:9
```

## Z5: `bg_stats.png` — Statistiken (Archiv/Logbuch)

**Target:** `assets/backgrounds/bg_stats.png` · **Größe:** 1920×1080 (16:9)

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
Wide cinematic shot of a steampunk archivist's study viewed from a low angle: tall dark wooden bookshelves filled with leather-bound tomes and rolled blueprints, a large brass-trimmed central desk in the middle distance covered in open ledgers, ink wells, brass calipers, an old typewriter-like calculation device, and stacks of yellowed parchment. A warm amber gas lamp hangs over the desk casting soft pools of light, faint dust motes floating in the air. The middle-vertical band of the image is intentionally darker and visually calm so a UI list can overlay it; visual interest sits in the upper corners and along the sides. Cozy, scholarly, slightly mysterious atmosphere.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 16:9
```

## Z7: `bg_victory.png` — Run-Sieg (Triumph)

**Target:** `assets/backgrounds/bg_victory.png` · **Größe:** 1920×1080 (16:9)

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
Wide cinematic triumphant aftermath scene: a victorious steampunk tower stands proudly on a hilltop overlooking a smoky industrial valley at golden hour, copper and brass plating gleaming with reflected amber sunset. Soft warm light streams dramatically from behind the tower, casting long heroic shadows forward. Tiny celebratory steam wisps rise from the tower's top. Defeated boss machine wreckage is faintly visible in the lower foreground (broken cogs, twisted brass) — present but not graphic. The horizon glows with hopeful amber-orange. The middle band of the image is intentionally calmer (mostly sky and atmosphere) so UI text can overlay it; visual interest sits along the bottom and sides.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, heroic mood, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 16:9
```

## Z8: `bg_defeat.png` — Run-Niederlage (Turm zerschlagen)

**Target:** `assets/backgrounds/bg_defeat.png` · **Größe:** 1920×1080 (16:9)

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
Wide cinematic somber aftermath scene: a ruined collapsed steampunk tower viewed from a low angle, leaning broken to one side with twisted brass beams exposed, pieces of fallen masonry and bent cogwheels scattered across cold dark earth at the base, soft cool grey-blue dawn light from a low horizon, faint cold mist drifting low across the ground, dying embers glowing faintly in the lower-foreground rubble. Melancholic but dignified — a fallen workshop that fought hard. The middle band of the image is intentionally calm (cloudy sky) so UI text can overlay it; visual weight sits along the bottom (rubble) and upper-right (faint cold sunrise).

Stil: cool dim blue-grey dawn lighting with faint warm amber embers, brass and iron steampunk materials with patina and damage, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, somber but not gory, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 16:9
```

## Z10: `bg_tower_builder.png` — Werkbank vor dem Kampf (Turm-Aufbau)

**Target:** `assets/backgrounds/bg_tower_builder.png` · **Größe:** 1920×1080 (16:9)

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
Wide cinematic steampunk workshop bench scene viewed head-on from a slight elevation: a sturdy wooden workbench in the middle distance fills the lower-middle third of the frame, scattered with brass items, copper fittings, and tools arranged neatly — a partially assembled mechanism in the center, several small brass parts to the side, a leather tool belt rolled up at the edge, a glowing oil lamp casting warm light. Behind the bench: a tall blueprint pinned to a brick-and-iron wall showing a vertical 3-tier tower schematic with annotations, flanked by hanging hand tools (wrenches, hammers, small saws) on a wall rack. Soft warm amber lantern light from above-center, faint cool blue-grey daylight through a small window high on the left wall, gentle steam wisps drifting from a kettle in the upper-right corner. The middle band is intentionally calm (workbench surface) so UI panels can overlay it; visual interest sits along the upper edges (blueprint, wall rack) and lower corners (tools). Anticipatory but peaceful mood — the moment before stepping into combat.

Stil: warm amber lantern lighting from above with cool blue daylight accent, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, contemplative pre-battle mood, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 16:9
```

## Z9: `bg_heal.png` — Reparatur-Halt (Wartungs-Station)

**Target:** `assets/backgrounds/bg_heal.png` · **Größe:** 1920×1080 (16:9)

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
Wide cinematic interior of an abandoned steampunk repair station / maintenance halt: in the middle distance a partially disassembled brass tower segment rests on a sturdy iron repair cradle, surrounded by neatly arranged tools — wrenches hanging on a wall rack, a small anvil, a workbench with rags and oil cans, a half-rolled tool belt. Soft warm amber lantern light pools in the center over the workbench, gentle puffs of steam drift from a maintenance kettle on the right, faint cooling green-tinted backlight from a small ventilation grate suggests calm rest. The atmosphere is restorative and peaceful — a place to mend before the next fight. The middle band is intentionally calm (open workbench area + tower segment) so UI text can overlay it; visual interest sits along the lower-corners (tools, oil cans) and along the upper edges (hanging pipes, lantern).

Stil: warm soft amber lantern light from above-center with cool green-tinted accents from background ventilation, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, calm and restorative mood, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 16:9
```

## Z6: `bg_settings.png` — Einstellungen (Kontrollraum)

**Target:** `assets/backgrounds/bg_settings.png` · **Größe:** 1920×1080 (16:9)

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
Wide cinematic shot of a steampunk engineer's control room viewed head-on: a tall dark wooden control panel in the middle distance covered with rows of brass dials, pressure gauges, large polished levers, glowing amber indicator lights, copper switches, and ornate brass valves. Pipes and tubes weave behind the panel along the walls, releasing small soft steam wisps. Soft warm amber light bathes the room from above and from the gauges themselves. The center of the panel is visually calm (a flat dark wooden surface) so the UI controls can overlay it; the rich detail lives in the upper corners and along the sides where the pipework runs.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion, Children of Morta, Frostpunk), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 16:9
```

---

# U — Werkstatt-Upgrade-Icons (14 Anfragen) — **Weißer Hintergrund**

Quadratisch, schmuckartig, jeweils ein einzelnes Hauptmotiv mit klarem Symbol. Sie erscheinen klein (~48×48) auf den Upgrade-Karten, daher silhouettenstark und nicht zu detailverliebt.

## U1: `upgrade_gold.png` — Schmiede-Vorrat

**Target:** `assets/ui/upgrades/upgrade_gold.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white (NOT transparent).
- KEIN Schachbrett.
- Mindestens 1024×1024 px.
- Klare zentrale Silhouette, gut lesbar auch klein (48 px).

Bild-Prompt:
Single icon on plain solid white background: a small open leather pouch overflowing with gleaming brass and copper coins, a few coins spilling at the front. Warm amber metallic gleam. Centered composition, slight isometric tilt for readability. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## U2: `upgrade_tower.png` — Verstärkter Turm

**Target:** `assets/ui/upgrades/upgrade_tower.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white.
- KEIN Schachbrett. Mindestens 1024×1024 px.
- Klare zentrale Silhouette.

Bild-Prompt:
Single icon on plain solid white background: a stylized three-floor steampunk tower in front silhouette with prominent brass reinforcement bands wrapping around it horizontally, riveted plates, a small heart-shield emblem at the front center symbolizing fortification. Stable, heavy, protective feel. Centered composition. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## U3: `upgrade_market.png` — Marktkenner

**Target:** `assets/ui/upgrades/upgrade_market.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white.
- KEIN Schachbrett. Mindestens 1024×1024 px.

Bild-Prompt:
Single icon on plain solid white background: a small brass merchant scale with two balanced pans, one pan holding a small gear, the other holding a single shiny coin. The pivot at the top is ornate brass with a small flourish. Centered composition. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## U4: `upgrade_shop_plus.png` — Erweitertes Angebot

**Target:** `assets/ui/upgrades/upgrade_shop_plus.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white.
- KEIN Schachbrett. Mindestens 1024×1024 px.

Bild-Prompt:
Single icon on plain solid white background: a steampunk shopkeeper's display crate with three small brass-trimmed item slots in a row, two filled with small bright items (one resembling a tiny gear, one a small bottle), the third slot showing a glowing PLUS symbol indicating an additional offering. Warm wooden frame. Centered composition. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## U5: `upgrade_heal.png` — Heiltechnik

**Target:** `assets/ui/upgrades/upgrade_heal.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white.
- KEIN Schachbrett. Mindestens 1024×1024 px.

Bild-Prompt:
Single icon on plain solid white background: a brass repair-wrench crossed in front of a small softly-glowing emerald-green heart-shape, the brass tool catching a warm amber highlight while the heart radiates a faint healing green glow. Centered composition with the heart slightly behind the wrench. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## U6: `upgrade_salvage.png` — Bessere Bergung

**Target:** `assets/ui/upgrades/upgrade_salvage.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white.
- KEIN Schachbrett. Mindestens 1024×1024 px.

Bild-Prompt:
Single icon on plain solid white background: a brass-bound canvas salvage sack tied at the top with a leather cord, slightly bulging with small protruding cogs, gears and a single coin visible at the opening. The sack sits next to a small pickaxe leaning against it. Centered composition. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## U7: `upgrade_skip.png` — Sparsame Schmiedin

**Target:** `assets/ui/upgrades/upgrade_skip.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white.
- KEIN Schachbrett. Mindestens 1024×1024 px.

Bild-Prompt:
Single icon on plain solid white background: a brass arrow pointing forward (to the right) made of polished metallic plates with rivets, in front of it a small stack of two coins glinting in warm amber. The arrow conveys "skip / next" while the coins convey "reward". Centered composition. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## U8: `upgrade_extra_item.png` — Voll-Werkstatt

**Target:** `assets/ui/upgrades/upgrade_extra_item.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white.
- KEIN Schachbrett. Mindestens 1024×1024 px.

Bild-Prompt:
Single icon on plain solid white background: an open wooden steampunk toolbox lined with brass corners, fully filled with small assorted miniature steampunk items — a tiny hammer, a small gear, a small vial, a tiny pipe-piece, all visible as silhouettes. A bright golden PLUS sign hovers above to signify "extra item". Centered composition. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## U9: `upgrade_crit.png` — Präzisions-Mechanik

**Target:** `assets/ui/upgrades/upgrade_crit.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white.
- KEIN Schachbrett. Mindestens 1024×1024 px.

Bild-Prompt:
Single icon on plain solid white background: a brass crosshair / scope reticle ring with a small precise gear in the center, four tiny pointer marks extending outward at cardinal directions. Subtle warm amber glow at the center point indicating a critical aim. Centered composition. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## U10: `upgrade_elite_gold.png` — Elite-Beute

**Target:** `assets/ui/upgrades/upgrade_elite_gold.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white.
- KEIN Schachbrett. Mindestens 1024×1024 px.

Bild-Prompt:
Single icon on plain solid white background: a small ornate brass-bound chest sitting open, overflowing with coins and a single small purple jeweled crystal, a tiny crown-shaped emblem above the chest implying elite reward. Warm amber glow from inside the chest. Centered composition. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## U11: `upgrade_luck.png` — Wanderer-Glück

**Target:** `assets/ui/upgrades/upgrade_luck.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white.
- KEIN Schachbrett. Mindestens 1024×1024 px.

Bild-Prompt:
Single icon on plain solid white background: a brass-and-bone four-leaf clover charm dangling from a small leather strap with a brass eyelet, decorated with tiny clockwork rivets where the leaves meet. Subtle warm amber backlight. Centered composition. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## U12: `upgrade_discovery.png` — Sammler-Auge

**Target:** `assets/ui/upgrades/upgrade_discovery.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white.
- KEIN Schachbrett. Mindestens 1024×1024 px.

Bild-Prompt:
Single icon on plain solid white background: a brass magnifying glass with a polished handle, the lens highlighting a tiny glowing pale-blue resonance crystal beneath it, faint sparkles emerging from the focused area. Centered composition, slight angle. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## U13: `upgrade_shield.png` — Schutzlauf

**Target:** `assets/ui/upgrades/upgrade_shield.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white.
- KEIN Schachbrett. Mindestens 1024×1024 px.

Bild-Prompt:
Single icon on plain solid white background: an ornate brass round shield with a single central gear motif, riveted along its edge, with a faint pale-blue energy halo around it suggesting absorbing force. Centered composition, slight tilt. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

## U14: `upgrade_boss_heal.png` — Endkampf-Vorbereitung

**Target:** `assets/ui/upgrades/upgrade_boss_heal.png` · **Größe:** 1024×1024 (1:1)

**Copy block:**

```
Generate exactly ONE single image. Not a sheet, not a collage,
not multiple images. One subject, one frame, 1:1 aspect.

TECHNISCHE VORGABEN:
- Vollständig opakes PNG. Hintergrund ist plain solid white.
- KEIN Schachbrett. Mindestens 1024×1024 px.

Bild-Prompt:
Single icon on plain solid white background: a small brass medical-style vial of glowing warm amber elixir labeled with a tiny gear emblem, sitting in front of a small silhouette of a horned boss-shape (suggesting "preparation for boss"). The vial in the foreground is sharp and detailed, the boss-silhouette is dark and supportive in the back. Centered composition. The area around the icon is plain solid white.

Stil: warm dark amber lighting from upper right, brass and copper steampunk materials with patina, hand-painted illustration in the style of warm action roguelike concept art (Bastion), rich textures, no logos, no watermarks, no text labels, NOT photorealistic, NOT cartoon, NOT chrome sci-fi.

--ar 1:1
```

---

# Sammel-Workflow nach jedem Download

Sobald du eines (oder mehrere) PNGs hast, in PowerShell:

```powershell
# 1. PNG ins richtige assets-Unterverzeichnis (siehe Target oben) verschieben/umbenennen
#    Beispiel:
#    Move-Item "$env:USERPROFILE\Downloads\char_pressure.png" "c:\KI-Projekte\Godot\game\assets\characters\char_pressure.png" -Force

# 2. Background-Removal NUR für Items/Map/UI/Tower (NICHT für Charaktere/Bosse/Backgrounds/Partikel)
#    Das Script aus den vorherigen Schritten anwenden, oder bei Bedarf gezielt:
#    Remove-WhiteBackground -Path "c:\KI-Projekte\Godot\game\assets\items\alchemist_flask.png" -Threshold 240

# 3. Headless-Reimport (am besten erst NACH einem Sektions-Block)
& "c:\KI-Projekte\Godot\bin\Godot_v4.6.3-stable_win64_console.exe" `
    --headless --path "c:\KI-Projekte\Godot\game" --import --quit

# 4. Bei Items: optional die .tres-Datei patchen von .svg auf .png
#    (passiert automatisch in den vorherigen Patch-Scripts)
```

---

**Stand:** 2026-05-26 · **Anfragen total:** 59 (A: 3, B: 4, C: 6, D: 3, E: 7, F: 3, G: 7, H: 5, Z4–Z10: 7, U: 14)
