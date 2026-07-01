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

@onready var eye_laser: RayCast2D = $sentinal_eye/Eye_Laser
@onready var upper_laser_beam: RayCast2D = $UpperTentacle/laser_gun/upper_Laser_beam
@onready var lower_laser_beam: RayCast2D = $LowerTentacle/laser_gun/lower_Laser_beam

@onready var eye_laser_charge: AudioStreamPlayer2D = $eye_laser_charge
@onready var eye_laser_shoot: AudioStreamPlayer2D = $eye_laser_shoot
@onready var palm_laser_charge: AudioStreamPlayer2D = $laser_charge
@onready var palm_laser_shoot: AudioStreamPlayer2D = $laser_shoot

@onready var health_bar: ProgressBar = $boss_health_bar/HealthBar

var sentinal_body_pos
var eye_rotation
var boss_hp = 1000
var bullet_dmg = 25
var beam_telegraph = 2.0
var eye_beam_telegraph = 4.0
var next_attack: int = 0
var boss_activated: bool = false

var screen_min_y = -650.0
var screen_max_y = 650.0

signal boss_defeated

enum BossState { TRACKING, CHARGING_UPPER, CHARGING_LOWER, CHARGING_EYE, FIRING_SMALL, FIRING_BIG}
var current_state: BossState = BossState.TRACKING

func _ready() -> void:
	health_bar.init_health(boss_hp)
	if eye_laser_fx.material:
		eye_laser_fx.material = eye_laser_fx.material.duplicate()
	if lower_laser_fx.material:
		lower_laser_fx.material = lower_laser_fx.material.duplicate()
	if upper_laser_fx.material:
		upper_laser_fx.material = upper_laser_fx.material.duplicate()
		
func activate_boss() -> void:
	boss_activated = true
	current_state = BossState.TRACKING
	run_boss()
	
func deactivate_boss() -> void:
	boss_activated = false
	turn_off_all_lasers()

func turn_off_all_lasers() -> void:
	if upper_laser_beam: upper_laser_beam.turn_off()
	if lower_laser_beam: lower_laser_beam.turn_off()
	if eye_laser: eye_laser.turn_off()

func _process(delta: float) -> void:
	sentinal_body_pos = sentinal_body.position
	upper_laser.position.x = sentinal_body_pos.x - 300
	lower_laser.position.x = sentinal_body_pos.x - 300

	var eye_is_shooting = eye_laser and eye_laser.is_firing
	
	if current_state == BossState.FIRING_BIG or eye_is_shooting:
		pass
	elif current_state == BossState.CHARGING_EYE:
		var progress = eye_laser_fx.material.get_shader_parameter("charge_progress") if eye_laser_fx.material else 0.0
		if progress < 0.5:
			eye_rotation = (player.global_position - sentinal_eye.global_position).angle() + PI
			sentinal_eye.rotation = lerp_angle(sentinal_eye.rotation, eye_rotation, delta * 5.0)
		else:
			pass
	else:
		eye_rotation = (player.global_position - sentinal_eye.global_position).angle() + PI
		sentinal_eye.rotation = lerp_angle(sentinal_eye.rotation, eye_rotation, delta * 5.0)
	
	upper_laser.rotation = 0
	lower_laser.rotation = 0
	
	target_player(delta)

func target_player(delta: float) -> void:
	var player_altitude = player.position.y
	
	var upper_is_shooting = upper_laser_beam and upper_laser_beam.is_firing
	
	if current_state == BossState.CHARGING_UPPER or upper_is_shooting:
		if not upper_is_shooting:
			var progress = upper_laser_fx.material.get_shader_parameter("charge_progress") if upper_laser_fx.material else 0.0
			if progress < 0.5:
				upper_laser.position.y = lerp(upper_laser.position.y, player_altitude + 200, delta * 5.0)
	else:
		upper_laser.position.y = lerp(upper_laser.position.y, player_altitude - 120, delta * 1.5)

	var lower_is_shooting = lower_laser_beam and lower_laser_beam.is_firing
	
	if current_state == BossState.CHARGING_LOWER or lower_is_shooting:
		if not lower_is_shooting:
			var progress = lower_laser_fx.material.get_shader_parameter("charge_progress") if lower_laser_fx.material else 0.0
			if progress < 0.5:
				lower_laser.position.y = lerp(lower_laser.position.y, player_altitude - 200, delta * 5.0)
	else:
		lower_laser.position.y = lerp(lower_laser.position.y, player_altitude + 120, delta * 1.5)

	if upper_laser.get_parent():
		var min_local = upper_laser.get_parent().to_local(Vector2(0, screen_min_y)).y
		var max_local = upper_laser.get_parent().to_local(Vector2(0, screen_max_y)).y
		upper_laser.position.y = clamp(upper_laser.position.y, min_local, max_local)
		
	if lower_laser.get_parent():
		var min_local = lower_laser.get_parent().to_local(Vector2(0, screen_min_y)).y
		var max_local = lower_laser.get_parent().to_local(Vector2(0, screen_max_y)).y
		lower_laser.position.y = clamp(lower_laser.position.y, min_local, max_local)
	
func run_boss() -> void:
	while true:
		if boss_activated == false:
			break
		match current_state:
			BossState.TRACKING:
				await get_tree().create_timer(1.0).timeout
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
					current_state = BossState.FIRING_SMALL

			BossState.FIRING_SMALL:
				await get_tree().create_timer(1.0).timeout
				if current_state == BossState.FIRING_SMALL:
					current_state = BossState.TRACKING
					
			BossState.FIRING_BIG:
				await get_tree().create_timer(1.0).timeout
				if current_state == BossState.FIRING_BIG:
					current_state = BossState.TRACKING

			BossState.CHARGING_LOWER:
				charge_and_shoot_lower(beam_telegraph)
				await get_tree().create_timer(beam_telegraph + 0.1).timeout
				if current_state == BossState.CHARGING_LOWER:
					current_state = BossState.FIRING_SMALL

			BossState.CHARGING_EYE:
				charge_and_shoot_eye(eye_beam_telegraph)
				await get_tree().create_timer(eye_beam_telegraph + 0.1).timeout
				if current_state == BossState.CHARGING_EYE:
					current_state = BossState.FIRING_BIG

func charge_and_shoot_lower(duration: float) -> void:
	palm_laser_charge.play()
	if not lower_laser_fx.material: return
	var tween = create_tween()
	lower_laser_fx.material.set_shader_parameter("charge_progress", 0.0)
	tween.tween_property(lower_laser_fx.material, "shader_parameter/charge_progress", 1.0, duration)
	tween.tween_callback(shootLowerLaser)

func charge_and_shoot_upper(duration: float) -> void:
	palm_laser_charge.play()
	if not upper_laser_fx.material: return
	var tween = create_tween()
	upper_laser_fx.material.set_shader_parameter("charge_progress", 0.0)
	tween.tween_property(upper_laser_fx.material, "shader_parameter/charge_progress", 1.0, duration)
	tween.tween_callback(shootUpperLaser)

func charge_and_shoot_eye(duration: float) -> void:
	eye_laser_charge.play()
	if not eye_laser_fx.material: return
	var tween = create_tween()
	eye_laser_fx.material.set_shader_parameter("charge_progress", 0.0)
	tween.tween_property(eye_laser_fx.material, "shader_parameter/charge_progress", 1.0, duration)
	tween.tween_callback(shootEyeLaser)

func shootUpperLaser() -> void:
	if upper_laser_beam:
		upper_laser_beam.turn_on()
		palm_laser_shoot.play()
		
	var fade_tween = create_tween()
	fade_tween.tween_property(upper_laser_fx.material, "shader_parameter/charge_progress", 0.0, 0.35)
	fade_tween.tween_interval(0.65)
	fade_tween.tween_callback(func():
		if current_state == BossState.FIRING_SMALL and upper_laser_beam:
			upper_laser_beam.turn_off()
	)

func shootLowerLaser() -> void:
	if lower_laser_beam:
		lower_laser_beam.turn_on()
		palm_laser_shoot.play()
		
	var fade_tween = create_tween()
	fade_tween.tween_property(lower_laser_fx.material, "shader_parameter/charge_progress", 0.0, 0.35)
	fade_tween.tween_interval(0.65)
	fade_tween.tween_callback(func():
		if current_state == BossState.FIRING_SMALL and lower_laser_beam:
			lower_laser_beam.turn_off()
	)
	
func shootEyeLaser() -> void:
	print("Eye Laser FIRED!")
	eye_laser.turn_on()
	eye_laser_shoot.play()
	var fade_tween = create_tween()
	fade_tween.tween_property(eye_laser_fx.material, "shader_parameter/charge_progress", 0.0, 0.35)
	fade_tween.tween_interval(0.65) 
	fade_tween.tween_callback(func():
		if current_state == BossState.FIRING_BIG:
			eye_laser.turn_off()
	)
	
func disable_boss_lasers() -> void:
	if upper_laser_beam: upper_laser_beam.turn_off()
	if lower_laser_beam: lower_laser_beam.turn_off()
	if eye_laser: eye_laser.turn_off()
	
	if upper_laser_fx and upper_laser_fx.material:
		upper_laser_fx.material.set_shader_parameter("charge_progress", 0.0)
	if lower_laser_fx and lower_laser_fx.material:
		lower_laser_fx.material.set_shader_parameter("charge_progress", 0.0)
	if eye_laser_fx and eye_laser_fx.material:
		eye_laser_fx.material.set_shader_parameter("charge_progress", 0.0)
		
	if palm_laser_charge: palm_laser_charge.stop()
	if palm_laser_shoot: palm_laser_shoot.stop()
	if eye_laser_charge: eye_laser_charge.stop()
	if eye_laser_shoot: eye_laser_shoot.stop()
	
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullets"):
		var bullet = area
		if not bullet.has_hit:
			bullet.has_hit = true
			print("boss is hit")

			animation_player.stop()
			animation_player.play("eye_damage_taken")
			bullet.queue_free()
			boss_hp -= bullet_dmg
			
			if health_bar and health_bar.has_method("update_health"):
				health_bar.update_health(boss_hp)
			
			if boss_hp <= 0:
				boss_hp = 1000
				disable_boss_lasers()
				boss_defeated.emit()
