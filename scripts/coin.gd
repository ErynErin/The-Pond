extends Area2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): # exits if the body isn't a player
		return
		
	$AudioStreamPlayer.play()
	GameManager.add_coin(1)
	GameManager.add_caps_collected()
	$AnimationPlayer.play("collect")
	await $AnimationPlayer.animation_finished
	queue_free()
