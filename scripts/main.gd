extends Control
@export var data: GameData

@export var available_results: ItemList
@export var search_bar: SearchBar

@export var current_human: Human
@export var current_query: Query


func get_related_results(query: Query) -> Array[Result]:
	var query_tags := query.negative_tags + query.positive_tags
	return data.results.filter(func(r: Result): return filter_result(r, query_tags))
	
func filter_result(r: Result, tags: Array[String]) -> bool:
	return r.positive_tags.any(func(t: String): return tags.has(t)) or r.negative_tags.any(func(t: String): return tags.has(t))

func show_results() -> void:
	var results := get_related_results(current_query)
	
	available_results.clear()
	for r in results:
		available_results.add_item(r.title)
		
func _ready() -> void:
	current_human = data.humans.pick_random()
	current_query = current_human.queries.pick_random()
	
	search_bar.show_query(current_query)
	show_results()
