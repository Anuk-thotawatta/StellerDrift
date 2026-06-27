extends Control

@onready var button_sound: AudioStreamPlayer2D = $button_sound
@onready var countdown: Label = $"../countdown"
@onready var beep: AudioStreamPlayer2D = $"../../beep"
@onready var game_soundtrack: AudioStreamPlayer2D = $"../../game_soundtrack"
@onready var player: CharacterBody2D = $"../../Player"

var can_hit_esc: bool

func _ready():
	can_hit_esc = true
	$AnimationPlayer.play("RESET")
	hide()

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	can_hit_esc = false
	get_tree().paused = true
	game_soundtrack.stop()
	countdown.show()
	var x=3
	while x>=0:
		countdown.text = str(x)
		beep.play()
		await get_tree().create_timer(1.0).timeout
		x-=1
	countdown.hide()
	game_soundtrack.play()
	player.show_exhaust()
	Global.countdown_happening = false
	get_tree().paused = false
	can_hit_esc = true
	
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
	elif Input.is_action_just_pressed("pause") and get_tree().paused == true and Global.countdown_happening == false:
		resume()


func _on_resume_button_pressed() -> void:
	resume()

func _on_restart_button_pressed() -> void:
	resume()
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
	
func _process(delta):
	if can_hit_esc:
		hit_escape()

func _on_resume_button_button_down() -> void:
	button_sound.play()

func _on_resume_button_mouse_entered() -> void:
	button_sound.play()

func _on_restart_button_button_down() -> void:
	button_sound.play()

func _on_restart_button_mouse_entered() -> void:
	button_sound.play()

func _on_quit_button_button_down() -> void:
	button_sound.play()

func _on_quit_button_mouse_entered() -> void:
	button_sound.play()


func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Assets/Scenes/main_menu.tscn")


func _on_menu_button_button_down() -> void:
	button_sound.play()


func _on_menu_button_mouse_entered() -> void:
	button_sound.play()
