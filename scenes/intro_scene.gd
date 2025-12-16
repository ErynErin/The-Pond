extends Node2D

@onready var video_player = $VideoStreamPlayer
@onready var intro_dialogue = preload("res://dialogues/p1_intro.dialogue")
@onready var system_balloon_scene = preload("res://balloons/TutorialBalloon.tscn")

@onready var player = $player
@onready var screen_fade = $CanvasLayer/ScreenFade

func _ready():
	GameManager.current_scene_path = "res://scenes/Main Scenes/intro_scene.tscn"
	
	# Don't start with black screen — screen_fade is transparent at first
	screen_fade.color.a = 0.0
	screen_fade.set_z_index(1000)

	# Player starts invisible and inactive
	player.modulate.a = 0.0
	player.visible = false
	player.set_physics_process(false)

	# Play video
	video_player.play()

func _on_skip_button_pressed() -> void:
	video_player.stop()
	video_player.hide()
	_on_video_stream_player_finished()
	$CanvasLayer/SkipButton.hide()

func _on_video_stream_player_finished():
	print("Video finished!")
	screen_fade.color.a = 1.0
	screen_fade.set_z_index(1000)
	$AudioStreamPlayer.play()
	
	#Fade to black AFTER video ends
	await fade_in_screen()

	# Fade out black screen to reveal player and dialogue
	await fade_out_screen()

	# Fade in the player (now screen is clear)
	fade_in_player()

	# Start dialogue
	var balloon_instance = system_balloon_scene.instantiate()
	get_tree().current_scene.add_child(balloon_instance)

	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	balloon_instance.start(intro_dialogue, "start")

	# Start dialogue
	system_balloon_scene.instantiate()
	#get_tree().current_scene.add_child(balloon_instance)

	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	balloon_instance.start(intro_dialogue, "start")

func fade_in_player():
	player.visible = true
	player.set_physics_process(true)

	var tween = create_tween()
	tween.tween_property(player, "modulate:a", 1.0, 2.0)

func _on_dialogue_ended(_resource):
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)

	await fade_in_screen()
	get_tree().change_scene_to_file("res://scenes/Main Scenes/nursery_scene.tscn")

func fade_in_screen():
	var tween = create_tween()
	tween.tween_property(screen_fade, "color:a", 1.0, 1.5)
	await tween.finished

func fade_out_screen():
	var tween = create_tween()
	tween.tween_property(screen_fade, "color:a", 0.0, 1.5)
	await tween.finished
