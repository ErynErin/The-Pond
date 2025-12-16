extends CharacterBody2D

const WALK_SPEED = 100.0
const DASH_SPEED = 700.0
const DASH_DISTANCE_THRESHOLD = 700.0
const DASH_DURATION = 0.5
const CHARGE_DURATION = 1.5  # Duration of charge animation before dash
const ATTACK_DURATION = 1.5  # Duration of single attack
const REST_DURATION = 3.0
const ATTACK_DISTANCE_THRESHOLD = 200.0  # Distance to trigger attack

enum State { INACTIVE, WALK, DASH, CHARGE, ATTACK, REST, DEATH }

@onready var player = get_parent().find_child("player")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_box: Area2D = $HurtBox
@onready var hit_box: Area2D = $HitBox
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer
@onready var progress_bar: ProgressBar = $CanvasLayer/VBoxContainer/ProgressBar
@onready var canvas_layer: CanvasLayer = $CanvasLayer

var current_state = State.INACTIVE
var boss_health = 100.0
var max_boss_health = 100.0
var state_timer = 0.0
var player_entered = 1

signal boss_died

func _ready() -> void:
	canvas_layer.visible = false
	progress_bar.max_value = max_boss_health
	progress_bar.value = boss_health
	current_state = State.INACTIVE

func _physics_process(delta: float) -> void:
	if current_state == State.DEATH or current_state == State.INACTIVE:
		return
		
	state_timer += delta
	
	match current_state:
		State.WALK:
			_walk_state(delta)
		State.DASH:
			_dash_state(delta)
		State.CHARGE:
			_charge_state(delta)
		State.ATTACK:
			_attack_state(delta)
		State.REST:
			_rest_state(delta)

	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()

func _walk_state(_delta: float) -> void:
	if not is_instance_valid(player):
		print("Player not found, stopping movement")
		velocity.x = 0
		return
		
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Check if should charge (far enough to dash)
	if distance_to_player > DASH_DISTANCE_THRESHOLD:
		print("Player far, switching to CHARGE (to prepare dash)")
		_change_state(State.CHARGE)
		return
	
	if distance_to_player < ATTACK_DISTANCE_THRESHOLD:
		print("Player in range, switching to ATTACK")
		_change_state(State.ATTACK)
		return
	
	# Normal walking movement
	var direction = (player.global_position - global_position).normalized()
	velocity.x = direction.x * WALK_SPEED
	
	# Flip sprite to face player
	if direction.x > 0:
		animated_sprite.flip_h = true
	elif direction.x < 0:
		animated_sprite.flip_h = false

func _dash_state(_delta: float) -> void:
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		return
	var direction = (player.global_position - global_position).normalized()
	velocity.x = direction.x * DASH_SPEED
	
	# Flip sprite to face player
	if direction.x > 0:
		animated_sprite.flip_h = true
	elif direction.x < 0:
		animated_sprite.flip_h = false
	
	# Check if close enough to stop dashing
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player < 300:  # Stop a bit before threshold
		print("Dash complete, switching to WALK")
		_change_state(State.WALK)

func _charge_state(_delta: float) -> void:
	$AudioStreamPlayer2.play()
	velocity.x = 0  # Stop movement during charge
	
	# Face the player during charge
	if is_instance_valid(player):
		var direction = player.global_position.x - global_position.x
		if direction > 0:
			animated_sprite.flip_h = true
		elif direction < 0:
			animated_sprite.flip_h = false
	
	# Transition to dash after charge duration
	if state_timer >= CHARGE_DURATION:
		print("Charge complete, switching to DASH")
		_change_state(State.DASH)

func _attack_state(_delta: float) -> void:
	$AudioStreamPlayer2.play()
	velocity.x = 0
	
	# Ensure hitbox is active during attack
	_set_hitboxes(false, true)
	
	if state_timer >= ATTACK_DURATION:
		_change_state(State.REST)

func _rest_state(_delta: float) -> void:
	$AudioStreamPlayer2.play()
	velocity.x = 0  # Stop movement during rest
	
	if state_timer >= REST_DURATION:
		print("Rest complete, switching to WALK")
		_change_state(State.WALK)

func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return

	var previous_state = current_state
	current_state = new_state
	state_timer = 0.0
	
	print("=== STATE CHANGE ===\tFrom: ", previous_state, " To: ", current_state)
	
	timer.stop()
	
	match current_state:
		State.WALK:
			_set_hitboxes(true, false)
			_play_animation_for_health_state("walk")
			
		State.DASH:
			_set_hitboxes(false, false)
			_play_animation_for_health_state("dash")
			
		State.CHARGE:
			_set_hitboxes(false, false)
			_play_animation_for_health_state("charge")
			
		State.ATTACK:
			_set_hitboxes(false, true)
			_play_animation_for_health_state("attack")
			
		State.REST:
			_set_hitboxes(true, false)
			_play_animation_for_health_state("idle")
			
		State.DEATH:
			_set_hitboxes(false, false)
			animated_sprite.play("death")
			print("=== BOSS DIED ===")
			# Emit the signal to notify other nodes of the boss's death
			await animated_sprite.animation_finished
			emit_signal("boss_died")

func _set_hitboxes(is_hurtbox_enabled: bool, is_hitbox_enabled: bool) -> void:
	hurt_box.set_deferred("monitoring", is_hurtbox_enabled)
	hurt_box.set_deferred("monitorable", is_hurtbox_enabled)
	hit_box.set_deferred("monitoring", is_hitbox_enabled)
	hit_box.set_deferred("monitorable", is_hitbox_enabled)
	print("Hitboxes updated - Hurtbox: ", is_hurtbox_enabled, " Hitbox: ", is_hitbox_enabled)

func take_damage(damage: float) -> void:
	boss_health -= damage
	boss_health = max(0, boss_health)
	progress_bar.value = boss_health
	
	if boss_health <= 0:
		print("Health depleted, switching to DEATH")
		_change_state(State.DEATH)
	else:
		animation_player.play("hurt")

func _play_animation_for_health_state(action: String) -> void:
	if action == "attack":
		animated_sprite.play("attack")
		return
	elif action == "walk":
		animated_sprite.play("run")
		return
	
	var animation_name = action
	print("Playing animation: ", animation_name)
	animated_sprite.play(animation_name)

func _on_hurt_box_area_entered(area) -> void:
	print("=== HURTBOX HIT ===\tHit by area from: ", area.owner)
	
	if area.owner.is_in_group("player"):
		print("Valid player attack detected")
		take_damage(GameManager.strength)

func _on_hit_box_area_entered(area) -> void:	
	if area.owner.is_in_group("player"):
		print("Player hit! Waiting 0.9 seconds to check if still in hitbox...")
		await get_tree().create_timer(0.9).timeout
		
		# Check if the player's area is still overlapping with our hitbox
		_set_hitboxes(true, true)
		var overlapping_areas = hit_box.get_overlapping_areas()
		var player_still_in_hitbox = false
		_set_hitboxes(false, false)
		
		for overlapping_area in overlapping_areas:
			if overlapping_area.owner.is_in_group("player"):
				player_still_in_hitbox = true
				break
		
		if player_still_in_hitbox:
			print("Player still in hitbox after delay - dealing 15 damage")
			GameManager.take_damage(15.0)
			if area.owner.has_method("_on_hurt_box_area_entered"):
				area.owner._on_hurt_box_area_entered(null)
		else:
			print("Player escaped hitbox - no damage dealt")
	else:
		print("Non-player collision, ignoring")

func _on_timer_timeout() -> void:
	print("=== TIMER TIMEOUT ===\tCurrent state: ", current_state)
	
	match current_state:
		State.ATTACK:
			print("Attack complete, switching to REST")
			_change_state(State.REST)
			
		State.DASH:
			print("Dash duration complete, switching to WALK")
			_change_state(State.WALK)
			
		State.REST:
			print("Rest complete, switching to WALK")
			_change_state(State.WALK)

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body == player and player_entered == 1:
		player_entered -= 1
		$AudioStreamPlayer.play()
		canvas_layer.visible = true
		progress_bar.max_value = max_boss_health
		progress_bar.value = boss_health
		timer.timeout.connect(_on_timer_timeout)
		_change_state(State.WALK)
