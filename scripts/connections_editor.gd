extends Control

@export var graph: GraphEdit
@export var human_node_scene: PackedScene
@export var tag_node_scene: PackedScene
@export var data: GameData
@export var initial_nodes_margin: float = 20
@export var tags_nodes: Dictionary[String, GraphNode]
@export var humans_nodes: Dictionary[Human, GraphNode]


const POSITIVE_PORT = 0
const NEGATIVE_PORT = 1

func _ready() -> void:
	for i in data.tags.size():
		var tag := data.tags[i]
		var node := tag_node_scene.instantiate() as GraphNode
		node.title = tag
		node.position_offset = Vector2(400, (node.size.y + initial_nodes_margin) * i)
		node.set_meta("tag", tag)
		graph.add_child(node)
		tags_nodes.set(tag, node)
		
	for i in data.humans.size():
		var human := data.humans[i]
		var node := human_node_scene.instantiate() as GraphNode
		node.title = human.name
		node.position_offset = Vector2(0, (node.size.y + initial_nodes_margin) * i)
		node.set_meta("human", human)
		graph.add_child(node)
		humans_nodes.set(human, node)
		#for positive_tag in human.positive_tags:
			#var tag_node := tags_nodes[positive_tag]
			#graph.connect_node(node.name, POSITIVE_PORT, tag_node.name, POSITIVE_PORT)


func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph.connect_node(from_node, from_port, to_node, to_port)


func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	graph.disconnect_node(from_node, from_port, to_node, to_port)
