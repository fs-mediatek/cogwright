class_name DraggableItemCard extends PanelContainer

# Inventory-Item-Karte, die per Drag-and-Drop auf einen TowerSlotPanel
# gezogen werden kann. Speichert das Item und seinen Index im Inventar.

var item: Item
var inv_idx: int = -1

func _get_drag_data(_at_position: Vector2):
	if item == null:
		return null
	# Visuelle Vorschau, die am Cursor klebt
	var preview_root := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.15, 0.10, 0.95)
	sb.border_color = Color(0.95, 0.78, 0.40, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	preview_root.add_theme_stylebox_override("panel", sb)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	preview_root.add_child(hbox)
	var icon := TextureRect.new()
	icon.texture = item.icon
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon)
	var name_lbl := Label.new()
	name_lbl.text = item.display_name
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	name_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(name_lbl)
	preview_root.modulate = Color(1, 1, 1, 0.92)
	set_drag_preview(preview_root)
	return {"type": "inventory_item", "inv_idx": inv_idx}
