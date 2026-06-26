extends RayCast2D

@onready var beam_line: Line2D = $beam_line
@export var max_length: float = 2000.0

var is_firing: bool = false

func _ready():
	set_physics_process(false)
	beam_line.points[1] = Vector2.ZERO
	beam_line.hide() # Keep it hidden until we fire

func turn_on():
	is_firing = true
	set_physics_process(true)
	beam_line.show()

func turn_off():
	is_firing = false
	set_physics_process(false)
	beam_line.hide()
	beam_line.points[1] = Vector2.ZERO

func _physics_process(delta):
	target_position = Vector2(-max_length, 0)
	
	force_raycast_update()
	
	var cast_point = target_position
	
	if is_colliding():
		cast_point = to_local(get_collision_point())
		
		# Handle hitting the player
		var collider = get_collider()
		if collider and collider.name == "Player":
			# If player has extra lives, trigger a hit sequence
			if collider.extra_life_count <= 0:
				get_tree().get_root().get_node("Game").player_died()
			else:
				# Trigger the player's damage logic
				if not Global.countdown_happening:
					# Assuming your main game node manages this, or you can call a hit method:
					# collider.take_damage()
					pass
			
	# Stretch Point 1 of the Line2D to match the collision or maximum range point
	beam_line.points[1] = cast_point
