extends CharacterBody2D

const VULNERABLE_DURATION = 7.0
const PROJECTILE_COUNT = 10

enum State { INACTIVE, FLOAT, ATTACK, DESCEND, VULNERABLE, ASCEND, DEATH }

@onready var player = get_parent().find_child("player")
@onready var ink: AnimatedSprite2D = $Pivot/ink
@onready var squid_body: AnimatedSprite2D = $Pivot/body
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hurt_box: HurtBox = $Pivot/HurtBox
@onready var progress_bar: ProgressBar = $CanvasLayer/VBoxContainer/ProgressBar
@onready var canvas_layer: CanvasLayer = $CanvasLayer

var current_state = State.INACTIVE
var boss_health = 100.0
var max_boss_health = 100.0
var state_timer = 0.0
var shots_fired = 0
var player_entered = 1

signal boss_died

func _ready() -> void:
	canvas_layer.visible = false
	progress_bar.max_value = max_boss_health
	progress_bar.value = boss_health

func _physics_process(delta: float) -> void:
	if current_state in [State.INACTIVE, State.DEATH]:
		return
	
	state_timer += delta
	
	match current_state:
		State.FLOAT:
			_float_state(delta)
		State.ATTACK:
			_attack_state()
		State.DESCEND:
			_descend_state(delta)
		State.VULNERABLE:
			_vulnerable_state(delta)
		State.ASCEND:
			_ascend_state(delta)

func _float_state(delta) -> void:
	# Idle at floating height
	var direct = global_position.direction_to(player.global_position)
	global_position.x += direct.x * 200 * delta
	
	squid_body.play("idle")
	
	# Start attack sequence
	_change_state(State.ATTACK)

func _attack_state() -> void:
	if shots_fired < PROJECTILE_COUNT:
		# Shoot projectile (AnimationPlayer triggers shooting)
		if not animation_player.is_playing():
			animation_player.play("attack")
			ink.play("attack")
			await ink.animation_finished
			shots_fired += 1
		return
	else:
		# After firing all projectiles, descend
		_change_state(State.DESCEND)	

func _descend_state(delta: float) -> void:
	animation_player.play("descend")
	await animation_player.animation_finished
	_change_state(State.VULNERABLE)

func _vulnerable_state(delta: float) -> void:
	velocity = Vector2.ZERO
	hurt_box.set_deferred("monitoring", true)
	hurt_box.set_deferred("monitorable", true)
	squid_body.play("idle")
	
	if state_timer >= VULNERABLE_DURATION:
		_change_state(State.ASCEND)

func _ascend_state(delta: float) -> void:
	animation_player.play("ascend")
	await animation_player.animation_finished
	shots_fired = 0
	_change_state(State.FLOAT)

func _change_state(new_state: State) -> void:
	current_state = new_state
	state_timer = 0.0
	
	match new_state:
		State.FLOAT:
			hurt_box.set_deferred("monitoring", false)
		State.ATTACK:
			hurt_box.set_deferred("monitoring", false)
		State.DESCEND:
			hurt_box.set_deferred("monitoring", false)
		State.VULNERABLE:
			hurt_box.set_deferred("monitoring", true)
		State.ASCEND:
			hurt_box.set_deferred("monitoring", false)
		State.DEATH:
			hurt_box.set_deferred("monitoring", false)
			squid_body.play("death")
			await squid_body.animation_finished
			emit_signal("boss_died")
			queue_free()

func take_damage(amount: float) -> void:
	if current_state != State.VULNERABLE:
		return
	
	boss_health -= amount
	progress_bar.value = boss_health
	squid_body.play("hit")
	await squid_body.animation_finished
	
	if boss_health <= 0:
		_change_state(State.DEATH)

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and player_entered == 1:
		player_entered -= 1
		canvas_layer.visible = true
		progress_bar.max_value = max_boss_health
		progress_bar.value = boss_health
		_change_state(State.ATTACK)

func _on_hurt_box_area_entered(area) -> void:
	print("=== HURTBOX HIT ===\tHit by area from: ", area.owner)
	
	if area.owner.is_in_group("player"):
		print("Valid player attack detected")
		take_damage(GameManager.strength)
