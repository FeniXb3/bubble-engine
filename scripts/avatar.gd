class_name Avatar
extends Control

@export var face: TextureRect
@export var head: TextureRect
@export var name_label: Label
@export var animation_player: AnimationPlayer
@export var timer: Timer

@export var human_visuals: HumanVisuals

signal face_updated(texture: Texture)

func _ready() -> void:
	SignalBus.human_picked.connect(show_head)
	SignalBus.mood_calculated.connect(update_face)
	SignalBus.reaction_calculated.connect(update_face)
	SignalBus.reseting.connect(func(): animation_player.play("hide"))
	
	modulate.a = 0
	TutorialManager.register_step("human_approached", "Someone visited Bubble Engine. We hacked into their cameras to register their mood.", self)

func show_head(human: Human, index: int) -> void:
	if modulate.a > 0:
		animation_player.play("hide")
		timer.start()
		await timer.timeout
	var head_shape := human_visuals.heads[index]
	head.texture = head_shape
	update_face(human.mood)
	name_label.text = human.name
	animation_player.play("show")
	
func update_face(mood: int) -> void:
	var t = human_visuals.faces.get(mood)
	face.texture = t
	face_updated.emit(t)
