extends Node2D

@onready var wall: CollisionShape2D = $"Dialogue Signal Areas/Invisible Wall/CollisionShape2D"
@onready var wall2: CollisionShape2D = $"Dialogue Signal Areas/Invisible Wall2/CollisionShape2D"
@onready var screen_fade = $GUI/ScreenFade
@onready var dialogue_resource: DialogueResource = preload("res://dialogues/p1_nurseryintro.dialogue")
var balloon_scene = preload("res://balloons/SystemBalloon.tscn")
var balloon_scene2 = preload("res://balloons/TutorialBalloon.tscn")
var dialogue_resource_title: String = ""

func _init() -> void:
	GameManager.phase_num = 1
	GameManager.merchant_access = 1
	GameManager.enemies_killed = 0
	GameManager.algae_eaten = 0
	GameManager.caps_collected = 0

func _ready():
	#wall2.set_deferred("disabled", false) # Enables wall
	wall.position = Vector2(2030, -5)
	GameManager.current_scene_path = "res://scenes/Main Scenes/nursery_scene.tscn"
	
	screen_fade.color.a = 1.0
	screen_fade.set_z_index(1000)
	await fade_out_screen()
	
	start_dialogue("start", true, balloon_scene)

func start_dialogue(title: String, make_player_movable: bool, balloon):
	GameManager.set_player_movable(make_player_movable)

	var balloon_instance = balloon.instantiate()
	get_tree().current_scene.add_child(balloon_instance)

	# Connect dialogue finished signal once
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	dialogue_resource_title = title
	balloon_instance.start(dialogue_resource, dialogue_resource_title)

func _on_dialogue_ended(_resource):
	if dialogue_resource_title == "start":
		wall.position = Vector2(3440.0,-5) # transfer for worm attacking
	elif dialogue_resource_title == "worm_end":
		$GUI/Objectives.visible = true
	
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

func _on_worm_tutorial_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		start_dialogue("worm_meet", false, balloon_scene)
		$"Dialogue Signal Areas/Worm Tutorial".queue_free()

func _on_first_worm_killed() -> void:
	wall.queue_free()
	start_dialogue("worm_end", true, balloon_scene)

func _on_siblings_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		start_dialogue("ted_siblings", false, balloon_scene2)
		$"Dialogue Signal Areas/Siblings".queue_free()

func _on_trash_flood_body_entered(body: Node2D) -> void:
	var trash_flood: Node2D = $"Trash Flood"

	if body.is_in_group("player"):
		start_dialogue("before_trash_flood", true, balloon_scene)
		
		if not trash_flood.is_connected("flood_finished", _on_trash_flood_flood_finished):
			trash_flood.connect("flood_finished", _on_trash_flood_flood_finished)
		
		trash_flood.start_flood() # start trash flood
		wall2.set_deferred("disabled", false) # Enables wall
		$"Dialogue Signal Areas/Trash Flood".queue_free()

func _on_trash_flood_flood_finished() -> void:
	await get_tree().create_timer(3).timeout
	start_dialogue("after_trash_flood", true, balloon_scene)

	# Disconnect so it doesn’t call again
	var trash_flood: Node2D = $"Trash Flood"
	if trash_flood.is_connected("flood_finished", _on_trash_flood_flood_finished):
		trash_flood.disconnect("flood_finished", _on_trash_flood_flood_finished)

#func _on_objectives_checker_body_entered(body: Node2D) -> void:
	#if body.is_in_group("player"):
		#print(GameManager.merchant_access == 0)
		#print(GameManager.phase_objectives["p" + str(GameManager.phase_num)][0] <= GameManager.enemies_killed)
		#print(GameManager.phase_objectives["p" + str(GameManager.phase_num)][1] <= GameManager.algae_eaten)
		#print(GameManager.phase_objectives["p" + str(GameManager.phase_num)][2] <= GameManager.caps_collected)
		## Disables wall going to trash flood if the objectives are met
		#if GameManager.merchant_access == 0 and GameManager.phase_objectives["p" + str(GameManager.phase_num)][0] <= GameManager.enemies_killed and GameManager.phase_objectives["p" + str(GameManager.phase_num)][1] <= GameManager.algae_eaten and GameManager.phase_objectives["p" + str(GameManager.phase_num)][2] <= GameManager.caps_collected:
			#wall2.set_deferred("disabled", true)
		#else:
			#$"GUI/Objectives Label".visible = true
			#await get_tree().create_timer(3).timeout
			#$"GUI/Objectives Label".visible = false
