extends Node

@export var target_control: Control
@export var mode: FocusSetterMode = FocusSetterMode.Show

enum FocusSetterMode {
	Show = 0,
	Ready = 1,
}

func _ready() -> void:
	if mode == FocusSetterMode.Show:
		target_control.visibility_changed.connect(_on_target_control_visibility_changed)
	elif mode == FocusSetterMode.Ready:
		await ready
		target_control.grab_focus()

func _on_target_control_visibility_changed() -> void:
	if target_control.is_visible_in_tree():
		target_control.grab_focus()
