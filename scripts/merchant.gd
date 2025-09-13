extends AnimatedSprite2D

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var dialogue_resource: DialogueResource = preload("res://dialogues/p1_merchant.dialogue")
var balloon_scene = preload("res://balloons/MerchantBalloon.tscn")  # Your custom balloon scene

func _ready():
	play("idle")
	interaction_area.interact = Callable(self, "_on_interact")

func _on_interact():
	if GameManager.merchant_access <= 0:
		return
	GameManager.merchant_access -= 1
	GameManager.set_player_movable(false)

	# Create and show the balloon
	var balloon_instance = balloon_scene.instantiate()
	get_tree().current_scene.add_child(balloon_instance)

	# Connect dialogue finished signal
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	# Start the pre-shop dialogue
	var current_scene = get_tree().current_scene
	var scene_name = current_scene.name
	print(scene_name)
	if scene_name == "Ted Game":
		balloon_instance.start(dialogue_resource, "start")
	elif scene_name == "Ted Game 2":
		balloon_instance.start(dialogue_resource, "meet_again")
	elif scene_name == "Ted Game 3":
		balloon_instance.start(dialogue_resource, "meet_again")
	else:
		balloon_instance.start(dialogue_resource, "afterbuy")
	
	GameManager.set_player_movable(true)
	play("talk")

func _on_dialogue_ended(_resource):
	DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)

	# Show the shop UI
	$AudioStreamPlayer.play()
	GameManager.show_shop()

	# Connect to shop_closed to wait before showing afterbuy dialogue
	if not GameManager.shop_closed.is_connected(_on_shop_closed):
		GameManager.shop_closed.connect(_on_shop_closed)

	play("idle")


func _on_shop_closed():
	GameManager.shop_closed.disconnect(_on_shop_closed)

	# Create and show the post-shop dialogue
	var after_balloon = balloon_scene.instantiate()
	get_tree().current_scene.add_child(after_balloon)

	if not DialogueManager.dialogue_ended.is_connected(_on_final_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_final_dialogue_ended)
	
	after_balloon.start(dialogue_resource, "afterbuy")

	play("talk")


func _on_final_dialogue_ended(_resource):
	DialogueManager.dialogue_ended.disconnect(_on_final_dialogue_ended)
	play("idle")
	
