class_name Human
extends Resource

@export var name: String
@export var mood: int
@export var queries: Array[Query]
@export var positive_tags: Array[String]
@export var negative_tags: Array[String]
@export var past_reactions: Dictionary[Result, int]
