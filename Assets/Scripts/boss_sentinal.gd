extends Node2D

@onready var sentinal_eye: Sprite2D = $sentinal_eye
@onready var player: CharacterBody2D = $"../Player"
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sentinal_body: Sprite2D = $sentinal_body
@onready var upper_laser = $UpperTentacle/laser_gun
@onready var lower_laser = $LowerTentacle/laser_gun

var sentinal_body_pos;
var boss_hp = 1000
var bullet_dmg = 125

signal boss_defeated

func _ready():
	pass

func _process(delta: float) -> void:
	sentinal_body_pos = sentinal_body.position
	upper_laser.position.x = sentinal_body_pos.x - 300
	lower_laser.position.x = sentinal_body_pos.x - 300
	# Eye tracks player
	var target_angle = (player.global_position - sentinal_eye.global_position).angle() + PI
	sentinal_eye.rotation = lerp_angle(sentinal_eye.rotation, target_angle, delta * 5.0)
	upper_laser.rotation = 0
	lower_laser.rotation = 0
	
	# Move palms towards player
	target_player(delta)
	
	# IK chains update automatically in their own _physics_process

func target_player(delta):
	var player_altitude = player.position.y
	
	# Upper arm aims slightly above player
	upper_laser.position.y = lerp(upper_laser.position.y, player_altitude - 40, delta * 1.0)
	
	# Lower arm aims slightly below player
	lower_laser.position.y = lerp(lower_laser.position.y, player_altitude + 40, delta * 1.0)

func _on_area_2d_area_entered(area: Area2D):
	if area.is_in_group("bullets"):
		var bullet = area
		if not bullet.has_hit:
			bullet.has_hit = true
			print("boss is hit")
			animation_player.stop()
			animation_player.play("eye_damage_taken")
			bullet.queue_free()
			boss_hp -= bullet_dmg
			
			if boss_hp <= 0:
				boss_hp = 1000  # Reset health
				boss_defeated.emit()
				
