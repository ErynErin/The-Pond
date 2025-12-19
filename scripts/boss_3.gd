extends CharacterBody2D

enum State { INACTIVE, IDLE, CHASE, LIGHTS_OFF, ATTACK, DEATH }

# Constants
const PATROL_SPEED = 100.0
const CHASE_SPEED = 300.0
const JUMP_VELOCITY = -700.0
const IDLE_DURATION = 4.0
const CHASE_DURATION = 5.0
const LIGHTS_OFF_DURATION = 15.0
const ATTACK_DURATION = 1.0

# Attack and detection ranges
const ATTACK_RANGE = 250.0

# Node references
@onready var animated_sprite = $SpriteNode/AnimatedSprite2D
@onready var back_hurtbox = $SpriteNode/BackHitbox
@onready var light_detection = $SpriteNode/LightDetectionArea
@onready var light_detection_shape = $SpriteNode/LightDetectionArea/CollisionShape2D
@onready var anglerfish_light = $SpriteNode/AnglerfishLight
@onready var progress_bar: ProgressBar = $CanvasLayer/VBoxContainer/ProgressBar 
@onready var canvas_layer: CanvasLayer = $CanvasLayer
var player
var wall_ray

@onready var canvas_modulate = get_parent().find_child("Lighting")

# State variables
var current_state = State.INACTIVE
var state_before_attack = State.CHASE
var player_entered = false
var state_timer = 0.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var player_found = false
var distance_traveled = 0

# Boss stats
@export var max_hp = 100
var current_hp = max_hp
const DAMAGE_PER_HIT = 25

# Attack cycle tracking
var chase_cycle_count = 0
const MAX_CHASE_CYCLES = 2

# Patrol variables
var patrol_start_position: Vector2
var patrol_direction = 1
var patrol_range = 700

# Player hiding state
var player_is_hidden = false

# Attack cooldown
var attack_cooldown = false
var lights_off_timer = 0.0

# Lights state
var lights_on = true

func _ready():
	progress_bar.value = current_hp
	
	# Find player
	player = get_parent().find_child("player")
	
	# Initially hide anglerfish light
	anglerfish_light.enabled = false
	
	# Setup raycasts
	setup_raycasts()
	
	# Set initial light detector size
	update_light_detector_size(true)
	
	# Start in INACTIVE state
	change_state(State.INACTIVE)

func setup_raycasts():
	if not has_node("WallRaycast"):
		wall_ray = RayCast2D.new()
		wall_ray.name = "WallRaycast"
		add_child(wall_ray)
		wall_ray.target_position = Vector2(150, 0)
		wall_ray.enabled = true
		wall_ray.collision_mask = 1

func _physics_process(delta):
	if current_state == State.DEATH:
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Check for attack range in all states except INACTIVE, ATTACK, and DEATH
	if current_state in [State.CHASE, State.LIGHTS_OFF]:
		check_attack_range()
	
	match current_state:
		State.INACTIVE:
			_handle_inactive_state(delta)
		State.IDLE:
			_handle_idle_state(delta)
		State.CHASE:
			_handle_chase_state(delta)
		State.LIGHTS_OFF:
			_handle_lights_off_state(delta)
		State.ATTACK:
			_handle_attack_state(delta)
	
	# Update sprite direction
	if velocity.x != 0:
		$SpriteNode.scale.x = -1 if velocity.x > 0 else 1
		update_raycast_direction()
	
	move_and_slide()

func update_raycast_direction():
	if velocity.x == 0 or not wall_ray:
		return
	
	var direction = sign(velocity.x)
	wall_ray.target_position = Vector2(150 * direction, 0)
	wall_ray.force_raycast_update()

func change_state(new_state: State):
	if current_state == new_state:
		return
	
	# Exit current state logic
	if current_state == State.LIGHTS_OFF and new_state != State.ATTACK:
		# Huwag i-on ang lights kung lilipat lang sa ATTACK
		if new_state != State.ATTACK:
			turn_lights_on()
	
	current_state = new_state
	state_timer = 0.0 # To be used for the animation/duration of the state itself
	
	print("=== CHANGE STATE: ", State.keys()[new_state], " ===")
	
	patrol_range = randf_range(700, 1200)
	
	# Exit current state
	match current_state:
		State.LIGHTS_OFF:
			if new_state != State.LIGHTS_OFF:
				turn_lights_on()
	
	current_state = new_state
	state_timer = 0.0
	
	# Enter new state
	match current_state:
		State.INACTIVE:
			print("Entering INACTIVE")
			velocity.x = 0
			animated_sprite.play("idle")
			back_hurtbox.set_deferred("monitoring", false)
			back_hurtbox.set_deferred("monitorable", false)
			
			# Check current direction against wall
			if wall_ray and wall_ray.is_colliding() and sign(wall_ray.target_position.x) == patrol_direction:
				patrol_direction *= -1
		State.IDLE:
			print("Entering IDLE")
			velocity.x = 0
			animated_sprite.play("idle")
			# Enable back hitbox - vulnerable state
			back_hurtbox.set_deferred("monitoring", true)
			back_hurtbox.set_deferred("monitorable", true)
		State.CHASE:
			print("Entering CHASE")
			animated_sprite.play("run")
			# Disable back hitbox - not vulnerable
			back_hurtbox.set_deferred("monitoring", false)
			back_hurtbox.set_deferred("monitorable", false)
		State.LIGHTS_OFF:
			print("Entering LIGHTS_OFF")
			turn_lights_off()
			# Disable back hitbox
			back_hurtbox.set_deferred("monitoring", false)
			back_hurtbox.set_deferred("monitorable", false)
		State.ATTACK:
			print("Entering ATTACK")
			velocity.x = 0
			animated_sprite.play("attack")
		State.DEATH:
			print("Entering DEATH")
			_enter_death_state()

# ============================================================
# STATE: INACTIVE
# ============================================================
func _handle_inactive_state(delta):
	velocity.x = patrol_direction * PATROL_SPEED

	# Check patrol boundaries
	distance_traveled += velocity.x * delta
	
	if abs(distance_traveled) >= patrol_range:
		distance_traveled = 0.0
		patrol_direction *= -1
		if not player_entered:
			change_state(State.IDLE)

	# Check for walls
	if wall_ray and wall_ray.is_colliding():
		patrol_direction *= -1

	if is_on_floor():
		animated_sprite.play("run")

	# Enter combat if player is detected and visible
	if player_entered and not player_is_hidden:
		print("player detected → IDLE")
		change_state(State.CHASE)


# ============================================================
# STATE: IDLE
# ============================================================
func _handle_idle_state(delta):
	state_timer += delta
	velocity.x = 0
	animated_sprite.play("idle")

	if state_timer < IDLE_DURATION:
		return

	# --- CHECK VISIBILITY ---
	if player_is_hidden:
		print("Player hiding → INACTIVE")
		change_state(State.INACTIVE)
		return
	
	if not player_entered:
		print("Player left → INACTIVE")
		change_state(State.INACTIVE)
		return

	# --- CONTINUE PHASE LOOP ---
	chase_cycle_count += 1
	print("Idle complete. Chase cycle:", chase_cycle_count)

	if chase_cycle_count >= MAX_CHASE_CYCLES:
		print("Max cycles reached → LIGHTS_OFF")
		chase_cycle_count = 0
		change_state(State.LIGHTS_OFF)
	else:
		change_state(State.CHASE)


# ============================================================
# STATE: CHASE
# ============================================================
func _handle_chase_state(delta):
	state_timer += delta
	
	if not player:
		return
	
	# Calculate direction to player
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * CHASE_SPEED
	
	# Check for walls to jump over
	var wall_ahead = wall_ray and wall_ray.is_colliding()
	
	if wall_ahead and is_on_floor():
		velocity.y = JUMP_VELOCITY
		animated_sprite.play("jump")
	elif is_on_floor():
		animated_sprite.play("run")
	
	if state_timer >= CHASE_DURATION:
		print("Chase finished → IDLE")
		change_state(State.IDLE)

# ============================================================
# STATE: LIGHTS_OFF
# ============================================================
func _handle_lights_off_state(delta):
	lights_off_timer += delta
	
	# If player is hidden, become inactive patrol
	if player_is_hidden:
		velocity.x = patrol_direction * PATROL_SPEED * 0.5
		
		# Check patrol boundaries
		distance_traveled += velocity.x * delta
		
		if abs(distance_traveled) >= patrol_range:
			distance_traveled = 0.0
			patrol_direction *= -1
			if not player_entered:
				change_state(State.IDLE)
		
		if wall_ray and wall_ray.is_colliding():
			patrol_direction *= -1
	else:
		# Chase player if not hidden
		if player:
			var direction = sign(player.global_position.x - global_position.x)
			velocity.x = direction * CHASE_SPEED * 0.8
			
			var wall_ahead = wall_ray and wall_ray.is_colliding()
			if wall_ahead and is_on_floor():
				velocity.y = JUMP_VELOCITY
	
	animated_sprite.play("run")
	
	# Timer ends regardless of player hiding
	if lights_off_timer >= LIGHTS_OFF_DURATION:
		print("Lights off ended → IDLE")
		change_state(State.IDLE)

# ============================================================
# STATE: ATTACK
# ============================================================
func _handle_attack_state(delta):
	state_timer += delta
	velocity.x = 0
	
	if state_before_attack == State.LIGHTS_OFF:
		lights_off_timer += delta

	if state_timer >= ATTACK_DURATION:
		print("Attack finished → Returning to ", State.keys()[state_before_attack])
		current_state = state_before_attack
		state_timer = 0.0
		GameManager.set_player_movable(true)
		animated_sprite.play("run")

# ============================================================
# ATTACK RANGE CHECK
# ============================================================
func check_attack_range():
	# Don't attack if on cooldown, player is hidden, or player doesn't exist
	if attack_cooldown or player_is_hidden or not is_instance_valid(player):
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	if distance < ATTACK_RANGE:
		#print("Player in attack range (", distance, ") → ATTACK")
		trigger_attack(player)

# ============================================================
# LIGHTS CONTROL
# ============================================================
func turn_lights_off():
	print("Lights OFF")
	lights_on = false
	
	if canvas_modulate:
		canvas_modulate.color = Color.DIM_GRAY
	
	anglerfish_light.enabled = true
	anglerfish_light.energy = 1.5
	anglerfish_light.texture_scale = 3.0
	
	# Make light detector smaller
	update_light_detector_size(false)

func turn_lights_on():
	print("Lights ON")
	lights_on = true
	
	if canvas_modulate:
		canvas_modulate.color = Color.WHITE
	
	anglerfish_light.enabled = false
	
	# Make light detector bigger
	update_light_detector_size(true)

func update_light_detector_size(lights_on_state: bool):
	if not light_detection_shape:
		return
	
	var shape = light_detection_shape.shape
	if lights_on_state:
		shape.size = Vector2(2900, 1425)
	else:
		shape.size = Vector2(975, 1425)

func _on_light_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and player_entered:
		player_entered = false
		print("Player left")

# ============================================================
# DAMAGE SYSTEM
# ============================================================
func take_damage(damage_amount: int):
	current_hp -= damage_amount
	current_hp = max(0, current_hp)
	progress_bar.value = current_hp
	
	print("Boss took damage:", damage_amount, "HP:", current_hp, "/", max_hp)
	
	# Visual feedback
	animated_sprite.modulate = Color.RED
	get_tree().create_timer(0.1).timeout.connect(func(): 
		if animated_sprite:
			animated_sprite.modulate = Color.WHITE
	)
	
	if current_hp <= 0:
		print("Boss defeated")
		change_state(State.DEATH)

func _enter_death_state():
	velocity = Vector2.ZERO
	turn_lights_on()
	animated_sprite.play("death")
	set_physics_process(false)
	
	# Disable hitboxes
	back_hurtbox.set_deferred("monitoring", false)
	back_hurtbox.set_deferred("monitorable", false)
	light_detection.set_deferred("monitoring", false)
	light_detection.set_deferred("monitorable", false)
	
	print("=== BOSS DIED ===")

# ============================================================
# ATTACK SYSTEM
# ============================================================
func _on_back_hitbox_area_entered(area: Area2D) -> void:
	if current_state == State.IDLE and area.owner.name == "Sword":
		take_damage(DAMAGE_PER_HIT)

func trigger_attack(player_body):
	if attack_cooldown:
		return
	
	attack_cooldown = true
	state_before_attack = current_state
	
	# Deal damage
	if player_body.has_method("take_damage"):
		GameManager.set_player_movable(false)
		player_body.take_damage(10)
	
	# Change to attack state
	change_state(State.ATTACK)
	
	# Reset cooldown
	get_tree().create_timer(3).timeout.connect(func(): attack_cooldown = false)

# ============================================================
# PLAYER HIDING SYSTEM
# ============================================================
func set_player_hidden(h: bool):
	player_is_hidden = h
	print("Player hidden state:", h)

# ============================================================
# BOSS FIGHT TRIGGER
# ============================================================
func _on_light_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not player_entered:
		player_entered = true
		print("Player entered")
		canvas_layer.visible = true 
		change_state(State.CHASE)
