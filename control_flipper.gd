@tool
class_name ControlFlipper
extends Control

@export var to_flip: Control
@export var container: Control

@export var flip: bool = true

var text_length: int = 0

func _process(_delta: float) -> void:
	# https://docs.godotengine.org/en/stable/tutorials/plugins/running_code_in_the_editor.html#reporting-node-configuration-warnings
	if Engine.is_editor_hint():
		update_configuration_warnings()

	if container == null or to_flip == null:
		return
	
	container.custom_minimum_size.y = abs(to_flip.get_rect().size.y)
	to_flip.pivot_offset = to_flip.get_rect().size / 2
	to_flip.scale.x = -1 if flip else 1


func _get_configuration_warnings():
	var warnings = []
	if container == null:
		warnings.append("Container must be set.")
	if to_flip == null:
		warnings.append("Control to flip must be set.")
	
	return warnings
