class_name DataManager

static var saved_path := "user://custom_data.tres"
static var default_path := "res://resources/sample_data.tres"
static var data : GameData

static func save_data(path: String = "user://custom_data.tres") -> void:
	ResourceSaver.save(data, path)

static func reset_input_scheme() -> void:
	if FileAccess.file_exists(saved_path):
		DirAccess.remove_absolute(saved_path)

	load_data()


static func load_data(path: String = "user://custom_data.tres") -> void:
	
	if FileAccess.file_exists(path):
		data = GameData.load(path)
	else:
		if not FileAccess.file_exists(default_path):
			save_default_data()
		data = GameData.load(default_path)

static func save_default_data() -> void:
	ResourceSaver.save(data, default_path)
