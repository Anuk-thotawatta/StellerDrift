extends Node2D

var player = null
var speed = 300

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_root().get_node("Game/Player")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.x -= speed * delta
	if position.x < -2000:
		queue_free()



func _on_area_2d_body_entered(body) :
	if body.name == "Player":
		player.get_extra_life()
		player.extra_life_count += 1 #need to fulfil upon picking pwr up
		hide()
