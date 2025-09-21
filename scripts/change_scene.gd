extends Area2D

@export var next_scene = "res://scenes/Main Scenes/2nd_scene.tscn"

func _on_body_entered(body) -> void:
	if body == get_parent().find_child("player"):
		GameManager.load_to_scene(next_scene)
