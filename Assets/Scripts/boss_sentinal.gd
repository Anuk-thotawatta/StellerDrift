extends Node2D

@onready var sentinal_eye: Sprite2D = $sentinal_eye
@onready var player: CharacterBody2D = $"../Player"
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var u_palm: Sprite2D = $upper_tentacle/upper_arm0/upper_arm1/upper_arm2/upper_arm3/upper_arm4/upper_arm5/upper_arm6/u_palm
@onready var l_palm: Sprite2D = $lower_tentacle/lower_arm0/lower_arm1/lower_arm2/lower_arm3/lower_arm4/lower_arm5/lower_arm6/l_palm


func _ready():
	pass

func _process(delta: float) -> void:
	# Eye tracks player
	var target_angle = (player.global_position - sentinal_eye.global_position).angle() + PI
	sentinal_eye.rotation = lerp_angle(sentinal_eye.rotation, target_angle, delta * 5.0)
	u_palm.rotation = 0
	l_palm.rotation = 0
	# Move palms towards player
	target_player(delta)
	
	# IK chains update automatically in their own _physics_process

func target_player(delta):
	var player_altitude = player.position.y
	
	# Upper arm aims slightly above player
	u_palm.position.y = lerp(u_palm.position.y, player_altitude - 40, delta * 0.5)
	
	# Lower arm aims slightly below player
	l_palm.position.y = lerp(l_palm.position.y, player_altitude + 40, delta * 0.5)

func _on_area_2d_area_entered(area: Area2D):
	if area.is_in_group("bullets"):
		var bullet = area
		if not bullet.has_hit:
			bullet.has_hit = true
			print("boss is hit")
			animation_player.stop()
			animation_player.play("eye_damage_taken")
			bullet.queue_free()
