extends Node2D

signal flood_finished

@export var trash_scenes: Array[PackedScene]
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var spawn_timer: Timer = $SpawnTimer
@onready var flood_timer: Timer = $FloodTimer

var screen_width: float = 1920
var screen_height: float = 1080

func start_flood() -> void:
	randomize()
	animation_player.play("start")
	await animation_player.animation_finished
	spawn_timer.start(0.3)
	flood_timer.start(4.0) # stop spawning after 4 seconds

func _on_spawn_timer_timeout() -> void:
	# Pick a random trash scene
	var trash_scene: PackedScene = trash_scenes.pick_random()
	var trash_instance: Node2D = trash_scene.instantiate()

	# Random spawn position (right side, random Y)
	var spawn_x: float = screen_width + 100
	var spawn_y: float = randf_range(0, screen_height)
	trash_instance.position = Vector2(spawn_x, spawn_y)

	# Random size (scale between 0.8x and 1.3x for variety)
	var random_scale: float = randf_range(0.8, 1.3)
	trash_instance.scale = Vector2(random_scale, random_scale)

	# Add to scene
	add_child(trash_instance)
	var tween = create_tween()
	tween.tween_property(trash_instance, "position:x", -100, 5.0) # 5s to exit screen
	tween.tween_callback(trash_instance.queue_free)

func _on_flood_timer_timeout() -> void:
	spawn_timer.stop()
	emit_signal("flood_finished")
