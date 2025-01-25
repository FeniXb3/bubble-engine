@tool
class_name SearchBar
extends Control

@export var container: HBoxContainer
@export var query_field: LineEdit

@export var flip: bool = true

func _process(_delta: float) -> void:
	custom_minimum_size.y = abs(container.get_rect().size.y)
	container.pivot_offset = container.get_rect().size / 2
	container.scale.x = -1 if flip else 1

func show_query(query: Query) -> void:
	query_field.text = query.text
