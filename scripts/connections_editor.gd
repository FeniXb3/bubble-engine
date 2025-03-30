extends Control

@export var graph: GraphEdit
@export var human_node_scene: PackedScene
@export var tag_node_scene: PackedScene
@export var query_node_scene: PackedScene
@export var data: GameData
@export var initial_nodes_margin: float = 20
@export var columns_separation: float =  400
@export var zoom_margin := 0.9
@export var tags_nodes: Dictionary[String, GraphNode]
@export var humans_nodes: Dictionary[Human, GraphNode]
@export var queries_nodes: Dictionary[Query, GraphNode]
@export var timer: Timer
@export var animation_duration: float = 0.25

var encountered_tags: Array[String] = []
var encountered_humans: Array[Human] = []
var encountered_queries: Array[Query] = []
var encountered_results: Array[Result] = []
var visible_nodes_extents := Rect2()
var top_left := Vector2(1234, 1234)
var bottom_right := Vector2()
var operations_queue: Array[Callable] = []
var nodes_to_show: Array[GraphNode] = []
var selected_node: GraphNode
var automation: Dictionary = {}

const POSITIVE_PORT = 1
const NEGATIVE_PORT = 2

const HUMANS_COLUMN = 0
const QUERIES_COLUMN = 1
const TAGS_COLUMN  = 2
const RESULTS_COLUMN = 3

func _ready() -> void:
	add_nodes()
	SignalBus.tag_encountered.connect(_show_tag)
	SignalBus.human_encountered.connect(_show_human)
	SignalBus.human_picked.connect(_show_human)
	SignalBus.query_picked.connect(_show_query)
	SignalBus.results_known.connect(_show_submitted_results)

func _show_submitted_results(results: Array[Result]) -> void:
	for result in results:
		_show_result(result)

func _show_node(node: GraphNode) -> Tween:
	_update_graph_offset(node)
	node.show()
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, animation_duration).from(0.0)
	return tween

func _show_tag(tag: String):
	if encountered_tags.has(tag):
		return
	var node := tags_nodes[tag]
	node.position_offset.y = (node.size.y + initial_nodes_margin) * encountered_tags.size()
	encountered_tags.append(tag)
	operations_queue.append(_include_in_graph_update.bind(node))
	
func _show_human(human: Human, _index: int = -1):
	if encountered_humans.has(human):
		return
	
	var node := humans_nodes[human]
	node.position_offset.y = (node.size.y + initial_nodes_margin) * encountered_humans.size()
	encountered_humans.append(human)
	
	operations_queue.append(_include_in_graph_update.bind(node))
	
func _include_in_graph_update(node: GraphNode) -> void:
	_update_graph_offset(node)
	nodes_to_show.append(node)
	
func _update_graph_offset(node: GraphNode = null):
	if node != null:
		top_left.x = min(top_left.x, node.position_offset.x)
		top_left.y = min(top_left.y, node.position_offset.y)
		bottom_right.x = max(bottom_right.x, node.position_offset.x + node.size.x)
		bottom_right.y = max(bottom_right.y, node.position_offset.y + node.size.y)

func _update_visible_rect() -> Tween:
	var graph_size := graph.size
	var zoom_vector := graph_size / (bottom_right - top_left)
	var zoom_value := minf(zoom_vector[zoom_vector.min_axis_index()] * zoom_margin, 1)
	var nodes_center := (bottom_right - top_left) / 2
	var graph_center := graph.size / 2
	var new_scroll_offset := top_left + nodes_center - graph_center
	
	# To make it easier, reset zoom to 100% before setting scroll offset.
	# The engine will take care to zoom out around current center of graph.
	var last_offset := graph.scroll_offset
	var last_zoom := graph.zoom
	graph.zoom = 1
	graph.scroll_offset = new_scroll_offset
	graph.zoom = zoom_value
	var zoomed_scroll_offset := graph.scroll_offset
	
	var tween := create_tween().set_parallel()
	tween.tween_property(graph, "zoom", zoom_value, animation_duration).from(last_zoom)
	tween.tween_property(graph, "scroll_offset", zoomed_scroll_offset, animation_duration).from(last_offset)
	
	return tween
	
func _show_query(query: Query):
	if encountered_queries.has(query):
		return
	
	encountered_queries.append(query)
	var node := queries_nodes[query]
	node.position_offset.y = (node.size.y + initial_nodes_margin) * encountered_queries.size()
	operations_queue.append(_include_in_graph_update.bind(node))
	
	for tag in query.positive_tags:
		_show_tag(tag)
		
	
func _show_result(result: Result):
	if encountered_results.has(result):
		return
	
	encountered_results.append(result)
	for tag in result.positive_tags:
		_show_tag(tag)
	for tag in result.negative_tags:
		_show_tag(tag)
	#results_nodes[result].show()

func add_graph_node(node_scene: PackedScene, node_data, nodes_dictionary: Dictionary, index: int, column: int, text_getter: Callable) -> DataGraphNode:
	var node := node_scene.instantiate() as DataGraphNode
	node.setup(index, text_getter.call(), column * columns_separation, initial_nodes_margin, node_data)
	graph.add_child(node, true)
	nodes_dictionary.set(node_data, node)

	return node

func add_nodes() -> void:
	for i in data.tags.size():
		var tag := data.tags[i]
		add_graph_node(tag_node_scene, tag, tags_nodes, i, TAGS_COLUMN, func(): return tag)
		
	for i in data.humans.size():
		var human := data.humans[i]
		add_graph_node(human_node_scene, human, humans_nodes, i, HUMANS_COLUMN, func(): return human.name)
		
		for j in human.queries.size():
			var query := human.queries[j]
			add_graph_node(query_node_scene, query, queries_nodes, j, QUERIES_COLUMN, func(): return query.text)


func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph.connect_node(from_node, from_port, to_node, to_port)
	var from_data = graph.get_node(NodePath(from_node)).get_meta("data")
	var to_data = graph.get_node(NodePath(to_node)).get_meta("data")
	
	if from_data is Human and to_data is String:
		var  tags = automation.get_or_add(from_data, {"positive": [], "negative": []})
		match from_port:
			POSITIVE_PORT:
				tags["positive"].append(to_data)
			NEGATIVE_PORT:
				tags["negative"].append(to_data)
	


func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph.disconnect_node(from_node, from_port, to_node, to_port)
	var from_data = graph.get_node(NodePath(from_node)).get_meta("data")
	var to_data = graph.get_node(NodePath(to_node)).get_meta("data")
	
	if from_data is Human and to_data is String:
		var  tags = automation.get_or_add(from_data, {"positive": [], "negative": []})
		match from_port:
			POSITIVE_PORT:
				tags["positive"].erase(to_data)
			NEGATIVE_PORT:
				tags["negative"].erase(to_data)


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	while not operations_queue.is_empty():
		operations_queue.pop_front().call()
	
	await _update_visible_rect().finished
	
	while not nodes_to_show.is_empty():
		var node := nodes_to_show.pop_front() as GraphNode
		await _show_node(node).finished


func _on_graph_edit_end_node_move() -> void:
	_update_graph_offset(selected_node)


func _on_graph_edit_node_selected(node: Node) -> void:
	if node is GraphNode:
		selected_node = node
