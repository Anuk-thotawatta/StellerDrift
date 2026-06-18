extends Node2D

var speed = Global.gameSpeed * 2

func _physics_process(delta):
	position.x += speed * delta  
	rotation = 0.0

func _on_body_entered(body):
	body.take_damage()
	queue_free()
