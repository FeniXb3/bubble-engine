class_name DataGraphNode
extends GraphNode

@export var text_label: Label

func setup(index: int, text: String, x: float, margin: float, data) -> void:
	text_label.text = text
	position_offset = Vector2(x, (size.y + margin) * index)
	set_meta("data", data)
	hide()
	modulate.a = 0
