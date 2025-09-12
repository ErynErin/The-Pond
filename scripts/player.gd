extends CharacterBody2D

const JUMP_VELOCITY = -600.0
const MAX_JUMPS = 2

@onready var sword: Node2D = $Sword
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var pivot: Node2D = $Pivot
@onready var animated_sprite: AnimatedSprite2D = $Pivot/AnimatedSprite2D

var jumps_left: int = MAX_JUMPS

func _ready():
	set_physics_process(true)
	GameManager.player_died.connect(_on_player_died)

func _physics_process(delta: float) -> void:
	var SPEED = GameManager.speed
	if GameManager.current_health <= 0 or not GameManager.can_move:
		return
	
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		# On floor: reset jumps
		jumps_left = MAX_JUMPS

	# Handle jump (double jump support)
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		$JumpAudio.play()
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1

	# Handle sprint
	if Input.is_action_pressed("Sprint") and Input.get_axis("left", "right"):
		velocity.x = move_toward(velocity.x, (velocity.x * 2), SPEED)

	# Flip character and sword
	if direction < 0:
		pivot.scale.x = direction
		sword.scale.x = direction
	elif direction > 0:
		pivot.scale.x = direction
		sword.scale.x = direction

	# Animation
	if is_on_floor():
		if Input.is_action_just_pressed("attack"):
			sword.sword_attack()
		elif direction == 0:
			animated_sprite.play("idle")
		elif Input.is_action_pressed("Sprint"):
			animated_sprite.play("run")
		else:
			animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")
		
	move_and_slide()

func take_damage(damage: float):
	GameManager.take_damage(damage)

func _on_hurt_box_area_entered(_area) -> void:
	animation_player.play("hurt")

func _on_player_died():
	$DeathAudio.play()
	set_physics_process(false)
	animated_sprite.play("death")
	GameManager.player_died.disconnect(_on_player_died)
	await animated_sprite.animation_finished
	GameManager.current_health = 100.0
	get_tree().reload_current_scene()
