extends Control
@export var data: GameData

@export var available_results: ItemList
@export var search_bar: SearchBar

@export var current_human: Human
@export var current_query: Query

var current_total_reaction: int


func get_related_results(query: Query) -> Array[Result]:
	var query_tags := query.negative_tags + query.positive_tags
	return data.results.filter(func(r: Result): return filter_result(r, query_tags))
	
func filter_result(r: Result, tags: Array[String]) -> bool:
	return r.positive_tags.any(func(t: String): return tags.has(t)) or r.negative_tags.any(func(t: String): return tags.has(t))

func show_results() -> void:
	var results := get_related_results(current_query)
	
	available_results.clear()
	for r in results:
		var index = available_results.add_item(r.title)
		available_results.set_item_metadata(index, r)
		
func _ready() -> void:
	available_results.clear()
	SignalBus.query_submitted.connect(show_results)
	SignalBus.result_read.connect(calculte_reaction)
	SignalBus.results_known.connect(calculate_mood)
	SignalBus.ready_to_pick_query.connect(pick_query)
	
	pick_human()

func pick_human() -> void:
	current_human = data.humans.pick_random()
	SignalBus.ready_to_pick_query.emit()

func pick_query() -> void:
	available_results.clear()
	current_query = current_human.queries.pick_random()
	
	SignalBus.query_picked.emit(current_query)

func _on_submit_button_pressed() -> void:
	current_total_reaction = 0
	var results_to_send: Array[Result] = []
	var indicies := available_results.get_selected_items()
	for index in indicies:
		results_to_send.append(available_results.get_item_metadata(index))
		
	SignalBus.results_submitted.emit(results_to_send)

func calculte_reaction(r: Result) -> void:
	var score: int = 0
	score += count_overlapping_tag(r.positive_tags, current_human.positive_tags)
	score += count_overlapping_tag(r.negative_tags, current_human.negative_tags)
	score -= count_overlapping_tag(r.positive_tags, current_human.negative_tags)
	score -= count_overlapping_tag(r.negative_tags, current_human.positive_tags)
	
	current_total_reaction += score
	
	SignalBus.reaction_calculated.emit(score)

func calculate_mood(results: Array[Result]) -> void:
	current_human.mood += current_total_reaction
	SignalBus.mood_calculated.emit(current_human.mood)
#func calculte_reaction(results: Array[Result]) -> void:
	#var score: int = 0
	#for r in results:
		#print(r.positive_tags)
		##score += r.positive_tags.count(func(t: String): return current_human.positive_tags.any(func(ht: String): ht == t))
		#score += count_overlapping_tag(r.positive_tags, current_human.positive_tags)
		#score += count_overlapping_tag(r.negative_tags, current_human.negative_tags)
		#score -= count_overlapping_tag(r.positive_tags, current_human.negative_tags)
		#score -= count_overlapping_tag(r.negative_tags, current_human.positive_tags)
		#
	#print(score)
	#
	#SignalBus.reaction_calculated.emit(score)
		

func count_overlapping_tag(result_tags: Array[String], human_tags: Array[String]) -> int:
	var count: int = 0
	for rt in result_tags:
		for ht in human_tags:
			if rt == ht:
				count += 1
	return count
				
	#return result_tags.count(func(rt: String): return human_tags.any(func(ht: String): ht == rt))
	
