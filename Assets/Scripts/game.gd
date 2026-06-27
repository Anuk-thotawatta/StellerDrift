extends Node2D

@onready var game_over = $CanvasLayer/Game_over
@onready var asteroid_pilar = preload("res://Assets/Objects/Asteroid_pillars.tscn")
@onready var score: Label = $CanvasLayer/score
@onready var hscore: Label = $CanvasLayer/hscore
@onready var extra_lives: Label = $CanvasLayer/extraLives
@onready var countdown: Label = $CanvasLayer/countdown
@onready var player: CharacterBody2D = $Player
@onready var background1: Sprite2D = $background1
@onready var explosion_fx: ColorRect = $Explosion_fx
@onready var star_field: ColorRect = $StarField
@onready var game_soundtrack: AudioStreamPlayer2D = $game_soundtrack
@onready var beep: AudioStreamPlayer2D = $beep
@onready var popup: Control = $CanvasLayer/Popup
@onready var popup_anim: AnimationPlayer = $CanvasLayer/Popup/AnimationPlayer
@onready var popup_text: Label = $CanvasLayer/Popup/Text
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sentinal: Node2D = $Sentinal
@onready var sentinal_music: AudioStreamPlayer2D = $sentinal_music

var background2: Sprite2D
var bg_width

var distance_since_last_pillar_spawn = 0.0
var pillar_gap_distance = 750.0

#phase timer variables
var game_started: bool = false
var phase_timer: float = 0.0
var phase_duration: float = 5.0

#score variables
var scoreVal = 0.0
var highScoreVal = 0.0
const BG_SCROLL_SPEED = 100.0
var star_time: float = 0.0

# Boss state
var boss_spawned: bool = false

func _ready():
	game_started = false
	Global.pillarCount = 0
	Global.current_phase_index = 0
	Global.is_boss_active = false
	Global.waiting_for_pillars = false
	
	score.text = str(int(scoreVal))
	extra_lives.text = str(player.extra_life_count)
	popup.hide()
	countdown.show()
	Global.game_state = Global.phase_queue[Global.current_phase_index]
	Global.countdown_happening = true
	player.hide_exhaust()
	explosion_fx.hide()
	player.show()
	highScoreVal = loadHighScore()
	hscore.text = str(highScoreVal)
	scoreVal = 0.0
	get_tree().paused = false
	game_over.hide()
	
	if star_field:
		star_field.process_mode = Node.PROCESS_MODE_ALWAYS
	
	#scrolling background
	bg_width = background1.texture.get_width() * background1.scale.x
	background1.position.x = 0
	background2 = background1.duplicate()
	add_child(background2)
	background2.position = Vector2(bg_width, background1.position.y)
	
	get_tree().paused = true
	var x=3
	while x>=0:
		if x==2:
			popup.show()
			popup_text.text = "Tap [SPACE] to Boost"
			popup_anim.play("pop_up")
		countdown.text = str(x)
		beep.play()
		await get_tree().create_timer(1.0).timeout
		x-=1
		
	game_started = true
	spawn_pillar()
	countdown.hide()
	game_soundtrack.play()
	player.show_exhaust()
	Global.countdown_happening = false
	get_tree().paused = false
	
	await popup_anim.animation_finished
	popup.hide()
	
	Global.phase_changed.connect(_on_phase_changed)
	sentinal.boss_defeated.connect(_on_boss_defeated)  # Add this line
	
func _process(delta):	
	if (get_tree().paused == false):
		handle_background(delta)
		distance_since_last_pillar_spawn += Global.gameSpeed * delta
		if Global.game_state == Global.state.ASTEROID and not Global.waiting_for_pillars:
			if distance_since_last_pillar_spawn >= pillar_gap_distance:
				distance_since_last_pillar_spawn = 0.0
				spawn_pillar()
		
	scoreVal += delta * 100
	score.text = str(int(scoreVal))
	hscore.text = str(int(highScoreVal))
	extra_lives.text = str(player.extra_life_count)

	# Handle boss behavior FIRST - this spawns the boss
	handle_boss_behavior(delta)
	
	# Handle phase transitions SECOND - this checks if boss is dead
	handle_phase_transitions(delta)
	
func handle_phase_transitions(delta):
	if not game_started:
		return
	match Global.game_state:
		Global.state.ASTEROID:
			phase_timer += delta
			if phase_timer >= phase_duration:
				phase_timer = 0.0
				transition_to_next_phase()
		Global.state.BOSS:
			# ONLY transition if the boss was successfully spawned AND is now dead
			if boss_spawned and not Global.is_boss_active:
				transition_to_next_phase()

func transition_to_next_phase():
	Global.current_phase_index = (Global.current_phase_index + 1) % Global.phase_queue.size()
	var new_state = Global.phase_queue[Global.current_phase_index]
	
	if new_state != Global.game_state:
		Global.game_state = new_state
		Global.phase_changed.emit(new_state)

func _on_boss_defeated():
	Global.is_boss_active = false
	if animation_player.has_animation("sentinal_appear"):
		sentinal.deactivate_boss()
		game_soundtrack.play()
		animation_player.play_backwards("sentinal_appear")
		sentinal_music.stop()
		

func handle_boss_behavior(delta):
	if not game_started:
		return
	
	# Spawn boss when pillars are cleared
	if Global.game_state == Global.state.BOSS and not boss_spawned and Global.pillarCount <= 0:
		boss_spawned = true
		Global.is_boss_active = true
		
		# Play boss appearance animation
		if animation_player.has_animation("sentinal_appear"):
			animation_player.play("sentinal_appear")
			sentinal_music.play()
			game_soundtrack.stop()
			if sentinal.has_method("activate_boss"):
				await animation_player.animation_finished
				sentinal.activate_boss()
		
		# Start boss idle animation
		if animation_player.has_animation("sentinal_idle"):
			animation_player.play("sentinal_idle")
		
		print("BOSS SPAWNED - Kill it to end phase")
	
func spawn_pillar():
	var pillar = asteroid_pilar.instantiate()
	pillar.position = Vector2(1700, randi_range(-500, 500))
	add_child(pillar)
	Global.pillarCount += 1

func handle_background(delta):
	# --- Scroll both backgrounds ---
	background1.position.x -= BG_SCROLL_SPEED * delta
	background2.position.x -= BG_SCROLL_SPEED * delta

	# --- Accumulate clean delta time and update the shader ---
	star_time += delta
	if star_field and star_field.material:
		star_field.material.set_shader_parameter("manual_time", star_time)

	# When a background fully exits left, wrap it to the right of the other
	if background1.position.x <= -bg_width:
		background1.position.x = background2.position.x + bg_width
	if background2.position.x <= -bg_width:
		background2.position.x = background1.position.x + bg_width
	# --------------------------------

func player_died():
	get_tree().paused = true
	player.play_explosion_audio()
	explosion_fx.global_position = player.global_position - explosion_fx.size / 2.0
	explosion_fx.process_mode = Node.PROCESS_MODE_ALWAYS
	explosion_fx.material.set_shader_parameter("progress", 0.0)
	explosion_fx.show()
	player.hide()
	var tween = explosion_fx.create_tween()
	tween.tween_property(explosion_fx.material, "shader_parameter/progress", 1.0, 0.6)
	await tween.finished
	explosion_fx.hide()
	saveHighScore(scoreVal)
	game_over.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func saveHighScore(new_score: int):
	var current = loadHighScore()
	if new_score <= current:
		return
	var data = {"highscore": new_score}
	var file = FileAccess.open(Global.SAVEPATH, FileAccess.WRITE)
	if file == null:
		print("Save error: ", FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data))
	file.close()

func loadHighScore() -> int:
	if not FileAccess.file_exists(Global.SAVEPATH):
		return 0 
	var file = FileAccess.open(Global.SAVEPATH, FileAccess.READ)
	if file == null:
		return 0
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null or not data.has("highscore"):
		return 0
	return int(data["highscore"])

func _on_floor_sky_limits_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		get_tree().get_root().get_node("Game").player_died()
	
func _on_phase_changed(new_state):
	match new_state:
		Global.state.ASTEROID:
			print("ASTEROID PHASE STARTED")
			phase_timer = 0.0  
			Global.waiting_for_pillars = false
			boss_spawned = false       # Ready for next cycle
			Global.is_boss_active = false # Ready for next cycle
			distance_since_last_pillar_spawn = pillar_gap_distance - 200
					
		Global.state.BOSS:
			print("BOSS PHASE TRIGGERED - Waiting for pillars to clear...")
