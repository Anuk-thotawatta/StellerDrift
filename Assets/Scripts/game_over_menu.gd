extends Control

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
