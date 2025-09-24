extends Node2D

@export var trash_scenes: Array[PackedScene]
@export var screen_width: float = 1920
@export var screen_height: float = 1080

@onready var spawn_timer: Timer = $Timer

func _ready() -> void:
	randomize()
	print("Spawner ready! Timer started? ", spawn_timer.is_stopped() == false)

func _on_timer_timeout() -> void:
	print("--- Timer triggered ---")

	# Pick a random trash scene
	var trash_scene: PackedScene = trash_scenes.pick_random()
	print("Picked trash scene: ", trash_scene.resource_path)

	var trash_instance: Node2D = trash_scene.instantiate()

	# Random spawn position (right side, random Y)
	var spawn_x: float = screen_width + 100
	var spawn_y: float = randf_range(0, screen_height)
	trash_instance.position = Vector2(spawn_x, spawn_y)
	print("Spawn position: (", spawn_x, ", ", spawn_y, ")")

	# Random size (scale between 0.5x and 1.5x for variety)
	var random_scale: float = randf_range(0.8, 1.3)
	trash_instance.scale = Vector2(random_scale, random_scale)
	print("Random scale: ", random_scale)

	# Add to scene
	add_child(trash_instance)
	print("Added trash instance to scene")

	var tween = create_tween()
	tween.tween_property(trash_instance, "position:x", -100, 5.0) # 5s to exit screen
	tween.tween_callback(trash_instance.queue_free)
	print("Applied tween movement")
