extends Node2D

@onready var sentinal_eye: Sprite2D = $sentinal_eye
@onready var player: CharacterBody2D = $"../Player"
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sentinal_body: Sprite2D = $sentinal_body
@onready var upper_laser = $UpperTentacle/laser_gun
@onready var lower_laser = $LowerTentacle/laser_gun

@onready var eye_laser_fx: ColorRect = $sentinal_eye/eye_laser_fx
@onready var lower_laser_fx: ColorRect = $LowerTentacle/laser_gun/lower_palm_laser
@onready var upper_laser_fx: ColorRect = $UpperTentacle/laser_gun/upper_palm_laser

var sentinal_body_pos
var eye_rotation
var boss_hp = 1000
var bullet_dmg = 125
var beam_telegraph = 2.0
var eye_beam_telegraph = 4.0
var next_attack: int = 0

signal boss_defeated

enum BossState { TRACKING, CHARGING_UPPER, CHARGING_LOWER, CHARGING_EYE, FIRING, HURT }
var current_state: BossState = BossState.TRACKING

func _ready() -> void:
	if eye_laser_fx.material:
		eye_laser_fx.material = eye_laser_fx.material.duplicate()
	if lower_laser_fx.material:
		lower_laser_fx.material = lower_laser_fx.material.duplicate()
	if upper_laser_fx.material:
		upper_laser_fx.material = upper_laser_fx.material.duplicate()
		
	run_boss()

func _process(delta: float) -> void:
	# Keep calculating positions and tracking the player as long as we aren't stunned
	if current_state != BossState.HURT:
		sentinal_body_pos = sentinal_body.position
		upper_laser.position.x = sentinal_body_pos.x - 300
		lower_laser.position.x = sentinal_body_pos.x - 300
		
		# Eye tracks player
		if current_state != BossState.CHARGING_EYE:
			eye_rotation = (player.global_position - sentinal_eye.global_position).angle() + PI
			sentinal_eye.rotation = lerp_angle(sentinal_eye.rotation, eye_rotation, delta * 5.0)
		
		upper_laser.rotation = 0
		lower_laser.rotation = 0
		
		# Move palms towards player
		target_player(delta)

func target_player(delta: float) -> void:
	var player_altitude = player.position.y
	
	# Upper arm aims slightly above player
	upper_laser.position.y = lerp(upper_laser.position.y, player_altitude - 40, delta * 1.0)
	# Lower arm aims slightly below player
	lower_laser.position.y = lerp(lower_laser.position.y, player_altitude + 40, delta * 1.0)

func run_boss() -> void:
	while true:
		match current_state:
			BossState.TRACKING:
				await get_tree().create_timer(2.5).timeout
				if current_state == BossState.TRACKING:
					if next_attack == 0:
						current_state = BossState.CHARGING_UPPER
					elif next_attack == 1:
						current_state = BossState.CHARGING_LOWER
					else:
						current_state = BossState.CHARGING_EYE
					
					next_attack = (next_attack + 1) % 3

			BossState.CHARGING_UPPER:
				charge_and_shoot_upper(beam_telegraph)
				await get_tree().create_timer(beam_telegraph + 0.1).timeout
				if current_state == BossState.CHARGING_UPPER:
					current_state = BossState.FIRING

			BossState.FIRING:
				await get_tree().create_timer(1.0).timeout
				if current_state == BossState.FIRING:
					current_state = BossState.TRACKING

			BossState.CHARGING_LOWER:
				charge_and_shoot_lower(beam_telegraph)
				await get_tree().create_timer(beam_telegraph + 0.1).timeout
				if current_state == BossState.CHARGING_LOWER:
					current_state = BossState.FIRING

			BossState.CHARGING_EYE:
				charge_and_shoot_eye(eye_beam_telegraph)
				await get_tree().create_timer(eye_beam_telegraph + 0.1).timeout
				if current_state == BossState.CHARGING_EYE:
					current_state = BossState.FIRING

			BossState.HURT:
				await get_tree().create_timer(0.4).timeout
				if current_state == BossState.HURT:
					current_state = BossState.TRACKING

func charge_and_shoot_lower(duration: float) -> void:
	if not lower_laser_fx.material: return
	var tween = create_tween()
	lower_laser_fx.material.set_shader_parameter("charge_progress", 0.0)
	tween.tween_property(lower_laser_fx.material, "shader_parameter/charge_progress", 1.0, duration)
	tween.tween_callback(shootLowerLaser)

func charge_and_shoot_upper(duration: float) -> void:
	if not upper_laser_fx.material: return
	var tween = create_tween()
	upper_laser_fx.material.set_shader_parameter("charge_progress", 0.0)
	tween.tween_property(upper_laser_fx.material, "shader_parameter/charge_progress", 1.0, duration)
	tween.tween_callback(shootUpperLaser)

func charge_and_shoot_eye(duration: float) -> void:
	if not eye_laser_fx.material: return
	var tween = create_tween()
	eye_laser_fx.material.set_shader_parameter("charge_progress", 0.0)
	tween.tween_property(eye_laser_fx.material, "shader_parameter/charge_progress", 1.0, duration)
	tween.tween_callback(shootEyeLaser)

func shootLowerLaser() -> void:
	print("Lower Laser FIRED!")
	# Spawn beam scene here	
	var fade_tween = create_tween()
	fade_tween.tween_property(lower_laser_fx.material,"shader_parameter/charge_progress",0.0,0.35)
	
func shootUpperLaser() -> void:
	print("Upper Laser FIRED!")
	# Spawn beam scene here	
	var fade_tween = create_tween()
	fade_tween.tween_property(upper_laser_fx.material,"shader_parameter/charge_progress",0.0,0.35)
	
func shootEyeLaser() -> void:
	print("Eye Laser FIRED!")
	# Spawn eye beam scene here	
	var fade_tween = create_tween()
	fade_tween.tween_property(eye_laser_fx.material,"shader_parameter/charge_progress",0.0,0.35)

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullets"):
		var bullet = area
		if not bullet.has_hit:
			bullet.has_hit = true
			print("boss is hit")
			
			# Switch to HURT state to break active charging loops
			current_state = BossState.HURT
			
			# Clean up visual shader artifacts instantly so they don't get stuck glowing
			lower_laser_fx.material.set_shader_parameter("charge_progress", 0.0)
			upper_laser_fx.material.set_shader_parameter("charge_progress", 0.0)
			eye_laser_fx.material.set_shader_parameter("charge_progress", 0.0)
			
			animation_player.stop()
			animation_player.play("eye_damage_taken")
			bullet.queue_free()
			boss_hp -= bullet_dmg
			
			if boss_hp <= 0:
				boss_hp = 1000
				boss_defeated.emit()
