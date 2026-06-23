extends Area2D

var speed = Global.gameSpeed * 3
var has_hit = false

func _ready():
	add_to_group("bullets")

func _physics_process(delta):
	position.x += speed * delta  
	rotation = 0.0
