class_name Human
extends Resource

@export var name: String
@export var mood: int
@export var queries: Array[Query]
@export var positive_tags: Array[String]
@export var negative_tags: Array[String]
@export var past_reactions: Dictionary[Result, int]
@export var past_queries: Dictionary[Query, int]

func _to_string() -> String:
	return "{
		\"name\": \"{name}\", 
		\"mood\": {mood}, 
		\"queries\": {queries},
		\"positive_tags\": {positive_tags},
		\"negative_tags\": {negative_tags},
		\"past_reactions\": {past_reactions}
	}". format({"name": name, 
		"mood": mood, 
		"queries": queries, 
		"positive_tags": positive_tags,
		"negative_tags": negative_tags,
		"past_reactions": past_reactions})
