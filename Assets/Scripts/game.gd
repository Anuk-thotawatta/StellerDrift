extends Node2D

@onready var game_over = $CanvasLayer/Game_over
@onready var asteroid_pilar = preload("res://Assets/Objects/Asteroid_pillars.tscn")
@onready var pillar_spawn_timer: Timer = $pillarSpawnTimer
@onready var score: Label = $CanvasLayer/score
@onready var hscore: Label = $CanvasLayer/hscore
@onready var countdown: Label = $initial_pillars/Asteroid_pillars/countdown
@onready var player: CharacterBody2D = $Player
@onready var background1: Sprite2D = $background1
@onready var explosion_fx: ColorRect = $Explosion_fx
@onready var star_field: ColorRect = $StarField

var background2: Sprite2D
var bg_width

const SAVEPATH = "user://save.json"

var scoreVal = 0
var highScoreVal = 0
const BG_SCROLL_SPEED = 100.0
var star_time: float = 0.0

func _ready():
	player.hide_exhaust()
	explosion_fx.hide()
	player.show()
	highScoreVal = loadHighScore()
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
		countdown.text = str(x)
		await get_tree().create_timer(1.0).timeout
		x-=1
	countdown.hide()
	player.show_exhaust()
	get_tree().paused = false
	
func _process(delta):
	# If the tree is paused (during the 3-second countdown), update twinkles without shifting position
	if get_tree().paused:
		if star_field and star_field.material:
			star_field.material.set_shader_parameter("manual_time", star_time)
		return

	scoreVal += delta * 100
	score.text = str(int(scoreVal))
	hscore.text = str(int(highScoreVal))
	
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
	var file = FileAccess.open(SAVEPATH, FileAccess.WRITE)
	if file == null:
		print("Save error: ", FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data))
	file.close()

func loadHighScore() -> int:
	if not FileAccess.file_exists(SAVEPATH):
		return 0 
	var file = FileAccess.open(SAVEPATH, FileAccess.READ)
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


func _on_pillar_spawn_timer_timeout() -> void:
	var pillar = asteroid_pilar.instantiate()
	pillar.position = Vector2(1500, randi_range(-500, 500))
	add_child(pillar)
