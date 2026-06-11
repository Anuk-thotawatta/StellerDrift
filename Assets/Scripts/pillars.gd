extends Node2D

var speed = 300
var player = null
var gap_center = 0.0 

func _ready():
	player = get_tree().get_root().get_node("Game/Player")
	gap_center = position.y
	
func die():
	get_tree().get_root().get_node("Game").player_died()
	
func _process(delta):
	position.x -= speed * delta
	if position.x < -2000:
		queue_free()
		
func _on_area_2d_body_entered(body):
	if body.name == "Player":
		if player.extra_life_count <= 0:
			die()
		else:
			Global.countdown_happening = true
			player.extra_life_count -= 1 
			if(player.extra_life_count <= 1):
				player.lose_extra_life()
			get_tree().paused = true
			await get_tree().create_timer(1.0, true).timeout
			player.position.y = position.y 
			player.rotation = 0.0
			player.velocity = Vector2.ZERO
			await get_tree().create_timer(2.0, true).timeout
			Global.countdown_happening = false
			get_tree().paused = false
			
			
