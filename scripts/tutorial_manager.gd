extends CanvasModulate

@export var skip_all_tutorials: bool = false
@export var dialog: AcceptDialog
@export var canvas_modulate: CanvasModulate
@export var inactive_color: Color = Color.WHITE
@export var active_color: Color = Color.DIM_GRAY
@export var visible_material: CanvasItemMaterial
@export var fade_duration: float = 0.5
@export var timer: Timer
@export var dialog_margin: float = 20

var steps: Dictionary[String, TutorialStep]
var previous_control_materials: Dictionary[Control, CanvasItemMaterial]
var current_step: TutorialStep

class TutorialStep:
	var id: String
	var text: String
	var control: Control
	var should_perform: bool
	var one_shot: bool
	
	signal performed

func _ready() -> void:
	dialog.visible = false
	canvas_modulate.color = inactive_color

func register_step(id: String, text: String, control: Control, one_shot: bool = true):
	var step := TutorialStep.new()
	step.id = id
	step.text = text
	step.control = control
	step.should_perform = true
	step.one_shot = one_shot
	
	steps[id] = step

func perform_step(id: String, params: Dictionary = {}) -> void:
	if skip_all_tutorials:
		return
	
	current_step = steps[id]
	if not current_step.should_perform:
		return
	
	_set_tutorial_visible_material(current_step.control)
	await _fade(active_color).finished
	dialog.dialog_text = current_step.text.format(params)
	_calculate_position()
	timer.start()
	await timer.timeout
	dialog.show()
	
	if current_step.one_shot:
		current_step.should_perform = false
	
	await current_step.performed

func _calculate_position() -> void:
	dialog.reset_size()
	var viewport_size := get_viewport_rect().size
	if current_step.control == null:
		dialog.initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
		dialog.position = (Vector2i)(viewport_size / 2) - dialog.size / 2
	else:
		var rect := current_step.control.get_global_rect()
		var right_border := rect.position.x if rect.size.y < 0 else rect.position.x + rect.size.x
		
		dialog.initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
		if rect.position.x > viewport_size.x - right_border:
			dialog.position = Vector2i(int(rect.position.x - dialog.size.x - dialog_margin), int(rect.position.y))
		else:
			dialog.position = Vector2i(int(right_border + dialog_margin), int(rect.position.y))
			
		var y_overflow = dialog.position.y + dialog.size.y + dialog_margin - viewport_size.y
		if y_overflow > 0:
			dialog.position.y -= int(y_overflow)

func _on_accept_dialog_canceled() -> void:
	_handle_step_performed()

func _on_accept_dialog_confirmed() -> void:
	_handle_step_performed()

func _handle_step_performed() -> void:
	timer.start()
	await timer.timeout
	await _fade(inactive_color).finished
	_reset_material(current_step.control)
	
	current_step.performed.emit()

func _set_tutorial_visible_material(control: Control, recursive: bool = true):
	if control == null:
		return
	
	previous_control_materials[control] = control.material
	control.material = visible_material
	if recursive:
		for child in control.get_children():
			if child is Control:
				_set_tutorial_visible_material(child)

func _reset_material(control: Control, recursive: bool = true):
	if control == null:
		return
	
	control.material = previous_control_materials[control]
	previous_control_materials.erase(control)
	if recursive:
		for child in control.get_children():
			if child is Control:
				_reset_material(child)
	
func _fade(target: Color):
	var tween := self.create_tween()
	tween.tween_property(canvas_modulate, "color", target, fade_duration)
	return tween
