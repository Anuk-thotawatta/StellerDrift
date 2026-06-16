extends Node2D

var player = null
var speed = 300
var is_exploding = false

@onready var power_up_fx: ColorRect = $"power-up_fx"

func _ready() -> void:
	player = get_tree().get_root().get_node("Game/Player")

func _process(delta):
	position.x -= speed * delta
	if position.x < -2000:
		queue_free()

func _on_area_2d_body_entered(body) :
	if body.name == "Player" and not is_exploding:
		is_exploding = true
		player.get_extra_life()
		player.extra_life_count += 1 
		$Area2D.set_deferred("monitoring", false)
		$Area2D.set_deferred("monitorable", false)
		explode_effect()
		
func explode_effect():
	var tween = create_tween()
	var material = power_up_fx.material as ShaderMaterial
	if material:
		material.set_shader_parameter("explosion_progress", 0.0)
		tween.tween_property(material, "shader_parameter/explosion_progress", 1.0, 0.5)
		await tween.finished
		queue_free()
	else:
		queue_free()
