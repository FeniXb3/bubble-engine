#@tool
class_name SearchBar
extends Control

#@export var container: HBoxContainer
@export var query_field: LineEdit
@export var input_timer: Timer

#@export var flip: bool = true
@export var current_query: Query

var text_length: int = 0

func _ready() -> void:
	SignalBus.query_picked.connect(show_query)

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
