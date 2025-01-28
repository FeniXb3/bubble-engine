class_name Query
extends Resource

@export var text: String
@export var positive_tags: Array[String]
@export var negative_tags: Array[String]

func _to_string() -> String:
	return "{
		\"text\": \"{text}\",
		\"positive_tags\": {positive_tags},
		\"negative_tags\": {negative_tags}
	}". format({"text": text, 
		"positive_tags": positive_tags,
		"negative_tags": negative_tags})
