extends Control

@onready var music_slider: HSlider = $VBoxContainer/Music_Slider
@onready var sfx_slider: HSlider = $VBoxContainer/SFX_Slider

@export var music_bus_name: String = "Background Music"
@export var sfx_bus_name: String = "SFX"

var music_bus_index
var sfx_bus_index

# Custom function to map a linear 0-100 value to a custom dB range
func convert_slider_value_to_db(value: float) -> float:
	# Set your desired range
	var min_db = -30.0
	var max_db = 10.0

	# Normalize the value from 0-100 to 0.0-1.0
	var normalized_value = value / 100.0

	# Return the mapped dB value
	return min_db + (max_db - min_db) * normalized_value

# Custom function to map a dB value to a linear 0-100 value
func convert_db_to_slider_value(db_value: float) -> float:
	# Set your desired range
	var min_db = -30.0
	var max_db = 10.0

	# Normalize the dB value from your range to 0.0-1.0
	var normalized_db = (db_value - min_db) / (max_db - min_db)

	# Return the mapped slider value (0-100)
	return normalized_db * 100.0

func _ready():
	music_bus_index = AudioServer.get_bus_index(music_bus_name)
	sfx_bus_index = AudioServer.get_bus_index(sfx_bus_name)

	# Set initial slider values from the current bus volume
	music_slider.value = convert_db_to_slider_value(AudioServer.get_bus_volume_db(music_bus_index))
	sfx_slider.value = convert_db_to_slider_value(AudioServer.get_bus_volume_db(sfx_bus_index))

	music_slider.value_changed.connect(_on_music_slider_value_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)

func _on_music_slider_value_changed(value: float):
	AudioServer.set_bus_volume_db(music_bus_index, convert_slider_value_to_db(value))
	
func _on_sfx_slider_value_changed(value: float):
	AudioServer.set_bus_volume_db(sfx_bus_index, convert_slider_value_to_db(value))

func _on_exit_pressed() -> void:
	$AudioStreamPlayer.play()
	GameManager.hide_options()
