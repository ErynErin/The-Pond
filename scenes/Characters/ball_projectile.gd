extends CharacterBody2D

var speed = 500.0
var ball_projectile: String = "ball_projectile"

func setup_projectile(direction: Vector2):
	velocity = direction * speed
	get_tree().create_timer(4).timeout.connect(queue_free)

func _physics_process(_delta):
	move_and_slide()
