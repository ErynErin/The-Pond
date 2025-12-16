extends Area2D

var player_hidden = false

func _ready():
	body_entered.connect(_on_player_enter)
	body_exited.connect(_on_player_exit)

func _on_player_enter(body):
	if body.is_in_group("player"):
		player_hidden = true
		body.set_collision_mask_value(2, false)  # Hide from boss

func _on_player_exit(body):
	if body.is_in_group("player"):
		player_hidden = false
		body.set_collision_mask_value(2, true)  # Visible to boss
