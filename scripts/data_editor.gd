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
@export var add_empty_element: bool = true
@export var empty_dropdown_element: String = "---"
@export var current_path: String
@export var modified: bool = false:
	set(value):
		modified = value
		save_button.disabled = not modified or current_path == null or current_path.is_empty()
		discard_button.disabled = save_button.disabled
@export var add_texture: Texture2D
@export var remove_texture: Texture2D
@export var should_collapse_tree: bool = false
		
var tag_holders_to_update: Array[TreeItem]

const NAME_COLUMN := 0
const BUTTON_COLUMN := 1

func _ready() -> void:
	save_dialog.file_selected.connect(save_data)
	load_dialog.file_selected.connect(load_data)
	
	DataManager.load_data()
	DataManager.save_current_data()
	DataManager.load_data()
	game_data = DataManager.data

func _populate_available_tag(parent: TreeItem, i: int) -> void:
	var tag_item := _create_editable_item_with_text(parent, game_data.tags[i])
	tag_item.set_metadata(NAME_COLUMN, func(item: TreeItem): _update_available_tag(item, i, game_data.tags))

func _populate_tag(parent: TreeItem, i: int, data: Array[String],  options: Array[String]) -> TreeItem:
	var all_tags := (empty_dropdown_element + "," if add_empty_element else "") + ",".join(options)
	var selected_index := options.find(data[i]) + (1 if add_empty_element else 0)
	var tag_item := _create_editable_dropdown_item(parent, all_tags, selected_index)
	tag_item.set_metadata(NAME_COLUMN, func(item: TreeItem): _update_tag(item, parent, data))
	
	tag_item.add_button(BUTTON_COLUMN, remove_texture)
	tag_item.set_metadata(BUTTON_COLUMN, func(): _remove_text_range_item(parent, tag_item, data))

	
	tag_holders_to_update.append(tag_item)
	
	return tag_item

func _remove_human(parent: TreeItem, item: TreeItem, h: Human, humans: Array[Human]) -> void:
	var index := humans.find(h)
	humans.remove_at(index)
	parent.remove_child(item)

func _remove_item(parent: TreeItem, item: TreeItem, element: Variant, array: Array) -> void:
	modified = true
	var index := array.find(element)
	array.remove_at(index)
	parent.remove_child(item)
	
func _remove_text_range_item(parent: TreeItem, item: TreeItem, array: Array) -> void:
	modified = true
	var available_tag_index := int(item.get_range(NAME_COLUMN)) - (1 if add_empty_element else 0)
	var text := game_data.tags[available_tag_index] if available_tag_index >= 0 else empty_dropdown_element
	array.erase(text)
	parent.remove_child(item)
	
func _populate_human(parent: TreeItem, h: Human) -> void:
	var human_branch := _create_editable_item_with_text(parent, h.name)
	human_branch.set_metadata(NAME_COLUMN, func(item: TreeItem): h.name = item.get_text(NAME_COLUMN))
	
	human_branch.add_button(BUTTON_COLUMN, remove_texture)
	human_branch.set_metadata(BUTTON_COLUMN, func(): _remove_item(parent, human_branch, h, game_data.humans))
	
	var mood_parent_branch := tree.create_item(human_branch)
	mood_parent_branch.set_text(NAME_COLUMN, "Mood")
	
	var face_texture = human_visuals.faces.get(h.mood)
	mood_parent_branch.set_icon(NAME_COLUMN, face_texture)
	
	var mood_branch := tree.create_item(mood_parent_branch)
	mood_branch.set_cell_mode(NAME_COLUMN, TreeItem.CELL_MODE_RANGE)
	mood_branch.set_range_config(NAME_COLUMN, worst_mood, best_mood, 1)
	mood_branch.set_range(NAME_COLUMN, h.mood)
	mood_branch.set_editable(NAME_COLUMN, true)
	mood_branch.set_metadata(NAME_COLUMN, func(item: TreeItem): _update_mood(item, h))
	
	var queries_parent_branch := tree.create_item(human_branch)
	queries_parent_branch.set_text(NAME_COLUMN, "Queries")
	queries_parent_branch.set_metadata(NAME_COLUMN, h.queries)
	queries_parent_branch.add_button(BUTTON_COLUMN, add_texture)
	queries_parent_branch.set_metadata(BUTTON_COLUMN, func(): _add_query(queries_parent_branch, h))
	
	for q in h.queries:
		_populate_query(queries_parent_branch, q, h.queries)
	
	_add_tags(human_branch, h)

func _add_available_tag(parent: TreeItem) -> void:
	modified = true
	var i := game_data.tags.size()
	game_data.tags.append("tag%d" % (i + 1))
	_populate_available_tag(parent, i)
	_update_tags_dropdown()

func _add_human(parent: TreeItem) -> void:
	modified = true
	var human := Human.new()
	game_data.humans.append(human)
	var i := game_data.humans.size()
	human.name = "human%d" % i
	_populate_human(parent, human)

func _add_tag(parent: TreeItem, tags: Array[String]) -> void:
	modified = true
	var i := tags.size()
	tags.append(empty_dropdown_element if add_empty_element else game_data.tags[0])
	_populate_tag(parent, i, tags, game_data.tags)

func _add_query(parent: TreeItem, h: Human) -> void:
	modified = true
	var query := Query.new()
	h.queries.append(query)
	var i := h.queries.size()
	query.text = "query%d" % i
	_populate_query(parent, query, h.queries)
	
func _add_result(parent: TreeItem) -> void:
	modified = true
	var result := Result.new()
	game_data.results.append(result)
	var i := game_data.results.size()
	result.title = "result%d" % i
	_populate_result(parent, result, game_data.results)

func _populate_result(parent: TreeItem, r: Result, array: Array[Result]) -> void:
	var result_branch := _create_editable_item_with_text(parent, r.title)
	result_branch.set_metadata(NAME_COLUMN, func(item: TreeItem): r.title = item.get_text(NAME_COLUMN))
	
	result_branch.add_button(BUTTON_COLUMN, remove_texture)
	result_branch.set_metadata(BUTTON_COLUMN, func(): _remove_item(parent, result_branch, r, array))
	
	_add_tags(result_branch, r)

func _populate_query(parent: TreeItem, q: Query, array: Array) -> TreeItem:
	var query_branch := _create_editable_item_with_text(parent, q.text)
	query_branch.set_metadata(NAME_COLUMN, func(item: TreeItem): q.text = item.get_text(NAME_COLUMN))
	
	query_branch.add_button(BUTTON_COLUMN, remove_texture)
	query_branch.set_metadata(BUTTON_COLUMN, func(): _remove_item(parent, query_branch, q, array))

	
	_add_tags(query_branch, q)
	return query_branch

func populate_tree() -> void:
	tree.clear()
	tag_holders_to_update.clear()
	var root = tree.create_item()
	root.set_metadata(NAME_COLUMN, game_data)
	
	print(JSON.stringify(game_data).c_unescape())
	tree.set_column_title(NAME_COLUMN, "Name")
	tree.set_column_expand(BUTTON_COLUMN, false)
	
	var tags_parent_branch := tree.create_item(root)
	tags_parent_branch.set_text(NAME_COLUMN, "Available Tags")
	tags_parent_branch.set_metadata(NAME_COLUMN, game_data.tags)
	tags_parent_branch.add_button(BUTTON_COLUMN, add_texture)
	tags_parent_branch.set_metadata(BUTTON_COLUMN, func(): _add_available_tag(tags_parent_branch))
	
	for i in game_data.tags.size():
		_populate_available_tag(tags_parent_branch, i)
	
	var humans_parent_branch := tree.create_item(root)
	humans_parent_branch.set_text(NAME_COLUMN, "Humans")
	humans_parent_branch.set_metadata(NAME_COLUMN, game_data.humans)
	humans_parent_branch.add_button(BUTTON_COLUMN, add_texture)
	humans_parent_branch.set_metadata(BUTTON_COLUMN, func(): _add_human(humans_parent_branch))
	
	for h in game_data.humans:
		_populate_human(humans_parent_branch, h)

	var results_parent_branch := tree.create_item(root)
	results_parent_branch.set_text(NAME_COLUMN, "Results")
	results_parent_branch.set_metadata(NAME_COLUMN, game_data.results)
	
	results_parent_branch.add_button(BUTTON_COLUMN, add_texture)
	results_parent_branch.set_metadata(BUTTON_COLUMN, func(): _add_result(results_parent_branch))
	
	for r in game_data.results:
		_populate_result(results_parent_branch, r, game_data.results)
	
	if should_collapse_tree:
		root.set_collapsed_recursive(true)
		root.collapsed = false
	
func _update_mood(item: TreeItem, human: Human) -> void:
	var mood := int(item.get_range(NAME_COLUMN))
	var new_face_texture = human_visuals.faces.get(mood)
	item.get_parent().set_icon.call_deferred(NAME_COLUMN, new_face_texture)
	human.mood = mood

func _add_tags(parent_branch: TreeItem, data_with_tags) -> void:
	_add_array_dropdowns(parent_branch, "Positive about", data_with_tags.positive_tags, game_data.tags)
	_add_array_dropdowns(parent_branch, "Negative about", data_with_tags.negative_tags, game_data.tags)

func _add_array_dropdowns(parent_branch: TreeItem, dropdowns_name: String, data: Array[String], options: Array[String]) -> void:
	var dropdowns_parent_branch := tree.create_item(parent_branch)
	dropdowns_parent_branch.set_text(NAME_COLUMN, dropdowns_name)
	dropdowns_parent_branch.set_metadata(NAME_COLUMN, data)
	dropdowns_parent_branch.add_button(BUTTON_COLUMN, add_texture)
	dropdowns_parent_branch.set_metadata(BUTTON_COLUMN, func(): _add_tag(dropdowns_parent_branch, data))
	
	for i in data.size():
		_populate_tag(dropdowns_parent_branch, i, data, options)

func _on_tree_item_edited() -> void:
	modified = true
	var item := tree.get_edited()
	var metadata = item.get_metadata(0)
	
	if metadata is Callable:
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
	DataManager.save_current_data(current_path)
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
	DataManager.save_current_data(current_path)
	modified = false

func _on_load_defaults_button_pressed() -> void:
	DataManager.load_data()
	game_data = DataManager.data
	modified = false
	populate_tree()

func _update_tags_dropdown() -> void:
	var options = game_data.tags
	for item in tag_holders_to_update:
		var all_tags := (empty_dropdown_element + "," if add_empty_element else "") + ",".join(options)
		item.set_text(0, all_tags)
		item.get_metadata(0).call(item)

func _update_available_tag(item: TreeItem, index: int, tags: Array[String]):
	tags[index] = item.get_text(0)
	item.set_metadata(NAME_COLUMN, item.get_text(0))
	_update_tags_dropdown()
		
func _update_tag(item: TreeItem, parent: TreeItem, tags: Array[String]):
	var available_tag_index: int = int(item.get_range(0)) - (1 if add_empty_element else 0)
	var index := parent.get_children().find(item)
	tags[index] = game_data.tags[available_tag_index]


func _on_tree_button_clicked(item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	var metadata = item.get_metadata(BUTTON_COLUMN)
	
	if metadata is Callable:
		metadata.call()


func _on_new_data_button_pressed() -> void:
	DataManager.data = GameData.new()
	game_data = DataManager.data
	modified = false
	populate_tree()


func _on_tree_gui_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return
	if tree.get_selected_column() != BUTTON_COLUMN:
		return
	
	var item := tree.get_selected()
	var metadata = item.get_metadata(BUTTON_COLUMN)
	if metadata is Callable:
		metadata.call()
