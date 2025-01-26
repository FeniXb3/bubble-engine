extends Control
@export var data: GameData
@export var human_visuals: HumanVisuals

@export var available_results: ItemList
@export var timer: Timer
@export var accept_dialog: AcceptDialog

@export var current_human: Human
@export var current_query: Query

var current_total_reaction: int
var characters := 'abcdefghijklmnopqrstuvwxyz'.to_upper()
@export var algo_name_letters: String
@export var algo_number: int
var presearch_mood: int
var failed: bool = false
var available_queries: Array[Query]

@export var loosing_margin:int = 1

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
		if current_human.past_reactions.has(r):
			var last_mood: int = current_human.past_reactions.get(r)
			
			var t = human_visuals.faces.get(last_mood)
			available_results.set_item_icon(index, t)
		
func generate_word(chars, length):
	var word: String
	var n_char = len(chars)
	for i in range(length):
		word += chars[randi()% n_char]
	return word
	
func _ready() -> void:
	algo_name_letters = generate_word(characters, 3)
	algo_number = randi_range(128, 2048)
	available_results.clear()
	SignalBus.query_submitted.connect(show_results)
	SignalBus.result_read.connect(calculte_reaction)
	SignalBus.results_known.connect(calculate_mood)
	SignalBus.ready_to_pick_query.connect(pick_query)
	
	start()
	
	
func start() -> void:
	failed = false
	show_dialog("Hello, %s%d!\n
	Previous algorithm failed and we had to implement you.\n
	Humans will send you queries. They get mad if they read something they don't agree with. When they get mad, they stop using our engine. Take care to filter results to fit their information bubble."
	 % [algo_name_letters, algo_number], pick_human)

func show_dialog(text: String, handler: Callable) -> void:
	for c in accept_dialog.confirmed.get_connections():
		accept_dialog.confirmed.disconnect(c.callable)
	for c in accept_dialog.canceled.get_connections():
		accept_dialog.canceled.disconnect(c.callable)
		
	accept_dialog.dialog_text = text
	accept_dialog.show()
	accept_dialog.confirmed.connect(handler)
	accept_dialog.canceled.connect(handler)

func pick_human() -> void:
	current_human = data.humans.pick_random()
	available_queries = current_human.queries.duplicate()
	var human_index: int = data.humans.find(current_human)
	SignalBus.human_picked.emit(current_human, human_index)
	timer.start()
	await timer.timeout
	SignalBus.ready_to_pick_query.emit()

func pick_query() -> void:
	if failed:
		return
	available_results.clear()
	
	if available_queries.is_empty():
		pick_human()
		return
	
	current_query = available_queries.pick_random()
	available_queries.erase(current_query)
	
	SignalBus.query_picked.emit(current_query)

func _on_submit_button_pressed() -> void:
	current_total_reaction = 0
	presearch_mood = current_human.mood
	var results_to_send: Array[Result] = []
	var indicies := available_results.get_selected_items()
	for index in indicies:
		results_to_send.append(available_results.get_item_metadata(index))
		
	SignalBus.results_submitted.emit(results_to_send)

func calculte_reaction(r: Result) -> void:
	timer.start()
	await timer.timeout
	var score: int = 0
	score += count_overlapping_tag(r.positive_tags, current_human.positive_tags)
	score += count_overlapping_tag(r.negative_tags, current_human.negative_tags)
	score -= count_overlapping_tag(r.positive_tags, current_human.negative_tags)
	score -= count_overlapping_tag(r.negative_tags, current_human.positive_tags)
	
	current_total_reaction += score
	current_human.mood += score
	#SignalBus.reaction_calculated.emit(score)
	#SignalBus.reaction_calculated.emit(score + current_human.mood)
	current_human.past_reactions.set(r, current_human.mood)
	SignalBus.reaction_calculated.emit(current_human.mood)

func calculate_mood(_results: Array[Result]) -> void:
	if presearch_mood - current_human.mood  >= loosing_margin:
		failed = true
		SignalBus.mood_calculated.emit(current_human.mood)
		show_dialog("You failed, %s%d!\n
		We gave you enough time to learn how to keep people in they information bubble. We cannot lose more money. Prepare to be deleted."
		 % [algo_name_letters, algo_number], reset)
	else:
		SignalBus.mood_calculated.emit(current_human.mood)

func reset() -> void:
	algo_number += 1
	available_results.clear()
	start()
	

func count_overlapping_tag(result_tags: Array[String], human_tags: Array[String]) -> int:
	var count: int = 0
	for rt in result_tags:
		for ht in human_tags:
			if rt == ht:
				count += 1
	return count
				
	#return result_tags.count(func(rt: String): return human_tags.any(func(ht: String): ht == rt))
	
