extends Control

func _ready():
	$AnimationPlayer.play("RESET")
	hide()

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func pause():
	get_tree().paused = true
	$AnimationPlayer.play("blur")
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hit_escape():
	var game = get_tree().get_root().get_node("Game")
	if game.game_over.visible:
		return

	if Input.is_action_just_pressed("pause") and get_tree().paused == false:
		pause()
	elif Input.is_action_just_pressed("pause") and get_tree().paused == true:
		resume()


func _on_resume_button_pressed() -> void:
	resume()

func _on_restart_button_pressed() -> void:
	resume()
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
	
func _process(delta):
	hit_escape()
