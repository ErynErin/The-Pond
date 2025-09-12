extends Area2D

func _on_area_2d_body_entered(body) -> void:
	if not body.is_in_group("player"): # exits if the body isn't a player
		return
	
	$AudioStreamPlayer.play()
	GameManager.heal(10)
	$AnimationPlayer.play("collect")
	await $AnimationPlayer.animation_finished
	queue_free()
