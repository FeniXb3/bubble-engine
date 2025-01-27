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
	
	var positive_tags_parent_branch := tree.create_item(parent_branch)
	positive_tags_parent_branch.set_text(NAME_COLUMN, "Positive about")

	for t in data_with_tags.positive_tags:
		_create_editable_item_with_text(positive_tags_parent_branch, t)
	
	var negative_tags_parent_branch := tree.create_item(parent_branch)
	negative_tags_parent_branch.set_text(NAME_COLUMN, "Negative about")
	for t in data_with_tags.negative_tags:
		_create_editable_item_with_text(negative_tags_parent_branch, t)

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
