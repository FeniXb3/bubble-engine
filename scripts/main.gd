extends Control
@export var data: GameData

@export var available_results: ItemList


func get_related_results(query: Query) -> Array[Result]:
	var query_tags := query.negative_tags + query.positive_tags
	return data.results.filter(func(r: Result): return filter_result(r, query_tags))
	
func filter_result(r: Result, tags: Array[String]) -> bool:
	return r.positive_tags.any(func(t: String): return tags.has(t)) or r.negative_tags.any(func(t: String): return tags.has(t))

func _ready() -> void:
	var human: Human = data.humans.pick_random()
	var query: Query = human.queries.pick_random()
	var results := get_related_results(query)
	
	available_results.clear()
	for r in results:
		available_results.add_item(r.title)
