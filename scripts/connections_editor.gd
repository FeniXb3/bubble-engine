extends Control

@export var graph: GraphEdit
@export var human_node_scene: PackedScene
@export var tag_node_scene: PackedScene
@export var data: GameData
@export var initial_nodes_margin: float = 20
@export var tags_nodes: Dictionary[String, GraphNode]
@export var humans_nodes: Dictionary[Human, GraphNode]
@export var add_real_connections: bool = false
var encountered_tags: Array[String] = []
var encountered_humans: Array[Human] = []
var encountered_queries: Array[Query] = []
var encountered_results: Array[Result] = []


const POSITIVE_PORT = 0
const NEGATIVE_PORT = 1

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

func _show_tag(tag: String):
	if encountered_tags.has(tag):
		return
	tags_nodes[tag].position_offset.y = tags_nodes[tag].size.y * encountered_tags.size()
	encountered_tags.append(tag)
	
	tags_nodes[tag].show()
	
func _show_human(human: Human, _index: int = -1):
	if encountered_humans.has(human):
		return
	
	humans_nodes[human].position_offset.y = humans_nodes[human].size.y * encountered_humans.size()
	
	encountered_humans.append(human)
	humans_nodes[human].show()
	
func _show_query(query: Query):
	if encountered_queries.has(query):
		return
	
	encountered_queries.append(query)
	for tag in query.positive_tags:
		_show_tag(tag)
	#queries_nodes[query].show()
	
func _show_result(result: Result):
	if encountered_results.has(result):
		return
	
	encountered_results.append(result)
	for tag in result.positive_tags:
		_show_tag(tag)
	for tag in result.negative_tags:
		_show_tag(tag)
	#results_nodes[result].show()

func add_nodes() -> void:
	for i in data.tags.size():
		var tag := data.tags[i]
		var node := tag_node_scene.instantiate() as GraphNode
		node.title = tag
		node.position_offset = Vector2(400, (node.size.y + initial_nodes_margin) * i)
		node.set_meta("tag", tag)
		graph.add_child(node)
		tags_nodes.set(tag, node)
		node.hide()
		
	for i in data.humans.size():
		var human := data.humans[i]
		var node := human_node_scene.instantiate() as GraphNode
		node.title = human.name
		node.position_offset = Vector2(0, (node.size.y + initial_nodes_margin) * i)
		node.set_meta("human", human)
		graph.add_child(node)
		humans_nodes.set(human, node)
		node.hide()
		
		if add_real_connections:
			for positive_tag in human.positive_tags:
				var tag_node := tags_nodes[positive_tag]
				graph.connect_node(node.name, POSITIVE_PORT, tag_node.name, POSITIVE_PORT)


func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph.connect_node(from_node, from_port, to_node, to_port)


func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph.disconnect_node(from_node, from_port, to_node, to_port)
