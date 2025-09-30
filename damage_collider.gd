extends StaticBody2D

var damage_collider: String = "damage_collider"

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(10)
