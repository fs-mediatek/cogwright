# Cogwright

Steampunk Auto-Battler Roguelike in Godot 4.6.3 (GDScript).

## Quick Start

1. Godot 4.6.3 installieren ([download](https://godotengine.org/download/archive/4.6.3-stable/))
2. Repo klonen
3. In Godot: `Import` → `game/project.godot` öffnen
4. F5 zum Starten

## Release-Build

Siehe [Cogwright_Build_Update_Guide.md](Cogwright_Build_Update_Guide.md).

Kurz:
```powershell
.\build_release.ps1
```

Output: `release/Cogwright-<version>.zip` (Single-EXE für Windows).

## Architektur

- `game/scripts/core/` — Autoloads (RunState, MetaState, AudioManager, AppVersion, UpdateChecker, …)
- `game/scripts/battle/` — Combat-Engine (Towers, Slots, Effects)
- `game/scripts/view/` — Szenen-Skripte (MainMenu, BattleView, …)
- `game/scenes/` — Szenen-Dateien
- `game/data/items/` — Item-Definitionen (.tres)
- `game/data/encounters/` — Gegner/Bosse
- `game/assets/` — Texturen, Audio, Fonts

## Status

Pre-Release v0.2.0 — Expansion-Build mit:
- Klassen: Pyrotechniker, Druckmeister, Schmiedin, Saboteur, Kanonenmeister
- 5 Bosse + Endboss
- 13 freischaltbare Perks
- Sandbox-Modus "Schmiede-Probe"
- Co-Op über LAN (experimentell)
