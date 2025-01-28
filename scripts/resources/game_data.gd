class_name GameData
extends Resource

@export var tags: Array[String]
@export var humans: Array[Human]
@export var results: Array[Result]

func _to_string() -> String:
	return "{\"tags\": {tags}, \"humans\": {humans}}".format({"tags": tags, "humans": humans})

static func load(path: String) -> GameData:
	var data := ResourceLoader.load(path, "GameData", ResourceLoader.CACHE_MODE_IGNORE) as GameData

	return data
