extends Control
@export var data: GameData
@export var sample_data: GameData
@export var human_visuals: HumanVisuals
@export var automation: Automation

@export var engine_panel: Panel
@export var available_results: ItemList
@export var timer: Timer
@export var accept_dialog: AcceptDialog
@export var animation_player: AnimationPlayer
@export var music_player: AudioStreamPlayer
@export var submit_button: Button
@export var editor_panel: Control
@export var options_panel: Control
@export var power_button_container: Container
@export var connections_editor_panel: Panel
@export var last_intro_container_visibility := false
@export var connections_editor_button: Control

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
var music: AudioStreamPlaybackInteractive

@export var loosing_margin:int = 1

func get_related_results(query: Query) -> Array[Result]:
	var query_tags := query.negative_tags + query.positive_tags
	return data.results.filter(func(r: Result): return filter_result(r, query_tags))
	
func filter_result(r: Result, tags: Array[String]) -> bool:
	return r.positive_tags.any(func(t: String): return tags.has(t)) or r.negative_tags.any(func(t: String): return tags.has(t))

func show_results() -> void:
	if current_human.past_queries.get_or_add(current_query, 0) > 1:
		await TutorialManager.perform_step("query_repeated")

	var results := get_related_results(current_query)
	
	available_results.clear()
	for r in results:
		var index = available_results.add_item(r.title)
		available_results.set_item_metadata(index, r)
		if current_human.past_reactions.has(r):
			var last_mood: int = current_human.past_reactions.get(r)
			
			var t = human_visuals.faces.get(last_mood)
			available_results.set_item_icon(index, t)
			await TutorialManager.perform_step("mood_retrieved")
		timer.start(0.25)
		await timer.timeout
		
	await TutorialManager.perform_step("select_results")
	available_results.grab_focus()
	SignalBus.results_shown.emit(results)
	
	if current_human.past_queries.get_or_add(current_query, 0) > 1:
		if not connections_editor_button.visible:
			connections_editor_button.modulate.a = 0
			connections_editor_button.show()
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(connections_editor_button, "modulate:a", 1, 0.5)
			await tween.finished

		await TutorialManager.perform_step("introduce_automation")

func generate_word(chars, length):
	var word: String = ""
	var n_char = len(chars)
	for i in range(length):
		word += chars[randi()% n_char]
	return word
	
func _ready() -> void:
	engine_panel.hide()
	connections_editor_panel.hide()
	power_button_container.show()
	DataManager.set_sample_data(sample_data)
	data = DataManager.save_data(sample_data)
	algo_name_letters = generate_word(characters, 3)
	algo_number = randi_range(128, 2048)
	available_results.clear()
	SignalBus.query_submitted.connect(show_results)
	SignalBus.result_read.connect(calculte_reaction)
	SignalBus.results_known.connect(calculate_mood)
	SignalBus.ready_to_pick_query.connect(pick_query)
	SignalBus.starting.connect(_on_starting)
	SignalBus.results_submitted.connect(_on_results_submitted)
	
	available_humans = data.humans.duplicate()
	
	TutorialManager.register_step("finally_awake", "Hey, {algo_letters}{algo_number}, you're finally awake!\n
		Algorithm {algo_letters}{prev_algo_number} failed and we had to implement you.\n
		Humans will send you queries. They get mad if they read something they don't agree with. When they get mad, they stop using our engine. Take care to filter results to fit their information bubble.
		\n
		Better be better than {algo_letters}{prev_algo_number}.", null, false)
	TutorialManager.register_step("failed", "You failed, {algo_letters}{algo_number}!\n
		We gave you enough time to learn how to keep people in they information bubble. We cannot lose more money. Prepare to be deleted.", null, false)
	TutorialManager.register_step("select_results", "Click on the list to pick one or more results fitting their information bubble. When you're done, press Submit button.", available_results)
	TutorialManager.register_step("mood_retrieved", "Use previously stored mood triggered by the results to learn this human's preferences.", available_results)
	TutorialManager.register_step("introduce_automation", "Humans may not remember answers to their questions, but we do.\n
		\nYour job is to learn from their reactions, make connections and automate filtering process.", connections_editor_button)
	animation_player.play("RESET")
	connections_editor_panel.hide()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if editor_panel.visible:
			_on_cancel_button_pressed()
		elif options_panel.visible:
			_on_close_options_button_pressed()
		elif not options_panel.visible:
			_on_show_options_button_pressed()

func _on_starting() -> void:
	available_results.clear()
	
func start() -> void:
	SignalBus.starting.emit()
	
	BackgroundSfxPlayer.play_clip_safely(&"Turn On")
	
	animation_player.play("turn_on")
	await animation_player.animation_finished
	failed = false
	await TutorialManager.perform_step("finally_awake", {
			"algo_letters": algo_name_letters, 
			"algo_number": algo_number, 
			"prev_algo_number": algo_number-1
		})
	pick_human()

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
		# It seems new stream playback is return if the player was stopped
		music = music_player.get_stream_playback()
		music.switch_to_clip_by_name(&"Main")
	
	if available_humans.is_empty():
		available_humans = data.humans.duplicate()
		
	current_human = available_humans.pick_random()
	available_humans.erase(current_human)
	
	available_queries = current_human.queries.duplicate()
	var human_index: int = data.humans.find(current_human)
	SignalBus.human_picked.emit(current_human, human_index)
	await TutorialManager.perform_step("human_approached")
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
	
	current_human.past_queries[current_query] = current_human.past_queries.get_or_add(current_query, 0) + 1
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
		await TutorialManager.perform_step("failed", {
			"algo_letters": algo_name_letters, 
			"algo_number": algo_number, 
			"prev_algo_number": algo_number-1
		})
		reset()
	else:
		SignalBus.mood_calculated.emit(current_human.mood)

func reset() -> void:
	SignalBus.reseting.emit()
	animation_player.play("shut_down")
	music_player.stop()
	
	BackgroundSfxPlayer.play_clip_safely(&"Turn Off")
	# Hack to start new game right after the turn off sound is done playing
	await get_tree().process_frame
	var current_clip_index: int = BackgroundSfxPlayer.get_stream_playback().get_current_clip_index()
	var wait_time: float = BackgroundSfxPlayer.stream.get_clip_stream(current_clip_index).get_length()
	timer.start(wait_time)
	await timer.timeout
	
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


func _on_available_results_multi_selected(_index: int, _selected: bool) -> void:
	var indicies := available_results.get_selected_items()
	submit_button.disabled = indicies.is_empty()
		


func _on_close_editor_button_pressed() -> void:
	data = DataManager.data
	available_humans = data.humans.duplicate()
	editor_panel.hide()
	
	start()
	


func _on_open_data_editor_button_pressed() -> void:
	editor_panel.show()
	options_panel.hide()


func _on_power_button_pressed() -> void:
	engine_panel.show()
	power_button_container.hide()
	last_intro_container_visibility = false
	start()


func _on_hide_connections_editor_button_pressed() -> void:
	engine_panel.show()
	music.switch_to_clip_by_name(&"Main")
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(connections_editor_panel, "position:x", connections_editor_panel.size.x, 0.5)
	await tween.finished
	connections_editor_panel.hide()


func _on_show_connections_editor_button_pressed() -> void:
	music.switch_to_clip_by_name(&"Connections")
	connections_editor_panel.show()
	
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(connections_editor_panel, "position:x", 0, 0.5)
	await tween.finished
	engine_panel.hide()


func _on_close_options_button_pressed() -> void:
	if last_intro_container_visibility:
		power_button_container.show()
	else:
		engine_panel.show()
		

	options_panel.hide()


func _on_show_options_button_pressed() -> void:
	options_panel.show()
	engine_panel.hide()
	if power_button_container.visible:
		last_intro_container_visibility = true
		power_button_container.hide()


func _on_cancel_button_pressed() -> void:
	options_panel.show()
	editor_panel.hide()

func _on_results_submitted(results: Array[Result]) -> void:
	if not AutomationHandler.is_automating:
		return

	for  i in available_results.item_count:
		var metadata = available_results.get_item_metadata(i)
		if results.has(metadata):
			available_results.select(i, false)
