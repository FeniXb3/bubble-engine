#@tool
class_name SearchBar
extends Control

#@export var container: HBoxContainer
@export var query_field: LineEdit
@export var input_timer: Timer
@export var cleaning_timer: Timer

#@export var flip: bool = true
@export var current_query: Query

var text_length: int = 0

func _ready() -> void:
	SignalBus.query_picked.connect(show_query)
	SignalBus.mood_calculated.connect(clean_query)
	SignalBus.starting.connect(_on_starting)
	
	TutorialManager.register_step("incoming_query", "Pay attention, {algo_letters}{algo_number}!\n
			You have incoming query from a human. Click on the list to pick one or more results fitting their information bubble. When you're done, press Submit button.\n\n
			Better be better than {algo_letters}{prev_algo_number}", query_field)

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
	query_field.text = current_query.text.substr(0, text_length)
	
	if query_field.text == current_query.text:
		input_timer.stop()
		SignalBus.query_submitted.emit()
		

func clean_query(_mood: int) -> void:
	cleaning_timer.start()
	while query_field.text.length() > 0:
		await cleaning_timer.timeout
		query_field.text = query_field.text.substr(0, query_field.text.length() - 1)
		
	cleaning_timer.stop()
	SignalBus.ready_to_pick_query.emit()
