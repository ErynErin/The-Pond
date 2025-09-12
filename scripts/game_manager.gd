extends Node

var hunger = 0
var max_health = 100.0
var current_health = 95.0
var strength = 10
var speed = 200
var next_scene_path = ""
var current_scene_path = "res://scenes/intro_scene.tscn"
var phase_num = 1
var merchant_access = 1
var can_move: bool = true
var coins = 0
@export var inv: Inv
signal health_changed(current_health: float, max_health: float)
signal player_died
signal shop_closed

func load_to_scene(next_scene: String):
	next_scene_path = next_scene
	get_tree().change_scene_to_file.call_deferred("res://scenes/Main Scenes/loading_scene.tscn")

func add_hunger():
	if hunger != 5:
		hunger += 1
		print("hunger:", hunger)
		var current_scene = get_tree().current_scene
		var hunger_lower_bar = current_scene.get_node("GUI/hunger lower bar")
		match hunger:
			1:
				hunger_lower_bar.region_rect = Rect2(0, 0, 215, 1000)
				hunger_lower_bar.size.x = 54.0
				print("num 1")
			2:
				hunger_lower_bar.region_rect = Rect2(0, 0, 410, 1000)
				hunger_lower_bar.size.x = 102.0
				print("num 2")
			3:
				hunger_lower_bar.region_rect = Rect2(0, 0, 600, 1000)
				hunger_lower_bar.size.x = 150.0
				print("num 3")
			4:
				hunger_lower_bar.region_rect = Rect2(0, 0, 790, 1000)
				hunger_lower_bar.size.x = 198.0
				print("num 4")
			5:
				hunger_lower_bar.region_rect = Rect2(0, 0, 0, 0)
				hunger_lower_bar.size.x = 250.0
				print("num 5")
	else:
		hunger += 1
		print("hunger: ", hunger, "more than 5")

func add_health():
	max_health += 20
	print("health: ", max_health)
	
func add_strength():
	strength += 20
	print("strength: ", strength)
	
func add_speed():
	speed += 50
	print("speed:", speed)

func show_shop():
	var current_scene = get_tree().current_scene	
	var merchant_shop = current_scene.get_node("GUI/merchant shop")
	merchant_access -= 1
	merchant_shop.visible = true
	
func hide_shop():
	var current_scene = get_tree().current_scene
	var merchant_shop = current_scene.get_node("GUI/merchant shop")
	emit_signal("shop_closed")
	merchant_shop.visible = false

func show_options():
	var current_scene = get_tree().current_scene	
	var options = current_scene.get_node("GUI/Options")
	options.visible = true
	
func hide_options():
	var current_scene = get_tree().current_scene
	var options = current_scene.get_node("GUI/Options")
	options.visible = false

func take_damage(damage: float):
	current_health -= damage
	current_health = max(current_health, 0)  # Don't go below 0
	health_changed.emit(current_health, max_health)
	print("Player Health Decreased by " + str(damage))
	print("New Health " + str(current_health))
	check_player_status()

func heal(amount: float):
	current_health += amount
	current_health = min(current_health, max_health)
	emit_signal("health_changed", current_health, max_health)
	check_player_status()

func set_health(new_health: float):
	current_health = clamp(new_health, 0, max_health) 
	health_changed.emit(current_health, max_health)

func check_player_status():
	if current_health <= 0:
		print("Player has died.")
		player_died.emit()

func collect(item):
	inv.insert(item)

func set_player_movable(is_movable: bool):
	can_move = is_movable
<<<<<<< Updated upstream
=======

func add_coin(amount: int):
	coins += amount
	emit_signal("coins_updated", coins)
	
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
