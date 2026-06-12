extends Control

@onready var game_soundtrack: AudioStreamPlayer2D = $game_soundtrack
@onready var button_sound: AudioStreamPlayer2D = $button_sound

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()

func _on_back_button_pressed() -> void:
	hide()

func _on_back_button_button_down() -> void:
	button_sound.play()

func _on_back_button_mouse_entered() -> void:
	button_sound.play()
