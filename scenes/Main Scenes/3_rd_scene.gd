extends Node2D

@onready var screen_fade = $GUI/ScreenFade
@onready var dialogue_resource: DialogueResource = preload("res://dialogues/p3_intro.dialogue")
var balloon_scene = preload("res://balloons/SystemBalloon.tscn")
@onready var boss_dialogue_resource: DialogueResource = preload("res://dialogues/p3_boss.dialogue")
var boss_balloon_scene = preload("res://balloons/BossBalloon.tscn")

func _init() -> void:
	GameManager.phase_num = 3
	GameManager.merchant_access = 1
	GameManager.enemies_killed = 0
	GameManager.algae_eaten = 0
	GameManager.caps_collected = 0

func _ready():
	GameManager.current_scene_path = "res://scenes/Main Scenes/3rd_scene.tscn"
	
	screen_fade.color.a = 1.0
	screen_fade.set_z_index(1000)
	await fade_out_screen()
	
	var balloon_instance = balloon_scene.instantiate()
	get_tree().current_scene.add_child(balloon_instance)

	# Connect dialogue finished signal
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	balloon_instance.start(dialogue_resource, "start")

func _on_dialogue_ended(_resource):
	GameManager.set_player_movable(true)
	DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)

func _on_boss_dialogue_area_body_entered(body) -> void:
	if body.is_in_group("player"):
		GameManager.set_player_movable(false)
		var balloon_instance = boss_balloon_scene.instantiate()
		get_tree().current_scene.add_child(balloon_instance)

		# Connect dialogue finished signal
		if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
			DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

		balloon_instance.start(boss_dialogue_resource, "start")
		$"Boss Dialogue Area".queue_free()

func fade_in_screen():
	var tween = create_tween()
	tween.tween_property(screen_fade, "color:a", 1.0, 1.5)
	await tween.finished

func fade_out_screen():
	var tween = create_tween()
	tween.tween_property(screen_fade, "color:a", 0.0, 1.5)
	await tween.finished

func _on_kingstar_boss_died() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/Main Scenes/ending.tscn")
