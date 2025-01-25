extends Control

@export var results_list: ItemList

func _ready() -> void:
	results_list.clear()
	SignalBus.results_submitted.connect(show_results)
	
func show_results(results) -> void:
	results_list.clear()
	for r in results:
		var index = results_list.add_item(r.title)
		results_list.set_item_metadata(index, r)
