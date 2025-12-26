extends CharacterBody2D

enum State { INACTIVE, PATROL, ATTACK_BALL, ATTACK_INK, VULNERABLE, DEATH }

# Constants
const PATROL_SPEED = 150.0
const INK_MOVE_SPEED = 250.0
const VULNERABLE_MOVE_SPEED = 200.0
const BALL_ATTACK_INTERVAL = 3.0
const VULNERABLE_DURATION = 5.0
const INK_HOVER_TIME = 2.0

# Node references
@onready var animation_player: AnimationPlayer = get_parent().find_child("AnimationPlayer")
@onready var squid_body: AnimatedSprite2D = $Pivot/body
@onready var player = get_parent().get_parent().find_child("player")
@onready var progress_bar: ProgressBar = get_parent().find_child("ProgressBar")
@onready var canvas_layer: CanvasLayer = get_parent().find_child("CanvasLayer")
@onready var wall1: CollisionShape2D = get_parent().find_child("StaticBody2D").find_child("CollisionShape2D")
@onready var wall2: CollisionShape2D = get_parent().find_child("StaticBody2D").find_child("CollisionShape2D2")
@onready var wall3: CollisionShape2D = get_parent().find_child("StaticBody2D").find_child("CollisionShape2D3")
@onready var hurt_box: HurtBox = $Pivot/HurtBox
@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_down: RayCast2D = $RayCastDown
@onready var debug_label: Label = $DebugLabel

@onready var boss_dialogue_resource: DialogueResource = preload("res://dialogues/boss.dialogue")
var boss_balloon_scene = preload("res://balloons/Boss3Balloon.tscn")

var ball_projectile_scene = preload("res://scenes/Characters/ball_projectile.tscn")
var ink_projectile_scene = preload("res://scenes/Characters/ink_projectile.tscn")

signal boss_died

# State variables
var current_state = State.INACTIVE
var player_entered = false
var health = 3
var max_health = 3
var state_timer = 0.0

# Attack cycle tracking
var attack_cycle_step = 0  # 0: ball, 1: ink, 2: ink, 3: ball, 4: ball, then vulnerable
var ball_attack_rounds = 0
var max_ball_rounds = 2
var projectiles_per_round = 2
var saved_player_position: Vector2

# Patrol variables
var patrol_start_position: Vector2
var patrol_direction = 1.0
var distance_traveled = 0.0

# Vulnerable state tracking
var hit_this_vulnerable_cycle = false
var center_position: Vector2
var normal_y_position: float
var ground_y_position: float

# Ink attack variables
var target_x_position: float
var ink_movement_complete = false

func _ready():
	patrol_start_position = global_position
	center_position = global_position  # Assuming boss starts in center
	normal_y_position = global_position.y
	change_state(State.INACTIVE)
	_disable_walls()

func _physics_process(delta):
	if current_state == State.DEATH:
		return
		
	match current_state:
		State.INACTIVE:
			pass
		State.PATROL:
			_handle_patrol_state(delta)
		State.ATTACK_BALL:
			_handle_attack_ball_state(delta)
		State.ATTACK_INK:
			_handle_attack_ink_state(delta)
		State.VULNERABLE:
			_handle_vulnerable_state(delta)
	
	if current_state != State.INACTIVE and current_state != State.DEATH:
		move_and_slide()

func change_state(new_state: State):
	print("=== CHANGE STATE: ", State.keys()[new_state], " ===")
	current_state = new_state
	state_timer = 0.0
	
	# Update debug label
	if debug_label:
		debug_label.text = "State: " + str(State.keys()[new_state])
	
	match current_state:
		State.INACTIVE:
			print("Entering INACTIVE")
			velocity = Vector2.ZERO
			squid_body.play("idle")
			hurt_box.set_deferred("monitoring", false)
			hurt_box.set_deferred("monitorable", false)
		State.PATROL:
			print("Entering PATROL")
			squid_body.play("idle")
			hurt_box.set_deferred("monitoring", false)
			hurt_box.set_deferred("monitorable", false)
		State.ATTACK_BALL:
			print("Entering ATTACK_BALL, rounds reset")
			velocity = Vector2.ZERO
			ball_attack_rounds = 0
			saved_player_position = player.global_position
			print("Saved player pos: ", saved_player_position)
			squid_body.play("idle")
		State.ATTACK_INK:
			print("Entering ATTACK_INK")
			_enter_attack_ink_state()
		State.VULNERABLE:
			print("Entering VULNERABLE")
			_enter_vulnerable_state()
		State.DEATH:
			print("Entering DEATH")
			_enter_death_state()


func _handle_patrol_state(delta):
	# Move horizontally
	velocity.x = patrol_direction * PATROL_SPEED
	distance_traveled += PATROL_SPEED * delta
	
	# Check if reached patrol distance
	if ray_cast_left.is_colliding():
		print("Hit LEFT wall")
		patrol_direction = 1
		_start_next_attack_cycle()	
	if ray_cast_right.is_colliding():
		print("Hit RIGHT wall")
		patrol_direction = -1
		_start_next_attack_cycle()	


func _start_next_attack_cycle():
	print("Cycle step: ", attack_cycle_step)
	match attack_cycle_step:
		0:
			print("Next attack: BALL")
			change_state(State.ATTACK_BALL)
		1:
			print("Next attack: INK")
			change_state(State.ATTACK_INK)
		2:
			print("Next attack: BALL")
			change_state(State.ATTACK_BALL)
		3:
			print("Next attack: VULNERABLE")
			attack_cycle_step = 0
			change_state(State.VULNERABLE)
			return
	
	attack_cycle_step += 1
	print("Cycle step incremented → ", attack_cycle_step)


func _handle_attack_ball_state(delta):
	state_timer += delta
	
	if ball_attack_rounds < max_ball_rounds and state_timer >= BALL_ATTACK_INTERVAL:
		print("Spawning BALL projectiles...")
		_spawn_ball_projectiles()
		ball_attack_rounds += 1
		state_timer = 0.0
		if ball_attack_rounds < max_ball_rounds:
			saved_player_position = player.global_position
			print("New saved player pos: ", saved_player_position)
	
	if ball_attack_rounds >= max_ball_rounds:
		print("BALL attack finished, returning to PATROL")
		change_state(State.PATROL)


func _enter_attack_ink_state():
	target_x_position = player.global_position.x
	ink_movement_complete = false
	print("INK target X: ", target_x_position)
	squid_body.play("idle")


func _handle_attack_ink_state(_delta):
	if not ink_movement_complete:
		var distance_to_target = abs(global_position.x - target_x_position)
		
		if distance_to_target > 5.0:
			var direction = sign(target_x_position - global_position.x)
			velocity.x = direction * INK_MOVE_SPEED
		else:
			print("Reached target X for INK")
			global_position.x = target_x_position
			velocity.x = 0
			ink_movement_complete = true
			print("Movement complete, firing ink...")
	else:
		print("Firing INK projectile")
		_fire_ink_projectile()
		change_state(State.PATROL)


func _enter_vulnerable_state():
	velocity = Vector2.ZERO
	hit_this_vulnerable_cycle = false

	# Reset timer when actually starting vulnerability
	state_timer = 0.0

	# Activate hurtbox right away
	squid_body.play("idle")
	hurt_box.set_deferred("monitoring", true)
	hurt_box.set_deferred("monitorable", true)
	print("VULNERABLE ready, hurtbox active")

func _handle_vulnerable_state(delta):
	state_timer += delta
	
	# First, move horizontally toward the center if not already there
	if abs(global_position.x - center_position.x) > 5.0:
		var dir_x = sign(center_position.x - global_position.x)
		velocity.x = dir_x * 150   # adjust speed as needed
	else:
		velocity.x = 0

	# While vulnerable, stay down
	if state_timer < VULNERABLE_DURATION:
		velocity.y = VULNERABLE_MOVE_SPEED
		if ray_cast_down.is_colliding():
			velocity.y = 0
	else:
		# After duration, ascend back
		velocity.y = -VULNERABLE_MOVE_SPEED
		print("Ascending with vel.y=", velocity.y)
		if global_position.y <= normal_y_position + 5:
			print("Back to normal Y → returning to PATROL")
			global_position.y = normal_y_position
			velocity = Vector2.ZERO
			change_state(State.PATROL)

func take_damage(_damage_amount):
	print("TAKE DAMAGE called in state: ", State.keys()[current_state])
	if current_state == State.VULNERABLE and not hit_this_vulnerable_cycle:
		hit_this_vulnerable_cycle = true
		health -= 1
		health = max(0, health)
		progress_bar.value = health
		print("Boss health now: ", health, "/", max_health)
		
		if health <= 0:
			print("Health 0 → DEATH")
			change_state(State.DEATH)
		else:
			print("Hit animation")
			animation_player.stop()
			squid_body.play("hit")
			await squid_body.animation_finished


func _spawn_ball_projectiles():	
	for i in projectiles_per_round:
		var projectile = ball_projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position
		
		var direction = (saved_player_position - global_position).normalized()
		var angle_offset = (i - float(projectiles_per_round - 1) / 2) * 0.3
		direction = direction.rotated(angle_offset)
		
		if projectile.has_method("setup_projectile"):
			projectile.setup_projectile(direction)

func _fire_ink_projectile():	
	if ink_projectile_scene:
		var projectile = ink_projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position
		
		var direction = Vector2(0, 1)
		if projectile.has_method("setup_projectile"):
			projectile.setup_projectile(direction)


func _enter_death_state():
	velocity = Vector2.ZERO
	_disable_walls()
	hurt_box.queue_free()
	animation_player.stop()
	squid_body.play("death")
	print("=== BOSS DIED ===")
	await squid_body.animation_finished
		
	canvas_layer.queue_free()
	emit_signal("boss_died")

# ===== WALL MANAGEMENT =====

func _enable_walls():
	wall1.set_deferred("disabled", false)
	wall2.set_deferred("disabled", false)
	wall3.set_deferred("disabled", false)

func _disable_walls():
	wall1.set_deferred("disabled", true)
	wall2.set_deferred("disabled", true)
	wall3.set_deferred("disabled", true)

# ===== SIGNALS =====

func _on_dialogue_ended(_resource):
	GameManager.set_player_movable(true)
	DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)
	
	player_entered = true
	canvas_layer.visible = true
	progress_bar.max_value = max_health
	progress_bar.value = health
	
	_enable_walls()
	change_state(State.PATROL)
	
	print("Boss fight started!")

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not player_entered:
		GameManager.set_player_movable(false)

		var balloon_instance = boss_balloon_scene.instantiate()
		get_tree().current_scene.add_child(balloon_instance)

		# Connect dialogue finished signal once
		if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
			DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

		balloon_instance.start(boss_dialogue_resource, "p3_start")
		$PlayerDetector.queue_free()

func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_attack"):
		take_damage(1)
