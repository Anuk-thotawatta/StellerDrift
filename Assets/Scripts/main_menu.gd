extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_quit_pressed() -> void:
	print("quit pressed")
	get_tree().quit()

func _on_start_pressed() -> void:
	print("start pressed")
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().change_scene_to_file("res://Assets/Scenes/Game.tscn")
