extends CharacterBody2D

const WALK_SPEED = 500.0
const DASH_SPEED = 1000.0
const DASH_DISTANCE_THRESHOLD = 700.0
const CHARGE_DURATION = 1.0  # Duration of charge animation before dash
const ATTACK_DURATION = 1.0
const REST_DURATION = 2.0
const ATTACK_DISTANCE_THRESHOLD = 400.0

enum State { INACTIVE, WALK, DASH, CHARGE, ATTACK, REST, DEATH }

@onready var player = get_parent().find_child("player")
@onready var animated_sprite: AnimatedSprite2D = $Node2D/AnimatedSprite2D
@onready var hurt_box: HurtBox = $Node2D/HurtBox
@onready var hit_box: HitBox = $Node2D/HitBox
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer
@onready var progress_bar: ProgressBar = $CanvasLayer/VBoxContainer/ProgressBar
@onready var label: Label = $Label
@onready var node_2d: Node2D = $Node2D

var current_state = State.WALK
var boss_health = 100.0
var max_boss_health = 100.0
var state_timer = 0.0

func _ready() -> void:
	_change_state(State.INACTIVE)

func start() -> void:
	progress_bar.max_value = max_boss_health
	progress_bar.value = boss_health
	$CanvasLayer.visible = true
	_change_state(State.CHARGE)
	print("starting...")

func _physics_process(delta: float) -> void:
	if current_state == State.DEATH:
		return
		
	state_timer += delta
	
	if current_state == State.WALK or current_state == State.DASH:
		_check_attack_range()

	match current_state:
		State.INACTIVE:
			_handle_inactive_state(delta)
		State.WALK:
			_walk_state(delta)
		State.DASH:
			_dash_state(delta)
		State.CHARGE:
			_charge_state(delta)
		State.ATTACK:
			_handle_attack_state(delta)
		State.REST:
			_rest_state(delta)

	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()

func _handle_inactive_state(_delta):
	velocity.x = 0
	animated_sprite.play("idle_100")

func _check_attack_range():
	var dist = global_position.distance_to(player.global_position)
	if dist < ATTACK_DISTANCE_THRESHOLD:
		_change_state(State.ATTACK)

func _handle_attack_state(_delta):
	velocity.x = 0
	
	var direction = player.global_position.x - global_position.x
	if direction > 0:
		node_2d.scale.x = -1 # Face Right
	elif direction < 0:
		node_2d.scale.x = 1  # Face Left
			
	if state_timer >= ATTACK_DURATION:
		_change_state(State.REST)
		
func _walk_state(_delta: float) -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Check if should charge (far enough to dash)
	if distance_to_player > DASH_DISTANCE_THRESHOLD:
		print("Player far, switching to CHARGE (to prepare dash)")
		_change_state(State.CHARGE)
		return
	
	if distance_to_player < ATTACK_DISTANCE_THRESHOLD:
		_change_state(State.ATTACK)
		return
	
	# Normal walking movement
	var direction = (player.global_position - global_position).normalized()
	velocity.x = direction.x * WALK_SPEED
	
	# Flip sprite to face player
	if direction.x > 0:
		node_2d.scale.x = -1
	elif direction.x < 0:
		node_2d.scale.x = 1

func _dash_state(_delta: float) -> void:
	var direction = (player.global_position - global_position).normalized()
	velocity.x = direction.x * DASH_SPEED
	
	# Flip sprite to face player
	if direction.x > 0:
		node_2d.scale.x = -1
	elif direction.x < 0:
		node_2d.scale.x = 1
	
	# Check if close enough to stop dashing
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player < -400:  # Stop a bit before threshold
		print("Dash complete, switching to WALK")
		_change_state(State.WALK)

func _charge_state(_delta: float) -> void:
	velocity.x = 0  # Stop movement during charge
	
	# Face the player during charge
	var direction = player.global_position.x - global_position.x
	if direction > 0:
		node_2d.scale.x = -1
	elif direction < 0:
		node_2d.scale.x = 1
	
	# Transition to dash after charge duration
	if state_timer >= CHARGE_DURATION:
		print("Charge complete, switching to DASH")
		_change_state(State.DASH)

func _attack_state(_delta: float) -> void:
	velocity.x = 0
	if state_timer >= ATTACK_DURATION:
		_change_state(State.REST)

func _rest_state(_delta: float) -> void:
	velocity.x = 0  # Stop movement during rest
	
	if state_timer >= REST_DURATION:
		print("Rest complete, switching to WALK")
		_change_state(State.WALK)

func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return

	current_state = new_state
	state_timer = 0.0
	
	label.text = State.keys()[new_state]
	print("Switched to State: ", State.keys()[new_state])
	
	match current_state:
		State.WALK:
			_set_hitboxes(false, false)
			_play_animation_for_health_state("walk")
			animation_player.play("RESET")
		State.ATTACK:
			_set_hitboxes(false, true) # Hitbox enabled
			_play_animation_for_health_state("attack")
		State.REST:
			_set_hitboxes(true, false) # Vulnerable
			_play_animation_for_health_state("idle")
		State.CHARGE:
			_set_hitboxes(false, false)
			_play_animation_for_health_state("charge")
			animation_player.play("RESET")
		State.DASH:
			_set_hitboxes(false, false)
			_play_animation_for_health_state("dash")
			animation_player.play("RESET")
		State.DEATH:
			_set_hitboxes(false, false)
			animation_player.play("RESET")
			animated_sprite.play("death")

func _set_hitboxes(is_hurtbox_enabled: bool, is_hitbox_enabled: bool) -> void:
	hurt_box.set_deferred("monitoring", is_hurtbox_enabled)
	hurt_box.set_deferred("monitorable", is_hurtbox_enabled)
	hit_box.set_deferred("monitoring", is_hitbox_enabled)
	hit_box.set_deferred("monitorable", is_hitbox_enabled)

func take_damage(damage: float) -> void:
	boss_health -= damage
	boss_health = max(0, boss_health)
	progress_bar.value = boss_health
	
	if boss_health <= 0:
		print("Health depleted, switching to DEATH")
		_change_state(State.DEATH)
		$CanvasLayer.visible = false
		hurt_box.queue_free()
		hit_box.queue_free()
	else:
		animation_player.play("hurt")

func _play_animation_for_health_state(action: String) -> void:
	var health_percent = boss_health
	var suffix = ""
	
	if health_percent <= 25:
		suffix = "_25"
	elif health_percent <= 50:
		suffix = "_50" 
	elif health_percent <= 75:
		suffix = "_75"
	else:
		suffix = "_100"
		
	if action == "attack":
		animation_player.play("attack")
	
	if action == "attack" and (suffix == "_25" or suffix == "_50"):
		animated_sprite.play("charge" + suffix)
		return
	elif action == "walk" and (suffix == "_25" or suffix == "_50"):
		animated_sprite.play("dash" + suffix)
		return
	
	var animation_name = action + suffix
	print("Playing animation: ", animation_name)
	animated_sprite.play(animation_name)

func _on_hurt_box_area_entered(area) -> void:
	if area.owner.is_in_group("player"):
		print("Valid player attack detected")
		take_damage(GameManager.strength)

func _on_hit_box_area_entered(area) -> void:	
	if area.owner.is_in_group("player"):
		print("Player hit! Waiting 2 seconds to check if still in hitbox...")
		await get_tree().create_timer(3).timeout
		
		var distance = global_position.distance_to(player.global_position)
		
		if distance < ATTACK_DISTANCE_THRESHOLD:
			_change_state(State.ATTACK)

func _on_timer_timeout() -> void:	
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
