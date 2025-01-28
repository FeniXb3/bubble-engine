extends Control

@export_group("Controls")
@export var tree: Tree
@export var save_dialog: FileDialog
@export var load_dialog: FileDialog
@export var save_button: Button
@export var discard_button: Button

@export_group("Data")
@export var human_visuals: HumanVisuals
@export var game_data: GameData
@export var worst_mood: int = -3
@export var best_mood: int = 3
@export var current_path: String
@export var modified: bool = false:
	set(value):
		modified = value
		save_button.disabled = not modified or current_path == null or current_path.is_empty()
		discard_button.disabled = save_button.disabled
var tag_holders_to_update: Array[TreeItem]

const TYPE_COLUMN := 0
const NAME_COLUMN := 0
const MOOD_COLUMN := 0
#const MOOD_ICON_COLUMN := 2
#const POSITIVE_COLUMN := 3
#const NEGATIVE_COLUMN := 4

func _ready() -> void:
	save_dialog.file_selected.connect(save_data)
	load_dialog.file_selected.connect(load_data)
	
	DataManager.load_data()
	DataManager.save_data()
	DataManager.load_data()
	game_data = DataManager.data
	#populate_tree()
	
func populate_tree() -> void:
	tree.clear()
	tag_holders_to_update.clear()
	var root = tree.create_item()
	root.set_metadata(0, game_data)
	
	print(JSON.stringify(game_data).c_unescape())
	#tree.set_column_title(TYPE_COLUMN, "Type")
	tree.set_column_title(NAME_COLUMN, "Name")
	tree.set_column_title(MOOD_COLUMN, "Mood Value")
	#tree.set_column_title(MOOD_ICON_COLUMN, "Mood Face")
	
	var tags_parent_branch := tree.create_item(root)
	tags_parent_branch.set_text(TYPE_COLUMN, "Available Tags")
	tags_parent_branch.set_metadata(0, game_data.tags)
	
	for t in game_data.tags:
		var item := _create_editable_item_with_text(tags_parent_branch, t)
		item.set_metadata(0, t)
	
	var humans_parent_branch := tree.create_item(root)
	humans_parent_branch.set_text(TYPE_COLUMN, "Humans")
	
	humans_parent_branch.set_metadata(0, game_data.humans)
	
	for h in game_data.humans:
		var human_branch := _create_editable_item_with_text(humans_parent_branch, h.name)
		human_branch.set_metadata(0, h)
	
		#human_branch.set_cell_mode(MOOD_COLUMN, TreeItem.CELL_MODE_CUSTOM)
		
		var mood_parent_branch := tree.create_item(human_branch)
		mood_parent_branch.set_text(TYPE_COLUMN, "Mood")
		mood_parent_branch.set_metadata(0, h)
		
		var face_texture = human_visuals.faces.get(h.mood)
		mood_parent_branch.set_icon(NAME_COLUMN, face_texture)
		
		
		var mood_branch := tree.create_item(mood_parent_branch)
		#mood_branch.set_text(TYPE_COLUMN, "Mood")
		mood_branch.set_cell_mode(MOOD_COLUMN, TreeItem.CELL_MODE_RANGE)
		mood_branch.set_range_config(MOOD_COLUMN, worst_mood, best_mood, 1)
		mood_branch.set_range(MOOD_COLUMN, h.mood)
		mood_branch.set_editable(MOOD_COLUMN, true)
		#mood_branch.set_metadata(0, h.mood)
		mood_branch.set_metadata(0, func(item: TreeItem): _update_mood(item, h))
		
		
		
		#human_branch.set_cell_mode(MOOD_COLUMN, TreeItem.CELL_MODE_RANGE)
		#human_branch.set_range_config(MOOD_COLUMN, worst_mood, best_mood, 1)
		#human_branch.set_range(MOOD_COLUMN, h.mood)
		#human_branch.set_editable(MOOD_COLUMN, true)
		
		#human_branch.set_cell_mode(MOOD_ICON_COLUMN, TreeItem.CELL_MODE_ICON)
		
		
		var queries_parent_branch := tree.create_item(human_branch)
		queries_parent_branch.set_text(TYPE_COLUMN, "Queries")
		queries_parent_branch.set_metadata(0, h.queries)
		
		for q in h.queries:
			var query_branch := _create_editable_item_with_text(queries_parent_branch, q.text)
			query_branch.set_metadata(0, q)
			_add_tags(query_branch, q)
		
		_add_tags(human_branch, h)

	var results_parent_branch := tree.create_item(root)
	results_parent_branch.set_text(TYPE_COLUMN, "Results")
	results_parent_branch.set_metadata(0, game_data.results)
	
	for r in game_data.results:
		var result_branch := _create_editable_item_with_text(results_parent_branch, r.title)
		result_branch.set_metadata(0, r)
		_add_tags(result_branch, r)
		
	root.set_collapsed_recursive(true)
	root.collapsed = false
	
func _update_mood(item: TreeItem, human: Human) -> void:
	var mood := int(item.get_range(MOOD_COLUMN))
	var new_face_texture = human_visuals.faces.get(mood)
	item.get_parent().set_icon.call_deferred(NAME_COLUMN, new_face_texture)
	human.mood = mood

func _add_tags(parent_branch: TreeItem, data_with_tags) -> void:
	_add_array_dropdowns(parent_branch, "Positive about", data_with_tags.positive_tags, game_data.tags)
	_add_array_dropdowns(parent_branch, "Negative about", data_with_tags.negative_tags, game_data.tags)

func _add_array_dropdowns(parent_branch: TreeItem, dropdowns_name: String, data: Array[String], options: Array[String], add_empty_element: bool = true) -> void:
	var dropdowns_parent_branch := tree.create_item(parent_branch)
	dropdowns_parent_branch.set_text(NAME_COLUMN, dropdowns_name)
	dropdowns_parent_branch.set_metadata(0, data)
	
	for t in data:
		var all_tags := ("---," if add_empty_element else "") + ",".join(options)
		var selected_index := game_data.tags.find(t) + (1 if add_empty_element else 0)
		var item := _create_editable_dropdown_item(dropdowns_parent_branch, all_tags, selected_index)
		item.set_metadata(0, t)
		
		tag_holders_to_update.append(item)

func _on_tree_item_edited() -> void:
	modified = true
	var item := tree.get_edited()
	var column := tree.get_edited_column()
	var metadata = item.get_metadata(0)
	
	if metadata is Human:
		if column == NAME_COLUMN:
			metadata.name = item.get_text(column)
		elif column == MOOD_COLUMN:
			var mood := int(item.get_range(MOOD_COLUMN))
			var face_texture = human_visuals.faces.get(mood)
			item.set_icon.call_deferred(NAME_COLUMN, face_texture)
			
			metadata.mood = mood
	elif metadata is String:
		var parent_metadata = item.get_parent().get_metadata(0) as Array
		var index = parent_metadata.find(metadata)
		if item.get_parent().get_parent().get_metadata(0) is GameData:
			parent_metadata[index] = item.get_text(0)
			item.set_metadata(0, item.get_text(0))
			_update_tags_dropdown()
		else:
			var available_tag_index: int = int(item.get_range(0))
			parent_metadata[index] = game_data.tags[available_tag_index - 1]
		
		
	elif metadata is Result:
		metadata.title = item.get_text(column)
	elif metadata is Query:
		metadata.text = item.get_text(column)
	elif metadata is Callable:
		metadata.call(item)
		
func _create_editable_item_with_text(parent: TreeItem, text: String, column: int = NAME_COLUMN) -> TreeItem:
		var item := tree.create_item(parent)
		item.set_text(column, text)
		item.set_editable(NAME_COLUMN, true)
		
		return item

func _create_editable_dropdown_item(parent: TreeItem, text: String, selected_index: int, column: int = NAME_COLUMN) -> TreeItem:
		var item := tree.create_item(parent)
		item.set_cell_mode(NAME_COLUMN, TreeItem.CELL_MODE_RANGE)
		item.set_text(column, text)
		item.set_range(NAME_COLUMN, selected_index)
		item.set_editable(NAME_COLUMN, true)
		
		return item

func _on_save_as_button_pressed() -> void:
	save_dialog.show()
	
func save_data(path: String) -> void:
	current_path = path
	DataManager.save_data(current_path)
	modified = false

func _on_load_button_pressed() -> void:
	load_dialog.show()
	
func load_data(path: String) -> void:
	current_path = path
	DataManager.load_data(path)
	game_data = DataManager.data
	modified = false
	populate_tree()

func _on_discard_changes_button_pressed() -> void:
	DataManager.load_data(current_path)
	game_data = DataManager.data
	modified = false
	populate_tree()

func _on_save_button_pressed() -> void:
	DataManager.save_data(current_path)
	modified = false


func _on_load_defaults_button_pressed() -> void:
	#current_path = DataManager.default_path
	DataManager.load_data()
	game_data = DataManager.data
	modified = false
	populate_tree()

func _update_tags_dropdown(add_empty_element: bool = true) -> void:
	var options = game_data.tags
	for item in tag_holders_to_update:
		var all_tags := ("---," if add_empty_element else "") + ",".join(options)
		item.set_text(0, all_tags)
		var metadata = item.get_metadata(0)
		
		var parent_metadata = item.get_parent().get_metadata(0) as Array
		var index = parent_metadata.find(metadata)
		parent_metadata[index] = game_data.tags[int(item.get_range(0)) - 1]
