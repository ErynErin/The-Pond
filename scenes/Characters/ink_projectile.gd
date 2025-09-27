extends CharacterBody2D

var ink_projectile: String = "ink_projectile"

func setup_projectile(direction: Vector2):
	velocity = direction * 300
	get_tree().create_timer(2).timeout.connect(queue_free)

func _physics_process(_delta):
	move_and_slide()
