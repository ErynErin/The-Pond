extends Area2D

var sound1 = preload("res://assets/Audios/chomp1.mp3")
var sound2 = preload("res://assets/Audios/chomp2.mp3")

static var use_first_sound : bool = true

func _on_area_2d_body_entered(body) -> void:
	if not body.is_in_group("player"): # exits if the body isn't a player
		return
	
	if use_first_sound:
		$AudioStreamPlayer.stream = sound1
	else:
		$AudioStreamPlayer.stream = sound2
	
	$AudioStreamPlayer.play()
	use_first_sound = !use_first_sound
	
	GameManager.heal(10)
	GameManager.add_algae_eaten()
	$AnimationPlayer.play("collect")
	await $AnimationPlayer.animation_finished
	queue_free()
