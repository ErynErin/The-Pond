extends Node2D

@export var fish_scenes: Array[PackedScene]
@onready var spawn_timer: Timer = $SpawnTimer
var spawn_from_right: bool 
var current_stage: int

@export var screen_width: float = 27000.0
@export var screen_height: float = 2162.0

func _ready() -> void:
	if not spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	start_fish_swarm()
	spawn_from_right = true
	current_stage = GameManager.phase_num

func start_fish_swarm() -> void:
	randomize()
	spawn_timer.start(6)

func _on_spawn_timer_timeout() -> void:
	if fish_scenes.is_empty(): return

	# Select Fish Type
	var fish_index: int = randi() % fish_scenes.size()
	var fish_instance = fish_scenes[fish_index].instantiate()
	
	if fish_instance is AnimatedSprite2D:
		var fish_name: String = ""
		match fish_index:
			0: fish_name = "fish"
			1: fish_name = "goldfish"
			2: fish_name = "koi"
		
		var anim_to_play: String = str(current_stage) + "_" + fish_name
		
		fish_instance.play(anim_to_play)

	# Determine Side
	var spawn_x: float
	var target_x: float
	var direction_multiplier: float
	
	if spawn_from_right:
		spawn_x = screen_width + 150
		target_x = -150
		direction_multiplier = 1.0 # Normal facing left (or right depending on your sprite)
	else:
		spawn_x = -150
		target_x = screen_width + 150
		direction_multiplier = -1.0

	var spawn_y: float = randf_range(100, screen_height - 100)
	fish_instance.position = Vector2(spawn_x, spawn_y)

	# Scaling logic
	var base_scale: float = 0.0
	if fish_index == 2:
		base_scale = randf_range(2.5, 3.0) # Big fish
	else:
		base_scale = randf_range(1.2, 2.5) # Small fish
	
	if fish_index == 0:
		fish_instance.scale = Vector2(base_scale * -direction_multiplier, base_scale)
	else:
		fish_instance.scale = Vector2(base_scale * direction_multiplier, base_scale)

	# Slow Movement Logic
	add_child(fish_instance)
	var tween = create_tween()
	var duration: float = randf_range(70, 100) 
	
	spawn_from_right = !spawn_from_right # alternate spawning sides
	
	tween.tween_property(fish_instance, "position:x", target_x, duration)
	tween.finished.connect(fish_instance.queue_free)
