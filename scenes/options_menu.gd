extends Control

@export_group("Data")
@export var available_themes: Dictionary[String, Theme]
@export var click_stream: AudioStream
@export var click_noise_stream: AudioStream
@export var skip_tutorials: bool = false:
	set(value):
		skip_tutorials = value
		if TutorialManager.skip_all_tutorials == skip_tutorials:
			return
			
		TutorialManager.skip_all_tutorials = skip_tutorials

@export_group("Controls")
@export var computer_noise_check_box: CheckBox
@export var skip_tutorials_checkbox: CheckBox
@export var theme_option_button: OptionButton

func _ready() -> void:
	for theme_name in available_themes:
		var new_item_index := theme_option_button.item_count
		theme_option_button.add_item(theme_name)
		theme_option_button.set_item_metadata(new_item_index, available_themes[theme_name])
	
	if not OS.has_feature("debug"):
		skip_tutorials = false
	skip_tutorials_checkbox.set_pressed_no_signal(skip_tutorials)
	computer_noise_check_box.set_pressed_no_signal(BackgroundSfxPlayer.stream == click_noise_stream)
	

func _on_skip_tutorial_check_box_toggled(toggled_on: bool) -> void:
	skip_tutorials = toggled_on

func _on_computer_noise_check_box_toggled(toggled_on: bool) -> void:
	BackgroundSfxPlayer.stream = click_noise_stream if toggled_on else click_stream


func _on_theme_option_button_item_selected(index: int) -> void:
	var selected_theme: Theme = theme_option_button.get_item_metadata(index)
	get_tree().root.theme = selected_theme
