# Godot Import-Hinweise

## Texturen

### Icons/UI/Particles

- Import als Texture2D
- Filter je nach Pixel-/Painterly-Look prüfen
- Mipmaps für kleine UI-Icons meist deaktivieren
- Repeat nur für Background-Layer aktivieren, wenn wirklich tilebar

## UI 9-slice

- TextureRect oder NinePatchRect verwenden
- Patch Margin: 24 px pro Seite
- Zentrum strecken, Ecken unverzerrt lassen

## Ordnerstruktur in Godot

```text
res://art/items/
res://art/characters/
res://art/bosses/
res://art/tower/
res://art/backgrounds/
res://art/ui/
res://art/map_icons/
res://art/particles/
```
