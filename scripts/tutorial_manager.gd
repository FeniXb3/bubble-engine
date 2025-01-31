extends CanvasModulate

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
	current_step = steps[id]
	if not current_step.should_perform:
		return
	
	var p := current_step.control.global_position
	var rect := current_step.control.get_global_rect()
	var window_size := DisplayServer.window_get_size()
	var right_border := rect.position.x if rect.size.y < 0 else rect.position.x + rect.size.x
	
	if OS.get_name() == "Web": # Popup location is wierd on web, so just disabling it for now for web
		dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	else:
		dialog.initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
		if rect.position.x > window_size.x - right_border:
			dialog.position = Vector2i(rect.position.x - dialog.size.x - dialog_margin, rect.position.y)
		else:
			dialog.position = Vector2i(right_border + dialog_margin, rect.position.y)
	
	_set_tutorial_visible_material(current_step.control)
	await _fade(active_color).finished
	dialog.dialog_text = current_step.text.format(params)
	timer.start()
	await timer.timeout
	dialog.show()
	
	if current_step.one_shot:
		current_step.should_perform = false
	
	await current_step.performed

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
	previous_control_materials[control] = control.material
	control.material = visible_material
	if recursive:
		for child in control.get_children():
			if child is Control:
				_set_tutorial_visible_material(child)

func _reset_material(control: Control, recursive: bool = true):
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
