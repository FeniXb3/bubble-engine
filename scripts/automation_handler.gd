extends Node

@export var is_automating: bool = false
@export var automation: Automation

var current_human: Human

func _ready() -> void:
	SignalBus.human_picked.connect(_on_human_picked)
	SignalBus.results_shown.connect(_on_results_shown)


func _on_results_shown(results: Array[Result]) -> void:
	if not is_automating or not current_human or not automation.connections.has(current_human):
		return

	var current_relations = automation.connections[current_human]
	var filtered := results.filter(func(r: Result): 
		return r.positive_tags.any(func(t: String): 
			return current_relations["positive"].has(t) and not current_relations["negative"].has(t)
		)
	)
	if filtered.is_empty():
		return
	SignalBus.results_submitted.emit(filtered)


func _on_human_picked(human: Human, _index: int) -> void:
	current_human = human
