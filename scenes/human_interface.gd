extends Control

@export var results_list: ItemList
@export var reading_timer: Timer
@export var face_update_timer: Timer
@export var control_flipper: ControlFlipper

@export var avatar: Avatar

func _ready() -> void:
	results_list.clear()
	SignalBus.results_submitted.connect(show_results)
	SignalBus.ready_to_pick_query.connect(clean_results)
	SignalBus.flip_change_requested.connect(update_flip_state)
	SignalBus.starting.connect(_on_starting)
	
func _on_starting() -> void:
	results_list.clear()

func update_flip_state(value: bool) -> void:
	control_flipper.flip = value
	
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
		var t: Texture = await avatar.face_updated
		face_update_timer.start()
		await face_update_timer.timeout
		results_list.set_item_icon(index, t)
		
	reading_timer.stop()
	SignalBus.results_known.emit(results)
