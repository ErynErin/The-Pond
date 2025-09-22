extends CharacterBody2D

const WALK_SPEED = 50.0
const FOLLOW_SPEED = 200.0
const ATTACK_SPEED = 300.0
const WALK_DISTANCE = 200.0
const STANDING_DURATION = 3.0
const MAX_ATTACKS = 5

enum State { STAND, WALK, FOLLOW, ATTACK, COOLDOWN }

@onready var player = get_parent().find_child("player")
@onready var hurt_box: HurtBox = $HurtBox
@onready var hit_box: HitBox = $Pivot/HitBox
@onready var pivot: Node2D = $Pivot
@onready var sprite_2d: AnimatedSprite2D = $Pivot/Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player_detector: Area2D = $"Player Detector"
@onready var coin_scene = preload("res://scenes/Collectibles/coin.tscn")

var current_state = State.STAND
var state_timer: float = 0.0
var distance_traveled: float = 0.0
var direction: float = 1.0
var enemy_health = 30
var is_player_in_range: bool = false
var attack_count: int = 0

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
			_handle_attack_state(delta)
		State.COOLDOWN:
			_handle_cooldown_state()
	
	move_and_slide()

func _handle_stand_state():
	velocity = Vector2.ZERO
	sprite_2d.play("idle")
	
	if is_player_in_range:
		_change_state(State.FOLLOW)
	elif state_timer >= STANDING_DURATION:
		_flip_sprite()
		_change_state(State.WALK)

func _handle_walk_state(delta):
	velocity.x = direction * WALK_SPEED
	sprite_2d.play("idle")
	
	distance_traveled += abs(velocity.x) * delta
	
	if is_player_in_range:
		_change_state(State.FOLLOW)
		return
	
	if distance_traveled >= WALK_DISTANCE:
		direction *= -1
		_change_state(State.STAND)

func _handle_follow_state(delta):
	if not is_instance_valid(player):
		_change_state(State.STAND)
		return
	
	if not is_player_in_range:
		_change_state(State.STAND) 
		return
	
	var direct = global_position.direction_to(player.global_position)
	global_position.x += direct.x * FOLLOW_SPEED * delta
	if direct.x > 0:
		direction = 1
		_flip_sprite()
	else:
		direction = -1
		_flip_sprite()
	
	sprite_2d.play("idle")

func _handle_attack_state(delta):
	if is_instance_valid(player):
		var direct = global_position.direction_to(player.global_position)
		global_position.x += direct.x * FOLLOW_SPEED * delta
		if direct.x > 0:
			direction = 1
			_flip_sprite()
		else:
			direction = -1
			_flip_sprite()
	else:
		_change_state(State.COOLDOWN)

func _handle_cooldown_state():
	velocity = Vector2.ZERO
	sprite_2d.play("idle")
	
	if state_timer >= STANDING_DURATION:
		if is_player_in_range:
			_change_state(State.FOLLOW)
		else:
			_flip_sprite()
			_change_state(State.WALK)

func _perform_attack_sequence():
	for i in range(MAX_ATTACKS):
		if not is_instance_valid(player):
			_change_state(State.COOLDOWN)
			break
			
		# Play the attack animation
		sprite_2d.play("attack")
		animation_player.play("attack")
		
		# Wait for the animation to finish
		await animation_player.animation_finished
		
		# Stop velocity and wait a short time before the next attack
		velocity = Vector2.ZERO
		await get_tree().create_timer(0.2).timeout
	
	# After all attacks are done, change to cooldown state
	_change_state(State.COOLDOWN)

func _change_state(new_state: State):
	current_state = new_state
	state_timer = 0.0
	
	match new_state:
		State.WALK:
			distance_traveled = 0.0
		State.ATTACK:
			# Start the attack sequence when entering the attack state
			_perform_attack_sequence()
		State.COOLDOWN:
			velocity = Vector2.ZERO

func _flip_sprite():
	if direction > 0:
		pivot.scale.x = -1
	else:
		pivot.scale.x = 1

func _on_hurt(damage_amount: int = 1):
	enemy_health -= damage_amount
	animation_player.play("hurt")
	
	if enemy_health <= 0:
		sprite_2d.play("death")
		await sprite_2d.animation_finished
		
		for i in range(3):
			var coin_instance = coin_scene.instantiate()
			var offset = (i - 0.5) * 50
			coin_instance.global_position = global_position + Vector2(offset, 0)
			get_parent().add_child(coin_instance)
		
		queue_free()

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body == player:
		is_player_in_range = true

func _on_player_detector_body_exited(body: Node2D) -> void:
	if body == player:
		is_player_in_range = false

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body == player:
		_change_state(State.ATTACK)

func _on_hit_box_area_entered(area) -> void:
	if current_state == State.ATTACK:
		if area.owner.is_in_group("player"):
			GameManager.take_damage(10.0)
			player._on_hurt_box_area_entered(null)
