# Cogwright — Asset & Design Brief

> Steampunk-Auto-Battler-Roguelike. Brief für die Erstellung neuer Assets, Illustrationen und visuelle Designs — passgenau zum bestehenden Look.

---

## 1. Projekt-Kontext

**Cogwright** ist ein Singleplayer-PvE-Auto-Battler-Roguelike im Steampunk-Setting. Spieler:innen bauen einen 3-stöckigen Werkstatt-Turm aus mechanischen Items (Funkenspeier, Druckhammer, Zahnräder, Dampf-Apparate), die automatisch auf eigenen Cooldowns gegen feindliche Türme feuern. Pro Run werden Items über eine verzweigte Karte gesammelt, Bosse gekämpft, und Resonanzkristalle für permanente Werkstatt-Upgrades verdient.

**Tonalität:** Düster-warme Werkstatt-Welt, Industrie-Romantik, Echtzeit-Mechanik trifft auf Roguelike-Strategie. Kein Cartoon, kein Grim-Dark — irgendwo zwischen *Bastion*, *Slay the Spire*, *Oaken Tower* und *Children of Morta*.

**Engine:** Godot 4.6, Vektorbasiert (SVG-Icons möglich) oder hochauflösende PNGs mit Transparenz.

---

## 2. Art Direction — Stil-Guide

### Generelle Visual-Identity

- **Genre-Anker:** Steampunk-Werkstatt — Messing, Kupfer, Eisen, Gussstahl, Dampf, Zahnräder, Druckluft, Nieten, abgenutzte Holzpaneele
- **Stimmung:** warm, abgenutzt, funktional. Patina, Rostspuren, Öl-Glanz auf Metall. Kein steriler Sci-Fi-Look.
- **Beleuchtung:** rim-light vor dunklem Hintergrund, oft ein einzelner warmer Lichtpunkt (Flamme, Glühen, Dampfventil). Highlight-Areas in cream/honey, Tiefen in tief-warmen Schwarz.
- **Linework:** klare Silhouetten zuerst, Details zweitrangig — Items müssen bei 32×32 Pixel noch erkennbar sein.
- **Vermeiden:** chromiges Sci-Fi-Silber, knalliges Magenta/Cyan, generisch-mittelalterlich (Burgen, Drachen), reines Schwarzweiß.

### Stilreferenzen (zur AI-Prompt-Eingabe)

- *Bastion* (Supergiant) — Lichtsetzung, warme Holz/Bronze-Töne, klare Silhouetten
- *Oaken Tower* — Tower-Mechanik visuell als geschichtete Holz/Metall-Etagen
- *Children of Morta* — Pixel-Art-Reichtum, Charakterportraits
- *Slay the Spire* — Item-Karten-Layout, Rarity-Visualisierung
- Studio Ghibli's *Howl's Moving Castle* — Steampunk-Maschinen mit Persönlichkeit
- *Frostpunk* — düster-industrielle Stadtsilhouetten

### Was den Look definiert

- **Zahnräder als Motiv** in mehreren Größen, häufig im Hintergrund halbtransparent rotierend
- **Pipes mit Nieten** als strukturelle Elemente
- **Dampfwolken** in Cream/White-Tönen mit ~10% Alpha — atmosphärisch, nie dominant
- **Lichtquellen aus Metallöffnungen** (Schornsteine, Ventile, Riss-Glühen)
- **Patinierte Oberflächen** statt makellosem Glanz

---

## 3. Farbpalette

### Primary (Hintergrund + UI)
- `#15100C` — tiefes Werkstatt-Braun (Background-Base)
- `#1B140F` — dunkles Holz
- `#2A2118` — Mid-Brown für Panels
- `#42342A` — heller Holzton, Akzent

### Brass / Gold (Hauptakzent)
- `#F2C75A` — leuchtendes Gold (Highlights, wichtige UI)
- `#D9A640` — Brass (Standard-Akzent)
- `#A37E2C` — Antik-Brass (Schatten)
- `#5E4818` — dunkles Bronze (Tiefen)

### Tag-Farben (im Spiel etabliert — bitte beibehalten)
| Tag | Hex | Charakter |
|---|---|---|
| `fire` | `#E55934` orange-rot | aggressiv, schnell |
| `steam` | `#A8C7E5` hellblau | dampfig, weich |
| `pressure` | `#F2A93B` warmes Orange | mechanisch, mächtig |
| `mechanical` | `#8C7B5C` warmes Grau | neutral, technisch |
| `blunt` | `#7A6A52` dunkles Beige | wuchtig, schwer |
| `precision` | `#5DB3D9` cyan | präzise, kühl |
| `support` | `#7CC279` grün | freundlich, heilend |
| `ranged` | `#C97BBF` magenta | distanziert |
| `heavy` | `#6B5A40` dunkles Braun | massiv |
| `scout` | `#6FA670` salbei-grün | listig |
| `sync` | `#D49845` honig-orange | rhythmisch |
| `modifier` | `#9B6BC2` violett | seltsam-mystisch |
| `reactive` | `#D4674A` rotorange | explosiv |

### Status & Feedback
- `#FF6B4A` — Damage (rot-orange, auf dunkel)
- `#74E670` — Heal (sattes Grün)
- `#F2D472` — Buff/Boost (gold)
- `#8FCFFF` — Crit/Special (eisblau)
- `#C44B4B` — Critical-HP-Warning

---

## 4. Asset-Kategorien — Was wird gebraucht

### A) Item-Icons (44+ Items, höchste Priorität)

Aktuell: einfache weiße SVG-Silhouetten in 64×64 Box. Brauchen Upgrade auf richtige Item-Illustrationen.

**Anforderungen:**
- Format: PNG mit Transparenz, 128×128 (oder 256×256 für High-DPI)
- Stil: ¾-Perspektive ODER frontal, isometrisch nicht zwingend, klare Silhouette
- Hintergrund: transparent — KEIN Rahmen, KEINE Padding
- Detail-Level: erkennbar bei 48×48 (Tower-Slot-Größe), aber rich bei 128×128 (Reward-Karte)
- Konsistenz: alle Items aus gleicher Kameraperspektive und Lichtsetzung

**Item-Liste (Originalnamen, Beschreibung für Visual-Briefing):**

| ID | Deutsch | Visual Briefing |
|---|---|---|
| `pressure_hammer` | Druckhammer | Schwerer Hammer mit Dampfdruckkammer am Kopf, Manometer angeschlossen |
| `steam_kettle` | Dampfkessel | Bauchige Kupferkessel-Form, Pfeife oben, Glut sichtbar durch Risse |
| `gear_sync` | Zahnrad-Synchronisator | Mehrere ineinandergreifende Zahnräder mit zentralem Mechanismus |
| `relief_valve` | Druckventil | Vertikale Pipe mit großem Schraubgriff und Dampfauslass |
| `pressure_gauge` | Druckmesser | Großes rundes Manometer im Brass-Gehäuse, Zeiger im roten Bereich |
| `repair_drone` | Reparatur-Drohne | Kleines fliegendes Brass-Gerät mit Propeller und Werkzeugarm |
| `spark_spitter` | Funkenspeier | Schmaler Tube/Tüllen-Apparat, am Ende Funken-Effekt |
| `pendulum_strike` | Pendel-Schlag | Großes Pendel an Brass-Aufhängung, schwerer Bleikopf |
| `cargo_lift` | Lasten-Aufzug | Plattform mit Kettenwinde und Druckluft-Hub |
| `forge_hearth` | Schmiede-Esse | Offene Feuerstelle mit glühendem Kohle, Blasebalg dran |
| `combustion_chamber` | Brennkammer | Verschlossenes Metallgefäß mit Glühschlitzen und Bedienpanel |
| `pressure_cannon` | Druckkanone | Lange Pipe mit Druckluft-Verschluss, Mündung leicht erhitzt |
| `boil_burst` | Kochsalve | Aufplatzender Dampfkessel mit ausströmendem heißem Wasser |
| `wind_mill` | Wind-Mühle | Vertikale Windrad-Mechanik mit kleinem Generator |
| `spring_trap` | Federfalle | Gespannte Stahlfeder zwischen zwei Klammern, gefährlich aussehend |
| `copper_coil` | Kupferspule | Aufgewickelter Kupferdraht um Eisenkern, leichter Funkenbogen |
| `storm_lance` | Sturm-Lanze | Stab mit elektrischer Spitze, Blitzentladungen |
| `resonance_crystal` | Resonanzkristall | Geschliffener Kristall in Brass-Halterung, pulsierendes Licht |
| `iron_claw` | Eisenklaue | Mechanische Greifklaue mit drei Fingern, Hydraulik |
| `ice_drill` | Eisbohrer | Spiralbohrer mit Kühlrippen und gefrorenem Glanz |
| `vacuum_tube` | Vakuumröhre | Glasröhre mit glimmenden Filament-Drähten |
| `belt_drive` | Riemenantrieb | Zwei Riemenscheiben mit Lederriemen, mit Werkzeugen verbunden |
| `shock_absorber` | Stoßdämpfer | Hydraulisch-Zylinder, Federspirale außen |
| `resonance_hammer` | Resonanzhammer | Hammer mit Kristall-eingelassenem Kopf, blau leuchtende Adern |
| `hydro_pump` | Hydropumpe | Kolbenpumpe mit Druckanzeige, Wasserablauf sichtbar |
| `spinneret` | Spindel | Schnell rotierender Spindelapparat, Fäden aus Metall |
| `spark_magazine` | Funken-Magazin | Behälter voller Funkenpatronen mit Drehmechanik |
| `oil_canister` | Schmieröl-Kanister | Bauchige Brass-Flasche mit Schraubdeckel und Tropfauslass |
| `head_lamp` | Späher-Lampe | Bergmannslampe mit zwei Linsen, warmes Licht |
| `rotary_blade` | Rotor-Klinge | Vierblättrige Rotorklinge mit Achsmechanik |
| `flintlock_pistol` | Steinschloss-Pistole | Antike Pistole mit Brass-Beschlägen, Eisenhahn |
| `clockwork_bird` | Uhrwerk-Vogel | Mechanischer Brass-Vogel mit sichtbaren Zahnrädern im Körper |
| `piston_engine` | Kolbenmotor | Vertikaler Zylinder-Kolben-Motor, schwer und massiv |
| `wrench_thrower` | Schraubenschlüssel-Werfer | Apparat mit Schraubenschlüssel-Magazin, Wurfarm |
| `gear_grinder` | Zahnrad-Reibe | Zwei gegenläufige raue Zahnräder, Funkenschauer |
| `flame_lance` | Flammenlanze | Lange Pipe mit Flammenwerfer-Düse, Brennstofftank |
| `steam_whistle` | Dampfpfeife | Klassische Dampflok-Pfeife auf Sockel, Dampfstoß |
| `bellows_lung` | Blasebalg-Lunge | Klassischer Schmiedeblasebalg in Akkordeon-Form |
| `brass_telescope` | Messing-Teleskop | Ausziehbares Teleskop auf Brass-Stativ, Linse glänzt |
| `chronometer` | Chronometer | Aufwendige Taschenuhr mit komplexem Zifferblatt |
| `brass_horn` | Messing-Trompete | Hörn-/Trompetenform mit Brass-Glanz, Ventile |
| `siphon_pump` | Saugpumpe | Vertikaler Pumpenmechanismus mit gekrümmter Pipe |
| `iron_helm` | Eisenhelm | Brass-/Eisenhelm mit Visier, Nieten, Schraubpaneele |
| `alchemist_flask` | Alchimisten-Kolben | Rundkolben mit langem Hals, gefärbte Flüssigkeit, blubbernd |

---

### B) Charakter-Portraits (4 Starter-Charaktere)

Für die Charakter-Auswahl-Karten und Coop-Lobby. Aktuell: keine Portraits, nur Namen.

**Format:** PNG mit Transparenz, 400×500 (Portrait-Hochformat) oder 800×600 (Wappenbreite). Konsistente Beleuchtung von rechts oben, alle Charaktere von vorne / leicht angewinkelt.

**Charaktere:**

1. **Pyrotechniker** (`fire`)
   - Männlich, mittleres Alter, leicht rußiges Gesicht
   - Lederjacke mit Brass-Knöpfen, Schutzbrille hochgeschoben
   - Held einen rauchenden Funkenspeier-Apparat in der Hand
   - Hintergrund: Funken, warmes Glühen
   - Stimmung: rau-pragmatisch, leicht zufrieden mit Chaos

2. **Druckmeister** (`pressure`)
   - Geschlechts-neutral, schmaler Statur, präzise Haltung
   - Brass-Brille mit mehreren Linsen, dunkelgrüne Weste
   - Manometer am Gürtel, Schraubenschlüssel in einer Hand
   - Hintergrund: Pipes und Druckanzeigen
   - Stimmung: analytisch, methodisch

3. **Schmiedin** (`blunt`)
   - Weiblich, kräftig, Lederschürze über brauner Bluse
   - Eisenhammer auf Schulter, einzelner Brass-Ohrring
   - Verschmierte Wangen, entschlossener Blick
   - Hintergrund: glühende Esse, fliegender Funken
   - Stimmung: stoisch-stark, handwerklich

4. **Saboteur** (`reactive`)
   - Geschlechts-neutral, schmaler Schatten-Charakter
   - Kapuze, halb verdeckt, Brass-Maske vor unterer Gesichtshälfte
   - Hände in fingerlosen Handschuhen, hält eine Federfalle
   - Hintergrund: dunkler Eingang, halbtransparente Dampfwolken
   - Stimmung: verschlagen, technisch-improvisierend

---

### C) Boss-Illustrationen (5+ Bosse)

Für die Boss-Intro-Cutscene und ggf. Encounter-Vorschau. Großformatige Halbportraits oder Full-Body-Illustrationen.

**Format:** PNG, 800×1000, transparenter Hintergrund

**Bosse (Liste erweiterbar):**

1. **Eisenbaron Gravelock** — schwer gepanzerter Industrie-Magnat, kantige Brass-Rüstung, einarmiger Dampf-Generator als Ersatzarm. Aristokratisch aber brutal.
2. **Die Uhrwerk-Hexe** — verzerrte Steampunk-Hexen-Gestalt, Uhrwerk-Innereien sichtbar durch zerrissene Robe, Zifferblatt statt Gesicht.
3. **Funken-Tyrann** — Riesen-Roboter aus zusammengeschweißten Items, brennende Augen, Funkenschauer permanent.
4. **Der stille Maschinist** — humanoide Schemen-Gestalt in Mechaniker-Overall, kein Gesicht, nur eine glühende Lampe wo der Kopf sein sollte.
5. **Ölbaron Krasnik** — übergewichtige Figur in glänzend-öliger Robe, mehrere mechanische Tentakel, Brillen-Stack.

Jeder Boss hat eine eindeutige Silhouette die schon aus 100m erkennbar ist.

---

### D) Tower-Visualisierung (groß!)

Aktuell: 3-stöckiges Slot-Grid aus rechteckigen Panels. Wunsch: visueller Turm mit Charakter.

**Anforderungen:**
- Drei aufeinandergestapelte "Etagen" als visueller Turm
- **Fundament** (unten): solides Steinmauerwerk mit großen Brass-Nieten und Stützstreben — Eindruck von Stabilität
- **Werkstatt** (Mitte): Holzpaneele mit Werkbänken, Rohren, Brass-Beschlägen — produktiver Bereich
- **Spitze/Observatorium** (oben): hellere Holzkonstruktion mit Glasfenster oder Teleskop-Plattform — luftig, beobachtend
- Jede Etage hat 3 "Slots" für Items — gestaltet als Werkbank-Plätze, Halterungen, Brennkammern
- Schornstein oben, dezenter Dampfaustritt
- Format: Vertikal-Stack 600×900px, modular zusammensetzbar
- Optional: Animated-Sprite-Sheets für Idle-Bewegung (Dampf, Glow, kleine Funken)

---

### E) Backgrounds & Parallax

Für Battle-, Map- und Menüszenen. Mehrere Layer für Parallax-Scrolling.

**Layer 1 (Sky/Far):** dunkelblauer/orangefarbener Himmel mit Wolken und einer Sonne/Mondscheibe durch Industrieschmutz
**Layer 2 (Far Buildings):** Silhouetten ferner Fabriken mit Schornsteinen und Dampf
**Layer 3 (Mid Buildings):** näher heran, mehr Detail — beleuchtete Fenster, Brass-Schilder
**Layer 4 (Foreground):** Mauerwerk und Pipes direkt vor dem Spieler

**Variationen:**
- **Standard-Battle-BG:** generisch-industriell, warm-grau
- **Boss-Battle-BG:** dramatischer, lila-rote Akzente, Blitz im Hintergrund
- **Map-Travel-BG:** weiter und atmosphärischer, mehr Tiefe

Format: Pro Layer 2048×1024px PNG, tilebar horizontal wenn möglich.

---

### F) UI-Frames & Decorations

Aktuell: einfache Godot-StyleBoxFlat-Panels. Upgrade auf richtige Brass-Ornament-Frames.

**Bedarf:**
- **Panel-Frame:** 9-slice-PNG (z.B. 96×96 mit 24px-Borders), Brass-Ecken mit Ornamenten, dunkler Holz-Hintergrund
- **Button-Frame:** ähnlich, kleiner (32×32 Border), mit hover/pressed Varianten
- **Card-Frame:** für Item-/Reward-Karten, etwas dekorativer, mit Rarity-Variante (siehe unten)
- **Rarity-Frames:** vier Versionen mit unterschiedlichen Akzentfarben:
  - Common: warmes Grau-Bronze
  - Uncommon: grünlich-bronze
  - Rare: blau-bronze
  - Legendary: lila/gold-bronze, mit subtilen Glow-Akzenten
- **Header-Banner:** dekorativer Brass-Streifen mit Ornamentik für Scene-Titel

---

### G) Map-Knoten-Icons

Aktuell: text-basierte Icons + Unicode-Symbole. Wunsch: kleine pixel-/illustrierte Icons.

**Format:** 96×96 PNG mit Transparenz, klare Silhouette für Lesbarkeit auf der Map.

| Knoten-Typ | Visual |
|---|---|
| `Start` | Brass-Pfeil oder Werkstatt-Tor halb geöffnet |
| `Kampf` | gekreuzte Mechanik-Werkzeuge (Schlüssel + Hammer) |
| `Elite` | Totenkopf mit Brass-Beschlägen, dunkel |
| `Boss` | aufwendigere Krone mit Zifferblatt drin |
| `Werkstatt/Shop` | Zahnrad mit Münze davor |
| `Heilung` | rotes Herz im Brass-Rahmen, ggf. mit Werkzeug-Wartung-Symbolik |
| `Event/Begegnung` | Fragezeichen aus Brass-Pipes geformt |

---

### H) Partikel-Texturen

Für die Item-Trigger-Effekte (aktuell CPUParticles2D mit Farb-Gradient). Verbessert durch kleine Sprite-Texturen.

- **Funke** (16×16): heller Punkt mit Stern-Strahlen, transparent
- **Dampfwolke** (32×32): weiche weiße Wolke
- **Rauch** (32×32): grau-bräunliche Wolke
- **Öl-Tropfen** (16×16): glänzender dunkler Tropfen
- **Splitter** (16×16): kleiner Metallsplitter mit Spitzen

---

### I) Audio (separate Briefing-Zeile)

Falls Audio mit auf die Liste soll:

- **Battle-Tracks** (3-4 Loops à 60-90s): Steampunk-Orchester mit Industrial-Drums, Brass-Bläser, Akkordeon. Verschiedene Intensitäten (Standard / Elite / Boss / Calm-Werkstatt).
- **Item-Sounds** (44 Items, je 0.3-0.8s): kurze Trigger-SFX — Funken-Knister, Dampf-Zisch, Metallschlag, mechanisches Klicken. Variation pro Item.
- **Impact-Sounds** (3 Stufen): leicht/mittel/schwer Metalltreffer.
- **UI-Sounds**: Klick (Brass-Glocke), Bestätigung (Zahnrad-Klick), Zurück (gedämpfter Ton), Sieg (Brass-Fanfare), Niederlage (Dampf-Ablass).

---

## 5. Technische Spezifikationen

**Dateiformate:**
- Statische Items/Icons: **PNG** mit alpha (am liebsten 2× Auflösung für Retina/4K)
- Vektor möglich: **SVG**, aber nur wenn keine komplexen Effekte/Schatten nötig
- Backgrounds: PNG mit alpha, Layer-getrennt
- 9-slice-Frames: PNG mit klar markierten Stretch-Zonen (Borders)
- Audio: **OGG Vorbis** (Godot-nativ), 44.1 kHz Stereo, 192kbps reicht

**Naming Convention:**
- Items: `<item_id>.png` (z.B. `pressure_hammer.png`)
- Charaktere: `char_<id>.png` (z.B. `char_fire.png`)
- Bosse: `boss_<id>.png`
- Backgrounds: `bg_<scene>_<layer>.png`

**Größen-Zielwerte:**
- Item-Icon: 128×128 (oder 256×256 für High-DPI)
- Charakter: 400×500
- Boss: 800×1000
- Background-Layer: 2048×1024 (horizontal tilebar wenn möglich)
- UI-Frames: 96×96 mit 24px Border-Zone

---

## 6. Beispiel-Prompts für AI-Tools

### Item-Icon (Midjourney / Stable Diffusion)

```
steampunk item icon, [Item-Name in English], brass and copper machinery, 
warm patina, glowing accents, transparent background, centered composition, 
detailed mechanical illustration in the style of Bastion and Children of Morta, 
warm dark amber lighting from one side, ¾ perspective, no border, no text, 
clean silhouette readable at small sizes --ar 1:1 --style raw --v 6
```

### Charakter-Portrait

```
steampunk character portrait, [Charakter-Beschreibung], hand-painted illustration, 
warm dark background with subtle gear motifs, brass mechanical accessories, 
expressive face, 3/4 view, dramatic rim lighting from upper right, 
style influenced by Children of Morta and Howl's Moving Castle, 
no border, transparent background, full body or chest-up, 
detailed but with clean silhouette --ar 4:5 --style raw --v 6
```

### Boss-Illustration

```
steampunk boss character, [Boss-Beschreibung], imposing silhouette, 
brass and iron heavy armor, glowing details, sparks and steam particles, 
dramatic dark atmosphere with single warm light source, 
hand-painted style with rich textures, transparent background, 
inspired by Frostpunk and Bastion, ominous mood --ar 4:5 --style raw --v 6
```

### Background-Parallax-Layer

```
steampunk industrial city silhouette, layered parallax background, 
dark warm amber sky with clouds and steam, factory chimneys with rising smoke, 
brass-tinted buildings with glowing windows in mid-distance, 
ornate Victorian-industrial architecture, dramatic lighting, 
horizontally seamless tilable, no characters, 
inspired by Frostpunk and Sunless Sea --ar 2:1 --style raw --v 6
```

### UI-Frame (Brass-Ornament)

```
ornate brass frame border, steampunk Victorian decoration, 
metallic patina with rivets and gear motifs in corners, 
9-slice compatible design with clear stretchable middle, 
dark wood backing, warm bronze and amber highlights, 
seamless tile-able pattern in middle sections, 
transparent center area, no text, no character --ar 1:1 --style raw --v 6
```

---

## 7. Was nicht im Brief steht — aber wichtig ist

- **Konsistenz vor Quantität:** Lieber 10 perfekt zusammenpassende Items als 44 stilistisch variable
- **Lesbarkeit zuerst:** jedes Asset muss bei finaler Engine-Größe (oft kleiner als das Asset selbst) noch funktionieren
- **Animationen möglich, nicht zwingend:** statische Sprites reichen, aber idle-Glow oder 2-Frame-Bewegung wirkt Wunder
- **Modulares Denken:** wenn möglich, Charaktere/Bosse so designen dass Kopf/Körper austauschbar sind (für spätere Skins)
- **Rechte:** für Steam-Release brauchen alle Assets klare Lizenz (CC0, kommerzielle Lizenz, oder eigene Produktion)

---

## 8. Glossar — Welt-Begriffe für AI-Kontext

| Begriff (DE) | Englisch | Definition |
|---|---|---|
| Werkstatt | Workshop | Zentrum der Spielwelt, halb Werkstatt, halb Festung |
| Fundament | Foundation | Untere Tower-Etage, defensiv |
| Werkstatt-Etage | Workshop Floor | Mittlere Etage, produktiv |
| Spitze / Observatorium | Pinnacle | Obere Etage, schnell + präzise |
| Resonanzkristall | Resonance Crystal | Meta-Currency, mystisch-mechanisch |
| Funkenspeier | Spark-Spitter | Klassisches Fire-Item, ikonisch |
| Druckmeister | Pressure-Master | Druck-spezialisierte Charakterklasse |
| Auto-Battler | — | Genre: keine Echtzeit-Interaktion im Kampf |
| Heat | — | Difficulty-Modifier-System ähnlich Hades |

---

**Stand:** 2026-05-25 · **Projekt:** Cogwright · **Version Brief:** 1.0
