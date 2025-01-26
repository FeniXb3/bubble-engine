extends Control

@export var results_list: ItemList
@export var reading_timer: Timer
@export var face_update_timer: Timer

@export var face: TextureRect
@export var human_visuals: HumanVisuals

func _ready() -> void:
	results_list.clear()
	SignalBus.results_submitted.connect(show_results)
	SignalBus.mood_calculated.connect(update_face)
	SignalBus.ready_to_pick_query.connect(clean_results)
	
func clean_results() -> void:
	results_list.clear()
	
func show_results(results) -> void:
	results_list.clear()
	reading_timer.start()
	for r in results:
		await reading_timer.timeout
		var index = results_list.add_item(r.title)
		results_list.set_item_metadata(index, r)
		SignalBus.result_read.emit(r)
		var response_mood: int = await SignalBus.reaction_calculated
		update_face(response_mood)
		face_update_timer.start()
		await face_update_timer.timeout
		var t = human_visuals.faces.get(response_mood)
		results_list.set_item_icon(index, t)
		
	reading_timer.stop()
	SignalBus.results_known.emit(results)

func update_face(mood: int) -> void:
	var t = human_visuals.faces.get(mood)
	face.texture = t
