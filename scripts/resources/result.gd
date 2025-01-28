class_name Result
extends Resource

@export var title: String
@export var description: String
@export var positive_tags: Array[String]
@export var negative_tags: Array[String]

func _to_string() -> String:
	return "{
		\"title\": \"{title}\", 
		\"description\": \"{description}\", 
		\"positive_tags\": {positive_tags},
		\"negative_tags\": {negative_tags},
		\"past_reactions\": {past_reactions}
	}". format({"title": title,
		"description": description, 
		"positive_tags": positive_tags,
		"negative_tags": negative_tags})
