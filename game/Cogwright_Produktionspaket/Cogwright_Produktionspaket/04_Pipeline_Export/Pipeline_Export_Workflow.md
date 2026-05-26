# Cogwright — Produktions- und Export-Pipeline

## 1. Stiltest vor Massenproduktion

Vor der vollständigen Produktion sollten mindestens diese Testassets erzeugt und im Spiel geprüft werden:

- 3 Item-Icons: `druckhammer`, `funkenspeier`, `chronometer`
- 1 Character: `char_pyrotechniker`
- 1 Boss: `boss_uhrwerk_hexe`
- 1 UI-Frame: `ui_panel_standard`
- 1 Background-Layer: `bg_city_mid_buildings`

Erst wenn diese Assets in ihrer Zielgröße funktionieren, sollte die Batch-Produktion gestartet werden.

## 2. Dateinamensregeln

- Kleinbuchstaben
- keine Leerzeichen
- Umlaute ersetzen: ä -> ae, ö -> oe, ü -> ue, ß -> ss
- Trennung per Unterstrich
- Dateiendung `.png`

Beispiele:

- `druckhammer.png`
- `char_pyrotechniker.png`
- `boss_eisenbaron_gravelock.png`
- `bg_city_sky.png`
- `ui_frame_legendary.png`

## 3. Exportgrößen

| Kategorie | Zielgröße | Alpha | Hinweise |
|---|---:|---|---|
| Item-Icon | 128x128, optional 256x256 | ja | kein Rahmen, zentriert |
| Charakter | 400x500 | ja | Licht von rechts oben |
| Boss | 800x1000 | ja | eindeutige Silhouette |
| Tower | 600x900 / 600x300 | ja | 3 Etagen modular denkbar |
| Background-Layer | 2048x1024 | je nach Layer | horizontal tilebar |
| UI-Frames | 96x96 | ja | 24px Border-Zone für 9-slice |
| Map-Icons | 96x96 | ja | klare Symbolik |
| Partikel | 16x16 / 32x32 | ja | weich, sparsam, loop-/atlasfähig |

## 4. Nachbearbeitung

- Hintergrund sauber entfernen, wenn Tool keinen echten Alpha-Export liefert
- Silhouette bei Zielgröße prüfen
- Kontrast gegen dunkles UI testen
- Farbstiche prüfen: kein Neon, kein Chrome
- bei Items ggf. Details reduzieren statt erhöhen

## 5. Versionierung

Empfohlen:

- `asset_id_v001.png` nur während der Produktion
- finales Delivery ohne Versionssuffix: `asset_id.png`
- Quell-/Arbeitsdateien separat speichern: `asset_id_source.psd`, `asset_id_source.afphoto`, `asset_id_source.kra`

## 6. Batch-Inputs

Für automatisierte Workflows liegen bereit:

- `Cogwright_Asset_Manifest.csv`
- `Cogwright_Asset_Manifest.json`
- `Cogwright_Batch_Prompts.jsonl`

Die JSONL-Datei enthält pro Zeile ein Asset mit Prompt und Negativ-Prompt.
