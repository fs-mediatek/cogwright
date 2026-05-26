# Unity Import-Hinweise

## Texturen

### Item-Icons, UI, Map-Icons, Partikel

- Texture Type: Sprite (2D and UI)
- Sprite Mode: Single
- Pixels Per Unit: projektabhängig, konsistent halten
- Alpha Is Transparency: aktivieren
- Filter Mode: Point oder Bilinear je nach gewünschter Schärfe
- Compression: None oder High Quality, abhängig vom Buildziel

### Backgrounds

- Texture Type: Sprite oder Default
- Wrap Mode: Repeat, wenn horizontal tilebar genutzt wird
- Compression: High Quality
- Mip Maps: bei 2D-Parallax meist deaktivieren, wenn keine Skalierung in Tiefe nötig ist

## UI 9-slice

- Sprite Editor öffnen
- Border: 24 px pro Seite
- Test mit gestrecktem Panel in mehreren Größen durchführen

## Ordnerstruktur in Unity

```text
Assets/Cogwright/Art/Items
Assets/Cogwright/Art/Characters
Assets/Cogwright/Art/Bosses
Assets/Cogwright/Art/Tower
Assets/Cogwright/Art/Backgrounds
Assets/Cogwright/Art/UI
Assets/Cogwright/Art/MapIcons
Assets/Cogwright/Art/Particles
```
