extends Control

@onready var button_audio: AudioStreamPlayer = $ButtonAudio
@onready var start_audio: AudioStreamPlayer = $StartAudio

@onready var BG_audio: AudioStreamPlayer = $AudioStreamPlayer
@export var ripple_overlay: NodePath

func _on_start_pressed() -> void:
	start_audio.play()
	await get_tree().create_timer(1.3).timeout 
	GameManager.load_to_scene(GameManager.current_scene_path)

func _on_quit_pressed() -> void:
	button_audio.play()
	await get_tree().create_timer(1.3).timeout 
	get_tree().quit()

func _on_options_pressed() -> void:
	button_audio.play()
	GameManager.show_options()

func _ready():
	BG_audio.play()
