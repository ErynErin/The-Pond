extends CharacterBody2D

const WALK_SPEED = 50.0
const FOLLOW_SPEED = 200.0
const WALK_DISTANCE = 200.0
const STANDING_DURATION = 3.0
const MAX_ATTACKS = 5
const ATTACK_COOLDOWN = 3.0
const ATTACK_RANGE = 60.0

enum State { STAND, WALK, FOLLOW, ATTACK, COOLDOWN }

@onready var player = get_parent().find_child("player")
@onready var hurt_box: HurtBox = $HurtBox
@onready var hit_box: Area2D = $HitBox
@onready var pivot: Node2D = $Pivot
@onready var sprite_2d: AnimatedSprite2D = $Pivot/Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player_detector: Area2D = $"Player Detector"

var current_state = State.STAND
var state_timer: float = 0.0
var distance_traveled: float = 0.0
var direction: float = 1.0
var enemy_health = 30
var is_player_in_range: bool = false
var attack_count: int = 0
var start_position: Vector2

func _ready():
	start_position = global_position
	
	# Connect player detector signals
	player_detector.body_entered.connect(_on_player_detected)
	player_detector.body_exited.connect(_on_player_lost)

func _physics_process(delta):
	state_timer += delta
	
	match current_state:
		State.STAND:
			_handle_stand_state()
		State.WALK:
			_handle_walk_state(delta)
		State.FOLLOW:
			_handle_follow_state(delta)
		State.ATTACK:
			_handle_attack_state()
		State.COOLDOWN:
			_handle_cooldown_state()
	
	move_and_slide()

func _handle_stand_state():
	velocity = Vector2.ZERO
	sprite_2d.play("idle")
	
	if is_player_in_range:
		_change_state(State.FOLLOW)
	elif state_timer >= STANDING_DURATION:
		_change_state(State.WALK)

func _handle_walk_state(delta):
	velocity.x = direction * WALK_SPEED
	sprite_2d.play("idle")
	
	# Update distance traveled
	distance_traveled += abs(velocity.x) * delta
	
	# Check if player is detected
	if is_player_in_range:
		_change_state(State.FOLLOW)
		return
	
	# Check if walked the required distance
	if distance_traveled >= WALK_DISTANCE:
		direction *= -1  # Reverse direction
		_flip_sprite()
		_change_state(State.STAND)

func _handle_follow_state(delta):
	if not player:
		_change_state(State.STAND)
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# If close enough to attack
	if distance_to_player <= ATTACK_RANGE:
		_change_state(State.ATTACK)
		return
	
	# If player is out of detection range
	if not is_player_in_range:
		_change_state(State.STAND)
		return
	
	# Move towards player
	var direction_to_player = (player.global_position - global_position).normalized()
	velocity = direction_to_player * FOLLOW_SPEED
	
	# Update sprite direction
	if direction_to_player.x > 0:
		direction = 1
	elif direction_to_player.x < 0:
		direction = -1
	_flip_sprite()
	
	sprite_2d.play("idle")

func _handle_attack_state():
	# Fish can still move during attacks if needed
	# velocity is not set to zero here to allow movement during attacks
	
	# Start attacking if we haven't started yet
	if attack_count == 0:
		_perform_attack()

func _handle_cooldown_state():
	velocity = Vector2.ZERO
	sprite_2d.play("idle")
	
	if state_timer >= ATTACK_COOLDOWN:
		attack_count = 0
		if is_player_in_range:
			_change_state(State.FOLLOW)
		else:
			_change_state(State.STAND)

func _perform_attack():
	attack_count += 1
	animation_player.play("attack")
	
	# Wait for attack animation to finish, then check if we need more attacks
	await animation_player.animation_finished
	
	if attack_count < MAX_ATTACKS:
		# Continue attacking
		_perform_attack()
	else:
		# Finished all attacks, go to cooldown
		_change_state(State.COOLDOWN)

func _change_state(new_state: State):
	current_state = new_state
	state_timer = 0.0
	
	match new_state:
		State.WALK:
			distance_traveled = 0.0
		State.ATTACK:
			attack_count = 0

func _flip_sprite():
	if direction > 0:
		pivot.scale.x = 1
	else:
		pivot.scale.x = -1

func _on_player_detected(body):
	if body == player:
		is_player_in_range = true

func _on_player_lost(body):
	if body == player:
		is_player_in_range = false

func _on_hurt(damage_amount: int = 1):
	enemy_health -= damage_amount
	animation_player.play("hurt")
	
	if enemy_health <= 0:
		sprite_2d.play("death")
		await sprite_2d.animation_finished
		queue_free()
