extends Node2D

@onready var sentinal_eye: Sprite2D = $sentinal_eye
@onready var player: CharacterBody2D = $"../Player"
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	if player:
		var target_angle = (player.global_position - sentinal_eye.global_position).angle() + PI
		sentinal_eye.rotation = lerp_angle(sentinal_eye.rotation, target_angle, delta * 5.0)

func _on_area_2d_area_entered(area: Area2D):
	if area.is_in_group("bullets"):
		var bullet = area
		if not bullet.has_hit:
			bullet.has_hit = true
			print("boss is hit")
			animation_player.stop()
			animation_player.play("eye_damage_taken")
			bullet.queue_free()
		
