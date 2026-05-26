# Cogwright — Build-Anleitung

## Voraussetzungen

- Godot 4.6.3-stable Editor + Export-Templates für Windows
- Templates: in Godot Editor → Editor → Manage Export Templates → Download

## Lokaler Build

```powershell
$exe = "c:\KI-Projekte\Godot\bin\Godot_v4.6.3-stable_win64_console.exe"
$proj = "c:\KI-Projekte\Godot\game"
& $exe --headless --path $proj --export-release "Windows Desktop" "build/Cogwright.exe"
```

Das Resultat liegt in `c:\KI-Projekte\Godot\game\build\Cogwright.exe` (~80-120 MB inkl. PCK).

## Erstmaliger Setup

1. Editor starten und `Project → Export...` öffnen
2. Falls Templates fehlen: Download über `Manage Export Templates`
3. Preset „Windows Desktop" sollte sichtbar sein (kommt aus `export_presets.cfg`)
4. Optional: Icon (`icon.svg`) durch hochauflösendes ICO ersetzen für native Taskbar-Optik

## Steam-Ready-Schritte (für später)

Vor Steam-Coming-Soon-Page:

- [ ] Trademark-Check für „Cogwright" (EUIPO + USPTO + Steam-Suche)
- [ ] Eigene Domain reservieren (cogwright-game.com o.ä.)
- [ ] Twitter/Bluesky-Handle sichern
- [ ] Steamworks-Direct-Fee zahlen (100 USD)
- [ ] Coming-Soon-Page mit:
    - Screenshots vom Battle-System
    - Trailer (60 sec, mit Soundtrack)
    - Feature-Liste
    - Wishlist-Button aktiviert
- [ ] Steam-SDK-Integration (Achievements zu Steam pushen, Cloud Saves)
    - GodotSteam-Addon empfohlen: https://godotsteam.com
    - Achievement-IDs aus `MetaState.ALL_ACHIEVEMENTS` mappen
- [ ] Build-Pipeline für CI (GitHub Actions o.ä.)

## Achievement-Mapping

Lokale Achievement-IDs (für späteres Steam-Mapping):

| ID | Steam-API-Name (Vorschlag) | Beschreibung |
|---|---|---|
| `first_blood` | ACH_FIRST_BLOOD | Erste Funken |
| `first_boss` | ACH_FIRST_BOSS | Eisenfäller |
| `three_bosses` | ACH_VETERAN | Werkstatt-Veteran |
| `heat_3` | ACH_HEAT_3 | Glühend heiß |
| `all_chars` | ACH_ALL_CHARS | Vier Hände am Werk |
| `daily_win` | ACH_DAILY_WIN | Tageswerk |
| `shop_addict` | ACH_SHOP | Werkstatt-Stammgast |
| `perfect_run` | ACH_PERFECT | Ungerührt |
