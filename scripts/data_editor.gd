extends Control

@export var tree: Tree
@export var game_data: GameData
@export var human_visuals: HumanVisuals
@export var worst_mood: int = -3
@export var best_mood: int = 3

const TYPE_COLUMN := 0
const NAME_COLUMN := 0
const MOOD_COLUMN := 1
#const MOOD_ICON_COLUMN := 2
#const POSITIVE_COLUMN := 3
#const NEGATIVE_COLUMN := 4

func _ready() -> void:
	var root = tree.create_item()
	#var json := JSON.new()
	#json["humans"] = []
	
	print(JSON.stringify(game_data).c_unescape())
	#tree.set_column_title(TYPE_COLUMN, "Type")
	tree.set_column_title(NAME_COLUMN, "Name")
	tree.set_column_title(MOOD_COLUMN, "Mood Value")
	#tree.set_column_title(MOOD_ICON_COLUMN, "Mood Face")
	
	var tags_parent_branch := tree.create_item(root)
	tags_parent_branch.set_text(TYPE_COLUMN, "Available Tags")
	
	for t in game_data.tags:
		_create_editable_item_with_text(tags_parent_branch, t)
	
	var humans_parent_branch := tree.create_item(root)
	humans_parent_branch.set_text(TYPE_COLUMN, "Humans")
	
	for h in game_data.humans:
		var human_branch := _create_editable_item_with_text(humans_parent_branch, h.name)
	
		#human_branch.set_cell_mode(MOOD_COLUMN, TreeItem.CELL_MODE_CUSTOM)
		human_branch.set_cell_mode(MOOD_COLUMN, TreeItem.CELL_MODE_RANGE)
		human_branch.set_range_config(MOOD_COLUMN, worst_mood, best_mood, 1)
		human_branch.set_range(MOOD_COLUMN, h.mood)
		human_branch.set_editable(MOOD_COLUMN, true)
		
		#human_branch.set_cell_mode(MOOD_ICON_COLUMN, TreeItem.CELL_MODE_ICON)
		var face_texture = human_visuals.faces.get(h.mood)
		human_branch.set_icon(NAME_COLUMN, face_texture)
		
		var queries_parent_branch := tree.create_item(human_branch)
		queries_parent_branch.set_text(TYPE_COLUMN, "Queries")
		for q in h.queries:
			var query_branch := _create_editable_item_with_text(queries_parent_branch, q.text)
			_add_tags(query_branch, q)
		
		_add_tags(human_branch, h)

	var results_parent_branch := tree.create_item(root)
	results_parent_branch.set_text(TYPE_COLUMN, "Results")
	
	for r in game_data.results:
		var result_branch := _create_editable_item_with_text(results_parent_branch, r.title)
		_add_tags(result_branch, r)
		
	root.set_collapsed_recursive(true)
	root.collapsed = false
		
func _add_tags(parent_branch: TreeItem, data_with_tags) -> void:
	_add_array_dropdowns(parent_branch, "Positive about", data_with_tags.positive_tags, game_data.tags)
	_add_array_dropdowns(parent_branch, "Negative about", data_with_tags.negative_tags, game_data.tags)

func _add_array_dropdowns(parent_branch: TreeItem, dropdowns_name: String, data: Array[String], options: Array[String], add_empty_element: bool = true) -> void:
	var dropdowns_parent_branch := tree.create_item(parent_branch)
	dropdowns_parent_branch.set_text(NAME_COLUMN, dropdowns_name)
	
	for t in data:
		var all_tags := ("---," if add_empty_element else "") + ",".join(options)
		var selected_index := game_data.tags.find(t) + (1 if add_empty_element else 0)
		_create_editable_dropdown_item(dropdowns_parent_branch, all_tags, selected_index)

func _on_tree_item_edited() -> void:
	var item := tree.get_edited()
	var column := tree.get_edited_column()
	
	if column == MOOD_COLUMN:
		var mood := int(item.get_range(MOOD_COLUMN))
		var face_texture = human_visuals.faces.get(mood)
		item.set_icon.call_deferred(NAME_COLUMN, face_texture)
		
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
