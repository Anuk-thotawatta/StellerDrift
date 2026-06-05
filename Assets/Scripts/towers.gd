extends Node2D

var speed = 300

func die():
	get_tree().get_root().get_node("Game").player_died()
	
func _process(delta):
	position.x -= speed * delta
	if position.x < -2000:
		queue_free()
		
func _on_area_2d_body_entered(body):
	if body.name == "Player":
		die()
