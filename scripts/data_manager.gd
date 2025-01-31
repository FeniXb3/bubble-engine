class_name DataManager

static var saved_path := "user://custom_data.tres"
static var default_path := "res://sample_data.tres"
static var data : GameData
static var sample_data: GameData

static func save_data(data_to_save: GameData, path: String = "user://custom_data.tres") -> GameData:
	data = data_to_save
	save_current_data(path)
	
	return data

static func save_current_data(path: String = "user://custom_data.tres") -> void:
	ResourceSaver.save(data, path)

static func load_data(path: String = "user://custom_data.tres") -> void:
	
	if FileAccess.file_exists(path):
		data = GameData.load(path)
	else:
		if sample_data:
			data = sample_data.duplicate()
		else:
			data = GameData.new()

static func save_default_data() -> void:
	ResourceSaver.save(data, default_path)
	
static func set_sample_data(data_to_set: GameData):
	sample_data = data_to_set
