extends Control

@onready var button_audio: AudioStreamPlayer = $ButtonAudio
@onready var start_audio: AudioStreamPlayer = $StartAudio

@onready var BG_audio: AudioStreamPlayer = $AudioStreamPlayer

func _on_start_pressed() -> void:
	start_audio.play()
	if GameManager.current_scene_path != "res://scenes/Main Scenes/intro_scene.tscn":
		GameManager.load_to_scene(GameManager.current_scene_path)
	else:
		get_tree().change_scene_to_file(GameManager.current_scene_path)

func _on_quit_pressed() -> void:
	button_audio.play()
	get_tree().quit()

func _on_options_pressed() -> void:
	button_audio.play()
	GameManager.show_options()

func _ready():
	BG_audio.play()
