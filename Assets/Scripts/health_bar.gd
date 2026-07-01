extends ProgressBar

@onready var timer: Timer = $Timer
@onready var damage_bar: ProgressBar = $DamageBar

var current_health: int = 0

var original_position: Vector2
var shake_intensity: float = 0.0
var shake_decay: float = 5.0

func _ready() -> void:
	original_position = position

func _process(delta: float) -> void:
	if shake_intensity > 0:
		shake_intensity = move_toward(shake_intensity, 0.0, shake_decay * delta)
		
		var offset_x = randf_range(-shake_intensity, shake_intensity)
		var offset_y = randf_range(-shake_intensity, shake_intensity)
		position = original_position + Vector2(offset_x, offset_y)
		
		if shake_intensity <= 0:
			position = original_position

func init_health(_health: int) -> void:
	current_health = _health
	max_value = _health
	value = _health
	if damage_bar:
		damage_bar.max_value = _health
		damage_bar.value = _health

func update_health(new_health: int) -> void:
	var prev_health = current_health
	current_health = clampi(new_health, 0, int(max_value))
	value = current_health
	
	if current_health < prev_health:
		if timer:
			timer.start()
		shake_intensity = 5.0
	else:
		if damage_bar:
			damage_bar.value = current_health

func _on_timer_timeout() -> void:
	if damage_bar:
		damage_bar.value = current_health
