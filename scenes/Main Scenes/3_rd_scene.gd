extends Node2D

@onready var screen_fade = $GUI/ScreenFade
@onready var trash_flood: Node2D = $"Trash Flood"
@onready var wall: StaticBody2D = $Wall
@onready var dialogue_resource: DialogueResource = preload("res://dialogues/p3_intro.dialogue")
var balloon_scene = preload("res://balloons/SystemBalloon.tscn")

func _init() -> void:
	GameManager.phase_num = 3
	GameManager.merchant_access = 1
	GameManager.enemies_killed = 0
	GameManager.algae_eaten = 0
	GameManager.caps_collected = 0

func _ready():
	GameManager.starting_health = GameManager.current_health
	GameManager.current_scene_path = "res://scenes/Main Scenes/3rd_scene.tscn"
	
	screen_fade.color.a = 1.0
	screen_fade.set_z_index(1000)
	await fade_out_screen()
	
	start_dialogue("start", true, balloon_scene)

func _on_dialogue_ended(_resource):
	GameManager.set_player_movable(true)
	DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)

func fade_in_screen():
	var tween = create_tween()
	tween.tween_property(screen_fade, "color:a", 1.0, 1.5)
	await tween.finished

func fade_out_screen():
	var tween = create_tween()
	tween.tween_property(screen_fade, "color:a", 0.0, 1.5)
	await tween.finished

# OUTRO PARTTTTTTTTTT
func _on_boss_died() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/Main Scenes/ending.tscn")

func start_dialogue(title: String, make_player_movable: bool, balloon):
	GameManager.set_player_movable(make_player_movable)

	var balloon_instance = balloon.instantiate()
	get_tree().current_scene.add_child(balloon_instance)

	# Connect dialogue finished signal once
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	balloon_instance.start(dialogue_resource, title)

func _on_trash_flood_signal_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		start_dialogue("trash_flood", true, balloon_scene)
		
		if not trash_flood.is_connected("flood_finished", _on_trash_flood_flood_finished):
			trash_flood.connect("flood_finished", _on_trash_flood_flood_finished)
		
		trash_flood.start_flood() # start trash flood
		wall.set_deferred("disabled", false) # Enables wall
		$"Trash Flood Signal".queue_free()

func _on_trash_flood_flood_finished() -> void:
	if trash_flood.is_connected("flood_finished", _on_trash_flood_flood_finished):
		trash_flood.disconnect("flood_finished", _on_trash_flood_flood_finished)
