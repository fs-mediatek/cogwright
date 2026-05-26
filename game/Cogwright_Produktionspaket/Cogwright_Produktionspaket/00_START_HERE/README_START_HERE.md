# Cogwright — vollständiges Produktionspaket

Stand: 2026-05-25

Dieses Paket bündelt die Asset-Produktion für **Cogwright**, ein Singleplayer-PvE-Auto-Battler-Roguelike im warm-düsteren Steampunk-Werkstatt-Look.

## Inhalt

- `01_Art_Direction/` — Styleguide, Farbpalette, Do/Don'ts
- `02_Asset_Manifest/` — vollständige Asset-Liste als XLSX, CSV, JSON und JSONL
- `03_Prompts/` — getrennte Prompt-Dateien nach Asset-Kategorien
- `04_Pipeline_Export/` — Naming, Batch-Workflow, Export- und Nachbearbeitungsregeln
- `05_Engine_Import/` — Import-Hinweise für Unity und Godot
- `06_QA_Checklists/` — Abnahmechecklisten für Items, Characters, UI, Backgrounds
- `07_Palettes/` — CSS, JSON, GIMP-Palette und PNG-Farbtafel
- `08_Delivery_Folders/` — Zielstruktur für final exportierte PNG-Dateien

## Produktionsumfang

| Kategorie | Menge |
|---|---:|
| Item-Icons | 44 |
| Charakter-Portraits | 4 |
| Boss-Illustrationen | 5 |
| Tower-Visualisierungen | 4 |
| Background-Layer | 4 |
| UI-Frames | 8 |
| Map-Knoten-Icons | 7 |
| Partikel-Texturen | 5 |

## Wichtig

Die 44er-Itemliste wurde produktionsfähig ergänzt, weil der bereitgestellte Brief Beispiele nennt, aber keine vollständige Liste enthält. Die Ergänzungen halten sich an Tonalität, Tag-System, Farbpalette und technische Vorgaben des Briefs.

## Empfohlener Ablauf

1. `02_Asset_Manifest/Cogwright_Asset_Manifest.xlsx` öffnen.
2. Pro Kategorie die Prioritäten prüfen.
3. Zuerst 5–8 Stil-Testassets erzeugen: 3 Items, 1 Character, 1 Boss, 1 UI-Frame, 1 Background.
4. Diese Assets im Spiel bei Zielgröße testen.
5. Danach Batch-Produktion anhand der JSONL-/CSV-Dateien starten.
6. Jede Datei anhand der QA-Checklisten abnehmen.
