# Cogwright — Ambient-Sound-Prompts für ElevenLabs

> **Workflow:** ElevenLabs → Sound Effects (https://elevenlabs.io/app/sound-effects). Pro Asset einen Block aus „Copy block" 1:1 in das Prompt-Feld kopieren. **Duration:** 20–22 s (Max). **Prompt influence:** 0.6–0.7. **Loop:** Sound Effects geneneriert nicht selbst Loops, aber wir wählen Clips mit gleichmäßiger Textur und loopen sie in Godot per `AudioStream.loop = true`.

**Tipp:** Pro Slot 2–3 Varianten generieren und die nahtloseste auswählen. Die ausgewählten OGGs landen in `game/assets/audio/ambient/`.

**Target-Pfade:**
- Ambient-Loops → `game/assets/audio/ambient/`
- Endings (one-shot) → `game/assets/audio/ambient/oneshots/`

**Dateinamen strict einhalten.** Nach Download → `.mp3` → mit `ffmpeg` zu `.ogg vorbis` konvertieren (oder Audacity Export).

```powershell
# Beispiel-Konvertierung
ffmpeg -i input.mp3 -c:a libvorbis -q:a 5 output.ogg
```

---

## Globale Stil-Anker

Alle Prompts teilen diese Linie: **dieselbe Steampunk-Werkstattwelt**, gedämpft genug um Musik nicht zu killen, mit Brass/Iron/Steam-Texturen statt Sci-Fi-Klängen. Keine menschliche Sprache, keine Melodien, keine Vocals.

**Common negative cues** (in jedem Prompt enthalten): no music, no melody, no human voices, no speech, no singing, no sci-fi laser sounds, no electronic synth pads.

---

# A — Ambient-Loops (Szenen-Hintergrund)

Jeder Loop sollte 18–22 s sein, ohne markante Einzelevents, damit der Loop-Punkt nicht hörbar wird.

## A1: `ambient_menu.ogg` — Hauptmenü (Werkstatt im Standby)

**Slot:** MainMenu, RunStart, MetaStats, SettingsView · **Dauer:** 22 s

**Copy block:**

```
A calm, low-volume steampunk workshop ambience: a distant slow rhythmic mechanical thumping like a large piston engine breathing far away, gentle steady hiss of steam venting from a brass pipe, occasional very soft metal-on-metal tink of cooling brass, faint low hum of an idle boiler. Warm, slightly hollow indoor reverb suggesting a large workshop hall at rest. Texture should be even and continuous without abrupt events, so it can loop seamlessly. Roughly 22 seconds, mono or stereo, no music, no melody, no human voices, no speech, no sci-fi laser sounds.
```

## A2: `ambient_map.ogg` — Karten-Erkundung (Stadt unter Dampf)

**Slot:** MapView · **Dauer:** 22 s

**Copy block:**

```
A wide outdoor steampunk city ambience heard from a high vantage point: distant low industrial rumble like factories far below, faint wind moving through brass pipework and iron beams, occasional very distant clatter of machinery, soft seagull-like metallic creaks of weather vanes turning, a faint low drone of a distant airship engine passing somewhere far away. Open airy outdoor reverb, slightly melancholic and contemplative. Texture should remain even and continuous for seamless looping. Roughly 22 seconds, no music, no melody, no human voices, no speech, no modern traffic.
```

## A3: `ambient_battle.ogg` — Kampf-Untergrund (Stress, Dampf)

**Slot:** BattleView (zusätzlich zur Battle-Music) · **Dauer:** 20 s

> **Hinweis 2026-05-26:** Die erste Version (`A3 v1`) hatte „irregular bursts of pressurized steam" → wurde als zu druckvoll empfunden (Kopfschmerz, konkurriert mit Item-SFX). Daher: aktuell im Code via `stop_ambient()` im BattleView abgeschaltet. Wenn du eine neue Variante generierst, nutze **A3 v2** (deutlich subtiler, reiner Drone ohne Bursts).

**Copy block (A3 v2 — subtle, no bursts):**

```
A very subtle, continuous low-frequency steampunk combat underbed: a single steady deep boiler hum at the bottom of the mix, a soft warm tape-like static wash suggesting distant air movement, a slow gentle pulse like a heavy mechanism breathing at the edge of hearing, very faint distant metallic resonance — no events, no bursts, no clicks, no transients. Designed to sit completely underneath active battle music and SFX without competing — almost subliminal, just adding warmth and weight. Even continuous texture for seamless looping. Roughly 20 seconds, no music, no melody, no human voices, no speech, no drums, no horror sounds, no steam hiss bursts, no clanging.
```

**Copy block (A3 v1 — original, aggressive, archiviert):**

```
A subtle low-mix combat-tension steampunk ambience: a constant low industrial drone like multiple boilers under load, irregular bursts of pressurized steam venting, distant low metallic groans of stressed iron, a faint low-frequency rumble suggesting nearby heavy machinery, occasional very soft electrical-magnetic crackle from copper coils. Tense but not aggressive — sits underneath the main battle music without competing. Texture should be even enough to loop without obvious cuts. Roughly 20 seconds, no music, no melody, no human voices, no drums, no sci-fi sounds.
```

## A4: `ambient_heal.ogg` — Reparatur-Halt (ruhige Werkstatt)

**Slot:** HealNodeView · **Dauer:** 22 s

**Copy block:**

```
A quiet, restorative steampunk maintenance station ambience: slow rhythmic drips of oil into a tin pan, very gentle steam hiss from a small kettle, faint ticking of a brass mechanical clock, occasional soft creak of cooling metal, a low gentle hum of a small idle pump in the distance. Warm intimate indoor reverb, peaceful and reassuring like a workshop at night. Even continuous texture for seamless looping. Roughly 22 seconds, no music, no melody, no human voices, no speech, no birds.
```

## A5: `ambient_shop.ogg` — Werkzeugmarkt

**Slot:** ShopView · **Dauer:** 22 s

**Copy block:**

```
A bustling but distant steampunk workshop market ambience: faint metallic clinking of coins and small tools being moved around on a wooden counter, soft jingling of hanging brass weights, low murmur of a wood stove crackling somewhere nearby, occasional gentle clack of a small mechanical till, a low warm hum of a gas lantern. Indoor cozy reverb, slightly busy but inviting. Texture should remain even for seamless looping. Roughly 22 seconds, no music, no melody, no human voices, no speech, no cash register beeps.
```

## A6: `ambient_workshop.ogg` — Werkstatt / Upgrade-Hub (aktive Schmiede)

**Slot:** ItemReward, TowerBuilder, Z4-Upgrade-Screens · **Dauer:** 22 s

**Copy block:**

```
An active steampunk forge workshop ambience: steady rhythmic hammer strikes on an anvil in the middle distance, a low constant roar of a forge bellows breathing, hiss of steam escaping a release valve in regular pulses, faint clatter of tools being set down on a metal bench, low resonant hum of a heavy iron piston engine driving a belt. Warm reverberant indoor space, busy and purposeful. Even continuous texture for seamless looping. Roughly 22 seconds, no music, no melody, no human voices, no speech.
```

## A7: `ambient_boss_intro.ogg` — Boss-Intro (Bedrohung)

**Slot:** BossIntro · **Dauer:** 18 s

**Copy block:**

```
An ominous low-end steampunk threat ambience: a deep slow industrial heartbeat-like pulse of a massive distant engine, ominous low metallic groans of stressed iron beams, occasional very deep brass horn-like resonance like a distant warning siren slowly fading, a faint high-frequency electrical magnetic crackle, slow drips of black oil into a deep pool. Dark, oppressive, cinematic. Dense low-frequency texture suitable as an underscore beneath the boss intro music. Roughly 18 seconds, no music, no melody, no human voices, no speech, no drums, no horror screams.
```

## A8: `ambient_event.ogg` — Event-Node (Mysterium)

**Slot:** EventView · **Dauer:** 20 s

**Copy block:**

```
A mysterious steampunk discovery ambience: a faint magnetic-electrical low hum suggesting strange energy, soft slow metallic creaks of unknown machinery shifting, occasional very gentle resonant brass chime as if a copper bell were struck far away, a low slow swell of warm air movement, faint distant tick of a chronometer. Curious and slightly unsettling but not threatening. Even continuous texture for seamless looping. Roughly 20 seconds, no music, no melody, no human voices, no speech, no horror sounds.
```

---

# C — Zusätzliche Combat-Layer (optional, falls A3 v2 noch nicht reicht)

Wenn der Kampf nach A3 v2 immer noch zu „nackt" klingt, kombiniere die folgenden Layer-Sounds — alle als separate Loops oder zufällige One-Shots, die der AudioManager spielt.

## C1: `combat_tension_rise.ogg` — Tension-Build (low health)

**Slot:** wird bei HP < 30 % vom AudioManager als zusätzlicher Layer eingeblendet · **Dauer:** 20 s

**Copy block:**

```
A slow rising steampunk tension drone: a deep low-frequency throb that very gradually increases in intensity, a faint warm sub-bass swell, soft mid-frequency metallic resonance fading in and out slowly, the impression of a boiler approaching critical pressure but never reaching release. No events, no transients, no melody. Designed as a tension-only layer added when the player is in danger. Roughly 20 seconds, no music, no melody, no human voices, no drums, no horror screams, no explosions.
```

## C2: `combat_impact_var1.ogg` — Treffer-Variante A (Brass-Crunch)

**Slot:** Pool für DealDamageEffect (zusätzlich zu impact_light/medium/heavy) · **Dauer:** 0.8 s

**Copy block:**

```
A short crisp steampunk impact: a brass fitting taking a hard hit, a quick metallic crunch with warm low resonance, immediately followed by a soft brass ring fading. Punchy and tactile, not harsh. About 0.8 seconds. No music, no human voices, no electronic synth.
```

## C3: `combat_impact_var2.ogg` — Treffer-Variante B (Steam-Vent-Hit)

**Slot:** Pool für DealDamageEffect · **Dauer:** 0.8 s

**Copy block:**

```
A short impact one-shot: a sudden short steam burst released by a hit on a pressurized pipe, with a hard metallic thud underneath, ending in a quick soft hiss. Punchy and immediate, satisfying impact feel. About 0.8 seconds. No music, no human voices.
```

## C4: `combat_crit_ring.ogg` — Crit-Akzent (Brass-Bell)

**Slot:** Wenn `crit` in DealDamageEffect ausgelöst wird · **Dauer:** 1.0 s

**Copy block:**

```
A short crisp brass bell ring as a critical-hit accent: a single small brass cymbal-like resonance struck once, bright but warm, ringing for about a second and decaying naturally. About 1 second total. No music, no melody, no human voices, no electronic synth.
```

---

# B — One-Shot-Stings (Übergänge / Outcome)

Nicht-loopende kurze Akzente (3–6 s), spielen einmalig bei Szenenwechsel.

## B1: `sting_run_start.ogg` — Run-Start (Aufbruch)

**Slot:** RunStart → MapView Übergang · **Dauer:** 4 s

**Copy block:**

```
A short triumphant steampunk "engines igniting" one-shot: a quick rising whoosh of a brass workshop powering up, a low deep boiler ignition rumble, a single confident brass horn-like resonance tone, settling into a brief warm steady hum. About 4 seconds total. No music, no melody, no human voices, no speech, no sci-fi sounds, no electronic synth.
```

## B2: `sting_victory.ogg` — Boss-Sieg (Triumph)

**Slot:** RunComplete (is_victory = true) · **Dauer:** 5 s

**Copy block:**

```
A short triumphant steampunk victory one-shot: a powerful steam whistle blowing a single warm sustained note, accompanied by a deep resonant brass bell strike, followed by a bright shower of small mechanical brass chimes settling, ending in a warm satisfied low hum. About 5 seconds total. Celebratory but dignified, not cheesy. No music with melody, no human voices, no speech, no cheering crowd.
```

## B3: `sting_defeat.ogg` — Run-Niederlage (Zusammenbruch)

**Slot:** GameOver · **Dauer:** 5 s

**Copy block:**

```
A short somber steampunk defeat one-shot: a long slow hiss of steam venting and dying, a deep low metallic groan of a tower collapsing in the distance, a final dull thud of heavy debris settling, a faint slow last drip of oil, ending in cold silence. About 5 seconds total. Melancholic and dignified, not horror. No music with melody, no human voices, no speech, no screams, no explosions.
```

## B4: `sting_node_pick.ogg` — Map-Knoten ausgewählt

**Slot:** MapView Klick auf Knoten · **Dauer:** 1.5 s

**Copy block:**

```
A short tactile steampunk UI confirmation one-shot: a small brass mechanism clicking into place, a soft satisfying gear engaging, a brief warm metallic resonance fading out. Crisp and immediate. About 1.5 seconds total. No music, no melody, no human voices.
```

---

## Empfohlene Reihenfolge

1. **Erste Welle** (am wichtigsten): A1 (Menu), A2 (Map), A4 (Heal), A6 (Workshop) — decken den Großteil der Spielzeit ab.
2. **Zweite Welle**: A3 (Battle-Untergrund), A5 (Shop), A7 (Boss-Intro), A8 (Event).
3. **Stings**: B1–B4 als Politur.

---

## Integration in Godot

```gdscript
# In AudioManager.gd ergänzen (Bus „Ambient" anlegen):
const AMBIENT_PATHS := {
    "menu": "res://assets/audio/ambient/ambient_menu.ogg",
    "map": "res://assets/audio/ambient/ambient_map.ogg",
    "heal": "res://assets/audio/ambient/ambient_heal.ogg",
    "shop": "res://assets/audio/ambient/ambient_shop.ogg",
    "workshop": "res://assets/audio/ambient/ambient_workshop.ogg",
    "battle": "res://assets/audio/ambient/ambient_battle.ogg",
    "boss_intro": "res://assets/audio/ambient/ambient_boss_intro.ogg",
    "event": "res://assets/audio/ambient/ambient_event.ogg",
}

func play_ambient(key: String, volume_db: float = -22.0) -> void:
    var path: String = AMBIENT_PATHS.get(key, "")
    if path == "" or not ResourceLoader.exists(path):
        return
    var stream: AudioStream = load(path)
    stream.loop = true   # OggVorbis + AudioStreamWAV unterstützen loop
    _ambient_player.stream = stream
    _ambient_player.volume_db = volume_db
    _ambient_player.play()
```

Pro Szene im `_ready()`: `AudioManager.play_ambient("heal")` parallel zu `AudioManager.play_music(...)`.

---

**Stand:** 2026-05-26 · **Ambient total:** 16 (A: 8 Loops, B: 4 Stings, C: 4 optionale Combat-Layer)
