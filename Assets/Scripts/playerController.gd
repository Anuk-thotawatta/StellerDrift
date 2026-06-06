extends CharacterBody2D

const gravity = 1600
var jump_force = 700 

const tilt_up = -05.00
const tilt_down = 65.00
const tilt_speed = 8.0

@onready var explosion: AudioStreamPlayer2D = $explosion
@onready var woosh: AudioStreamPlayer2D = $woosh
@onready var exhaust_fx: ColorRect = $Exhaust_fx
@onready var jump_jet_fx: ColorRect = $JumpJet_fx

func show_exhaust():
	exhaust_fx.show()

func hide_exhaust():
	exhaust_fx.hide()
	
func play_explosion_audio():
	explosion.play()
	
func play_burst():
	jump_jet_fx.material.set_shader_parameter("burst_progress", 0.5)
	var tween = jump_jet_fx.create_tween()
	tween.tween_property(jump_jet_fx.material, "shader_parameter/burst_progress", 1.0, 0.4)

func _ready() -> void:
	velocity = Vector2.ZERO
	jump_jet_fx.material.set_shader_parameter("burst_progress", 1.0)

var can_jump = true

func _physics_process(delta):
	if Input.is_action_just_pressed("jump") and can_jump:
		woosh.play()
		play_burst()
		velocity.y = -jump_force
		rotation = 0
		can_jump = false
		await get_tree().create_timer(0.4).timeout
		can_jump = true

	var target_angle = lerp(tilt_up, tilt_down, (velocity.y + jump_force) / (gravity + jump_force))
	rotation_degrees = lerp(rotation_degrees, target_angle, tilt_speed * delta)

	velocity.y += gravity * delta
	move_and_slide()
