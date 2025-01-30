extends CanvasModulate

@export var dialog: AcceptDialog
@export var canvas_modulate: CanvasModulate
@export var inactive_color: Color = Color.WHITE
@export var active_color: Color = Color.DIM_GRAY
@export var visible_material: CanvasItemMaterial
@export var fade_duration: float = 0.5
@export var timer: Timer

var steps: Dictionary[String, TutorialStep]
var previous_control_material: CanvasItemMaterial
var current_step: TutorialStep

class TutorialStep:
	var id: String
	var text: String
	var control: Control

signal step_performed

func _ready() -> void:
	canvas_modulate.color = inactive_color

func register_step(id: String, text: String, control: Control):
	var step := TutorialStep.new()
	step.id = id
	step.text = text
	step.control = control
	steps[id] = step

func perform_step(id: String, params: Dictionary = {}) -> void:
	current_step = steps[id]
	previous_control_material = current_step.control.material
	current_step.control.material = visible_material
	await _fade(active_color).finished
	dialog.dialog_text = current_step.text.format(params)
	timer.start()
	await timer.timeout
	dialog.show()

func _on_accept_dialog_canceled() -> void:
	_handle_step_performed()

func _on_accept_dialog_confirmed() -> void:
	_handle_step_performed()

func _handle_step_performed() -> void:
	timer.start()
	await timer.timeout
	await _fade(inactive_color).finished
	current_step.control.material = previous_control_material
	current_step = null
	
	step_performed.emit()

func _fade(target: Color):
	var tween := self.create_tween()
	tween.tween_property(canvas_modulate, "color", target, fade_duration)
	return tween
