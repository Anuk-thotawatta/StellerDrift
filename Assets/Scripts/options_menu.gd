extends Control

@onready var button_sound: AudioStreamPlayer2D = $button_sound
@onready var master_volume_sldr: HSlider = $Panel/MasterVolume_sldr
@onready var music_volume_sldr: HSlider = $Panel/MusicVolume_sldr
@onready var effects_volume_sldr: HSlider = $Panel/EffectsVolume_sldr
@onready var game_speed_sldr: HSlider = $Panel/gameSpeed_sldr

var master_audio = 1.0
var music_audio = 1.0
var effects_audio = 1.0
var gameSpeed = 300

func _ready() -> void:
	loadOptions()
	hide()

func saveOptions():
	var data = {
		"MasterAudio": master_audio,
		"MusicAudio": music_audio,
		"EffectsAudio": effects_audio,
		"GameSpeed": Global.gameSpeed
	}
	var file = FileAccess.open(Global.OPTIONSPATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func loadOptions():
	if FileAccess.file_exists(Global.OPTIONSPATH):
		var file = FileAccess.open(Global.OPTIONSPATH, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		if data:
			master_audio = data.get("MasterAudio", 1.0)
			music_audio = data.get("MusicAudio", 1.0)
			effects_audio = data.get("EffectsAudio", 1.0)
			gameSpeed = data.get("GameSpeed",300)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_audio))
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_audio))
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), linear_to_db(effects_audio))
			Global.gameSpeed = gameSpeed
			master_volume_sldr.value = master_audio
			music_volume_sldr.value = music_audio
			effects_volume_sldr.value = effects_audio
			game_speed_sldr.value = gameSpeed
			

func _on_back_button_pressed() -> void:
	saveOptions()
	hide()

func _on_back_button_button_down() -> void:
	button_sound.play()

func _on_back_button_mouse_entered() -> void:
	button_sound.play()

func _on_master_volume_sldr_value_changed(value: float) -> void:
	master_audio = value  
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_music_volume_sldr_value_changed(value: float) -> void:
	music_audio = value 
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func _on_effects_volume_sldr_value_changed(value: float) -> void:
	effects_audio = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), linear_to_db(value))

func _on_game_speed_sldr_value_changed(value: float) -> void:
	Global.gameSpeed = value
