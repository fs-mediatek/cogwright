class_name TagChips extends HFlowContainer

@export var chip_font_size: int = 11
@export var chip_padding_h: int = 8
@export var chip_padding_v: int = 3

func _ready() -> void:
	add_theme_constant_override("h_separation", 4)
	add_theme_constant_override("v_separation", 4)

func set_tags(tags: Array, boosted_tags: Array = []) -> void:
	for child in get_children():
		child.queue_free()
	for tag in tags:
		var chip := _make_chip(tag, tag in boosted_tags)
		add_child(chip)

func _make_chip(tag: StringName, is_boosted: bool) -> Control:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = TagPalette.bg(tag)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = chip_padding_h
	sb.content_margin_right = chip_padding_h
	sb.content_margin_top = chip_padding_v
	sb.content_margin_bottom = chip_padding_v
	if is_boosted:
		sb.border_color = Color(1.0, 0.85, 0.45)
		sb.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", sb)

	# Tooltip mit Tag-Beschreibung
	var desc: String = TagPalette.TAG_DESCRIPTIONS.get(tag, "")
	if desc != "":
		panel.tooltip_text = "%s\n\n%s" % [String(tag).capitalize(), desc]
	else:
		panel.tooltip_text = String(tag).capitalize()

	var label := Label.new()
	label.text = String(tag)
	label.add_theme_font_size_override("font_size", chip_font_size)
	label.add_theme_color_override("font_color", TagPalette.fg(tag))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE   # Tooltip durchreichen
	panel.add_child(label)
	return panel
