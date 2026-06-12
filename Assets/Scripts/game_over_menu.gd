extends Control

@onready var button_sound: AudioStreamPlayer2D = $button_sound

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_restart_button_button_down() -> void:
	button_sound.play()

func _on_restart_button_mouse_entered() -> void:
	button_sound.play()

func _on_quit_button_button_down() -> void:
	button_sound.play()

func _on_quit_button_mouse_entered() -> void:
	button_sound.play()

func _on_menu_button_mouse_entered() -> void:
	button_sound.play()

func _on_menu_button_button_down() -> void:
	button_sound.play()

func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Assets/Scenes/main_menu.tscn")
