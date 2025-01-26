extends Control
@export var data: GameData
@export var human_visuals: HumanVisuals

@export var available_results: ItemList
@export var timer: Timer
@export var accept_dialog: AcceptDialog
@export var animation_player: AnimationPlayer
@export var bg_animation_player: AnimationPlayer
@export var music_player: AudioStreamPlayer
@export var submit_button: Button

@export var current_human: Human
@export var current_query: Query

var current_total_reaction: int
var characters := 'abcdefghijklmnopqrstuvwxyz'.to_upper()
@export var algo_name_letters: String
@export var algo_number: int
var presearch_mood: int
var failed: bool = false
var available_queries: Array[Query]
var available_humans: Array[Human]
var first_time := true

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
			
	available_results.grab_focus()
	
	if first_time:
		first_time = false
		show_dialog("Pay attention, %s%d!\n
			You have incoming query from a human. Click on the list to pick result fitting their information bubble. When you're done, press Submit button.\n\n
			Better be better than %s%d"
	 % [algo_name_letters, algo_number,
		algo_name_letters, algo_number-1], func(): pass)
		
func generate_word(chars, length):
	var word: String = ""
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
	
	available_humans = data.humans.duplicate()
	start()
	
	
func start() -> void:
	
	bg_animation_player.play("start", 0.01)
	animation_player.play("turn_on")
	await animation_player.animation_finished
	failed = false
	show_dialog("Hello, %s%d!\n
	Algorithm %s%d failed and we had to implement you.\n
	Humans will send you queries. They get mad if they read something they don't agree with. When they get mad, they stop using our engine. Take care to filter results to fit their information bubble."
	 % [algo_name_letters, algo_number,
		algo_name_letters, algo_number-1], pick_human)

func show_dialog(text: String, handler: Callable) -> void:
	for c in accept_dialog.confirmed.get_connections():
		accept_dialog.confirmed.disconnect(c.callable)
	for c in accept_dialog.canceled.get_connections():
		accept_dialog.canceled.disconnect(c.callable)
		
	accept_dialog.dialog_text = text
	accept_dialog.show()
	if handler:
		accept_dialog.confirmed.connect(handler)
		accept_dialog.canceled.connect(handler)

func pick_human() -> void:
	if not music_player.playing:
		music_player.play()
	
	if available_humans.is_empty():
		available_humans = data.humans.duplicate()
		
	current_human = available_humans.pick_random()
	available_humans.erase(current_human)
	
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
	submit_button.disabled = true

func calculte_reaction(r: Result) -> void:
	timer.start()
	await timer.timeout
	var score: int = 0
	score += count_overlapping_tag(r.positive_tags, current_human.positive_tags)
	score += count_overlapping_tag(r.negative_tags, current_human.negative_tags)
	score -= count_overlapping_tag(r.positive_tags, current_human.negative_tags)
	score -= count_overlapping_tag(r.negative_tags, current_human.positive_tags)
	
	current_total_reaction += score
	current_human.mood = clampi(current_human.mood + score, -4, 3,)
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
	animation_player.play("shut_down")
	bg_animation_player.play("stop")
	#await animation_player.animation_finished
	await bg_animation_player.animation_finished
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
	


func _on_check_box_toggled(toggled_on: bool) -> void:
	SignalBus.flip_change_requested.emit(not toggled_on)


func _on_available_results_multi_selected(index: int, selected: bool) -> void:
	var indicies := available_results.get_selected_items()
	submit_button.disabled = indicies.is_empty()
		
