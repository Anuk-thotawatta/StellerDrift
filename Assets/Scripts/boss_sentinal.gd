extends Node2D

@onready var sentinal_eye: Sprite2D = $sentinal_eye
@onready var player: CharacterBody2D = $"../Player"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	if player:
		var target_angle = (player.global_position - sentinal_eye.global_position).angle() + PI
		sentinal_eye.rotation = lerp_angle(sentinal_eye.rotation, target_angle, delta * 5.0)
