extends CharacterBody2D

const gravity = 1600.0
var is_falling = true
var jump_force = 700.0 
var horizontalSpeed = 200
var is_dashing = false

var can_jump = true
var can_shoot = true

const tilt_up = -5.00
const tilt_down = 65.00
const tilt_speed = 8.0

var extra_life_count = 0

@onready var muzzle: Marker2D = $Muzzle
@onready var bullet = preload("res://Assets/Objects/bullet.tscn")
@onready var explosion: AudioStreamPlayer2D = $explosion
@onready var woosh: AudioStreamPlayer2D = $woosh
@onready var shoot_sound: AudioStreamPlayer2D = $shoot_sound
@onready var exhaust_fx: ColorRect = $Exhaust_fx
@onready var jump_jet_fx: ColorRect = $JumpJet_fx
@onready var force_field_fx: ColorRect = $ForceField_fx

func show_exhaust():
	exhaust_fx.show()

func hide_exhaust():
	exhaust_fx.hide()

func get_extra_life():
	force_field_fx.show()

func lose_extra_life():
	force_field_fx.hide()
	
func play_explosion_audio():
	explosion.play()
	
func play_burst():
	jump_jet_fx.material.set_shader_parameter("burst_progress", 0.5)
	var tween = jump_jet_fx.create_tween()
	tween.tween_property(jump_jet_fx.material, "shader_parameter/burst_progress", 1.0, 0.4)

func _ready() -> void:
	lose_extra_life()
	velocity = Vector2.ZERO
	jump_jet_fx.material.set_shader_parameter("burst_progress", 1.0)

func _physics_process(delta):
	if Global.game_state == Global.state.BOSS:
		if position.x > -500 and Global.pillarCount <= 0:
			velocity.x = -horizontalSpeed
		else:
			velocity.x = 0
	elif Global.game_state != Global.state.BOSS:
		if position.x < 0:
			velocity.x = horizontalSpeed
		else:
			velocity.x = 0
		
	if Input.is_action_just_pressed("jump") and can_jump:
		jump()
		
	#if Input.is_action_just_pressed("dash") and !is_dashing:
	#	dash()
		
	if Input.is_action_just_pressed("shoot") and can_shoot:
		shoot()

	var target_angle = lerp(tilt_up, tilt_down, (velocity.y + jump_force) / (gravity + jump_force))
	rotation_degrees = lerp(rotation_degrees, target_angle, tilt_speed * delta)
	force_field_fx.rotation = -rotation

	if is_falling:
		velocity.y += gravity * delta
	move_and_slide()
	
func jump():
	woosh.play()
	play_burst()
	velocity.y = -jump_force
	rotation = 0
	can_jump = false
	await get_tree().create_timer(0.2).timeout
	can_jump = true
	
func shoot():
	var projectile = bullet.instantiate()
	projectile.global_position = muzzle.global_position
	get_parent().add_child(projectile)
	shoot_sound.play()
	can_shoot = false
	await get_tree().create_timer(0.4).timeout
	can_shoot = true
	
func dash():
	is_falling = false
	is_dashing = true
	velocity.y = 0
	
	var start_x = position.x
	
	# Phase 1: move with the pillars (net zero movement) for 0.6s
	var elapsed = 0.0
	while elapsed < 0.6:
		var delta = get_process_delta_time()
		elapsed += delta
		position.x -= Global.gameSpeed * delta  # drift back with the world
		velocity.y = 0
		await get_tree().process_frame
	
	var dash_back_x = position.x
	
	# Phase 2: rocket forward past start_x (0.2s)
	var overshoot_x = start_x + Global.gameSpeed  # how far past start to overshoot
	elapsed = 0.0
	while elapsed < 0.2:
		var delta = get_process_delta_time()
		elapsed += delta
		var t = elapsed / 0.2
		var eased = 1.0 - pow(1.0 - t, 3)
		position.x = lerp(dash_back_x, overshoot_x, eased)
		velocity.y = 0
		await get_tree().process_frame
	
	# Phase 3: glide back to start_x with pillar drift (until we reach start)
	while position.x > start_x:
		var delta = get_process_delta_time()
		position.x -= Global.gameSpeed * delta  # drift with the world again
		#velocity.y = 0
		is_falling = true
		await get_tree().process_frame
	
	position.x = start_x
	is_dashing = false
	
	
