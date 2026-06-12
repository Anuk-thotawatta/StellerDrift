extends Control

@onready var game_soundtrack: AudioStreamPlayer2D = $game_soundtrack
@onready var button_sound: AudioStreamPlayer2D = $button_sound
@onready var options_menu: Control = $Options_menu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	options_menu.hide()
	game_soundtrack.play()

func _on_quit_pressed() -> void:
	print("quit pressed")
	get_tree().quit()

func _on_start_pressed() -> void:
	print("start pressed")
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().change_scene_to_file("res://Assets/Scenes/Game.tscn")

func _on_start_button_mouse_entered() -> void:
	button_sound.play()

func _on_start_button_button_down() -> void:
	button_sound.play()

func _on_quit_button_mouse_entered() -> void:
	button_sound.play()

func _on_quit_button_button_down() -> void:
	button_sound.play()

func _on_options_button_button_down() -> void:
	button_sound.play()

func _on_options_button_mouse_entered() -> void:
	button_sound.play()

func _on_options_button_pressed() -> void:
	options_menu.show()
