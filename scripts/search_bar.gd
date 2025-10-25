#@tool
class_name SearchBar
extends Control

#@export var container: HBoxContainer
@export var query_field: LineEdit
@export var input_timer: Timer
@export var cleaning_timer: Timer
@export var keyboard_audio_stream_player: AudioStreamPlayer
@export var accessibilityLabel: Label

#@export var flip: bool = true
@export var current_query: Query

var text_length: int = 0

func _ready() -> void:
	SignalBus.query_picked.connect(show_query)
	SignalBus.mood_calculated.connect(clean_query)
	SignalBus.starting.connect(_on_starting)
	
	TutorialManager.register_step("incoming_query", "You have incoming query from a human.", self)
	TutorialManager.register_step("query_repeated", "Wondering why people ask the same questions over and over again?\n
		We made it so easy for them to find answers, that they don't bother to even remember them for more than a minute. They are now depending on their manual work and, of course, on us.", self)

func _on_starting() -> void:
	query_field.clear()
#
#func _process(_delta: float) -> void:
	#custom_minimum_size.y = abs(container.get_rect().size.y)
	#container.pivot_offset = container.get_rect().size / 2
	#container.scale.x = -1 if flip else 1

func show_query(query: Query) -> void:
	text_length = 0
	current_query = query
	input_timer.start()


func _on_timer_timeout() -> void:
	text_length += 1
	keyboard_audio_stream_player.play()
	await get_tree().process_frame
	query_field.text = current_query.text.substr(0, text_length)
	
	
	if query_field.text == current_query.text:
		input_timer.stop()
		await TutorialManager.perform_step("incoming_query")
		query_field.queue_accessibility_update()
		SignalBus.query_submitted.emit()

func clean_query(_mood: int) -> void:
	cleaning_timer.start()
	while query_field.text.length() > 0:
		await cleaning_timer.timeout
		query_field.text = query_field.text.substr(0, query_field.text.length() - 1)
		
	cleaning_timer.stop()
	SignalBus.ready_to_pick_query.emit()
