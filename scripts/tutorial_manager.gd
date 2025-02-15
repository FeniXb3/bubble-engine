extends CanvasModulate

@export var skip_all_tutorials: bool = false
@export var dialog: AcceptDialog
@export var timer: Timer
@export var fade_duration: float = 0.5
@export_group("Color Change")
@export var should_fade: bool = true
@export var canvas_modulate: CanvasModulate
@export var inactive_color: Color = Color.WHITE
@export var active_color: Color = Color.DIM_GRAY
@export var visible_material: CanvasItemMaterial
@export var dialog_margin: float = 20
@export_group("Audio Pitch Change", "pitch")
@export var pitch_should_change: bool = true
@export var pitch_bus_name: = &"Master"
@export var pitch_gameplay_scale: float = 1.0
@export var pitch_tutorial_scale:= 0.47

var steps: Dictionary[String, TutorialStep]
var previous_control_materials: Dictionary[Control, CanvasItemMaterial]
var current_step: TutorialStep
var pitch_shift_effect: AudioEffectPitchShift

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
	var music_bus_index = AudioServer.get_bus_index(pitch_bus_name)
	for i in AudioServer.get_bus_effect_count(music_bus_index):
		var effect := AudioServer.get_bus_effect(music_bus_index, i)
		if effect is AudioEffectPitchShift:
			pitch_shift_effect = effect
	
	if pitch_shift_effect == null:
		pitch_shift_effect = AudioEffectPitchShift.new()
		AudioServer.add_bus_effect(music_bus_index, pitch_shift_effect)
	

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
	
	dialog.theme = get_tree().root.theme
	current_step = steps[id]
	if not current_step.should_perform:
		return
	
	_set_tutorial_visible_material(current_step.control)
	await _fade(active_color, pitch_tutorial_scale).finished
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
	var title_size := dialog.get_theme_constant("title_height")
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
		
		dialog.position.y += title_size
		
		var y_overflow = dialog.position.y + dialog.size.y + dialog_margin - viewport_size.y
		if y_overflow > 0:
			dialog.position.y -= int(y_overflow)
			
	if not get_tree().root.is_embedding_subwindows():
		dialog.position += get_window().position

func _on_accept_dialog_canceled() -> void:
	_handle_step_performed()

func _on_accept_dialog_confirmed() -> void:
	_handle_step_performed()

func _handle_step_performed() -> void:
	timer.start()
	await timer.timeout
	await _fade(inactive_color, pitch_gameplay_scale).finished
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
	
func _fade(target: Color, target_audio_pitch: float):
	var tween := self.create_tween().set_parallel()
	if should_fade:
		tween.tween_property(canvas_modulate, "color", target, fade_duration)
	if pitch_should_change:
		tween.tween_property(pitch_shift_effect, "pitch_scale", target_audio_pitch, fade_duration)
	return tween
