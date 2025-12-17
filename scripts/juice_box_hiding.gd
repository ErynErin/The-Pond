extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.set_collision_mask_value(2, false)  # Hide from boss

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.set_collision_mask_value(2, true)  # Visible to boss
