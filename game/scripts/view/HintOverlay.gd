class_name HintOverlay extends CanvasLayer

# Modaler Hint-Overlay. Statische Methode `show_hint(parent, id, title, text)`.
# Zeigt nichts wenn Hint schon gesehen.

const SCENE_PATH: String = "res://scenes/HintOverlay.tscn"

static func show_if_new(parent: Node, hint_id: String, title: String, text: String) -> void:
	if HintState.has_seen(hint_id):
		return
	HintState.mark_seen(hint_id)
	var scene: PackedScene = load(SCENE_PATH)
	var inst: HintOverlay = scene.instantiate()
	parent.add_child(inst)
	inst.populate(title, text)

func populate(title: String, text: String) -> void:
	$Panel/VBox/TitleLabel.text = title
	$Panel/VBox/TextLabel.text = TagPalette.colorize_tags(text)
	$Panel/VBox/CloseButton.pressed.connect(_close)

func _close() -> void:
	AudioManager.ui("click")
	queue_free()
