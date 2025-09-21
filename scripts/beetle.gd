extends CharacterBody2D

const WALK_SPEED = 65.0
const ATTACK_SPEED = 400.0
const JUMP_VELOCITY = -600.0
const WALK_DISTANCE = 200.0
const CHARGE_DURATION = 1.5
const VULNERABLE_DURATION = 3.0
const ATTACK_DURATION = 1.0
const STANDING_DURATION = 3.0

enum State { STAND, CRAWL, CHARGE, ATTACK, VULNERABLE }

@onready var player = get_parent().find_child("player")
@onready var hurt_box: HurtBox = $HurtBox
@onready var hit_box: Area2D = $HitBox
@onready var sprite_2d: AnimatedSprite2D = $Pivot/Sprite2D
@onready var pivot: Node2D = $Pivot
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player_detector: Area2D = $"Player Detector"

var current_state = State.STAND
var state_timer: float = 0.0
var distance_traveled: float = 0.0
var direction: float = 1.0
var is_player_in_range: bool = false
var has_jumped: bool = false
var player_was_hit: bool = false

var total_hits_taken: int = 0  # Track total hits across lifespan
var hit_this_vulnerable_cycle: bool = false  # Track if hit during current vulnerable state

func _ready() -> void:
	_change_state(State.STAND)

func _physics_process(delta: float) -> void:    
	match current_state:
		State.STAND:
			_stand_state(delta)
		State.CRAWL:
			_crawl_state(delta)
		State.CHARGE:
			_charge_state(delta)
		State.ATTACK:
			_attack_state(delta)
		State.VULNERABLE:
			_vulnerable_state(delta)

	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

func _stand_state(delta: float) -> void:
	velocity.x = 0
	state_timer += delta
	if state_timer >= STANDING_DURATION:
		if is_player_in_range:
			_change_state(State.CHARGE)
		else:
			pivot.scale.x = -direction
			_change_state(State.CRAWL)

func _crawl_state(delta: float) -> void:
	velocity.x = direction * WALK_SPEED

	distance_traveled += WALK_SPEED * delta

	if distance_traveled >= WALK_DISTANCE:
		distance_traveled = 0.0
		direction *= -1
		_change_state(State.STAND)

func _charge_state(delta: float) -> void:
	velocity.x = 0
	state_timer += delta
	if state_timer >= CHARGE_DURATION:
		$AudioStreamPlayer.play()
		_change_state(State.ATTACK)

	if player:
		pivot.scale.x = -sign(player.global_position.x - global_position.x)

func _attack_state(delta: float) -> void:
	state_timer += delta
	velocity.x = sign(player.global_position.x - global_position.x) * ATTACK_SPEED

	if is_on_floor() and not has_jumped:
		velocity.y = JUMP_VELOCITY
		has_jumped = true
		
	if state_timer >= ATTACK_DURATION:
		$AudioStreamPlayer2.play()
		if player_was_hit:
			if is_player_in_range:
				_change_state(State.STAND)
			else:
				_change_state(State.CRAWL)
		else:
			_change_state(State.VULNERABLE)

func _vulnerable_state(delta: float) -> void:
	velocity.x = 0
	state_timer += delta
	if state_timer >= VULNERABLE_DURATION:
		if is_player_in_range:
			_change_state(State.CHARGE)
		else:
			_change_state(State.STAND)

func _change_state(new_state) -> void:
	current_state = new_state
	state_timer = 0.0
	has_jumped = false
	player_was_hit = false
	
	# Reset the hit flag when entering a new vulnerable state
	if new_state == State.VULNERABLE:
		hit_this_vulnerable_cycle = false

	match current_state:
		State.STAND:
			hurt_box.set_deferred("monitoring", false)
			hit_box.set_deferred("monitoring", false)
			hurt_box.set_deferred("monitorable", false)
			hit_box.set_deferred("monitorable", false)
			sprite_2d.play("stand")
		State.CRAWL:
			hurt_box.set_deferred("monitoring", false)
			hit_box.set_deferred("monitoring", false)
			hurt_box.set_deferred("monitorable", false)
			hit_box.set_deferred("monitorable", false)
			sprite_2d.play("crawl")
		State.CHARGE:
			hurt_box.set_deferred("monitoring", false)
			hit_box.set_deferred("monitoring", false)
			hurt_box.set_deferred("monitorable", false)
			hit_box.set_deferred("monitorable", false)
			sprite_2d.play("charge")
		State.ATTACK:
			hurt_box.set_deferred("monitoring", false)
			hit_box.set_deferred("monitoring", true)
			hurt_box.set_deferred("monitorable", false)
			hit_box.set_deferred("monitorable", true)
			sprite_2d.play("attack")
			animation_player.play("attack")
		State.VULNERABLE:
			hurt_box.set_deferred("monitoring", true)
			hit_box.set_deferred("monitoring", false)
			hurt_box.set_deferred("monitorable", true)
			hit_box.set_deferred("monitorable", false)
			sprite_2d.play("vulnerable")

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body == player:
		is_player_in_range = true
		if current_state == State.STAND or current_state == State.CRAWL:
			_change_state(State.CHARGE)

func _on_player_detector_body_exited(body: Node2D) -> void:
	if body == player:
		is_player_in_range = false

func take_damage(_damage: float) -> void:
	# Only allow damage if in vulnerable state and hasn't been hit this cycle
	if current_state == State.VULNERABLE and not hit_this_vulnerable_cycle:
		hit_this_vulnerable_cycle = true  # Mark as hit this cycle
		total_hits_taken += 1  # Increment total hits
		
		animation_player.play("hurt")
		await animation_player.animation_finished
		
		# Check if beetle should die (after 2 total hits)
		if total_hits_taken >= 2:
			$AudioStreamPlayer3.play()
			await $AudioStreamPlayer3.finished
			queue_free()
		# If still alive, continue vulnerable state until timer finishes naturally

func _on_hit_box_area_entered(area) -> void:
	if current_state == State.ATTACK:
		if area.owner.is_in_group("player"):
			print("*** PLAYER'S HURTBOX WAS HIT ***")
			player_was_hit = true
			GameManager.take_damage(10.0)
			player._on_hurt_box_area_entered(null)
