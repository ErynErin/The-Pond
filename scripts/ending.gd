extends Control

func _ready() -> void:
	$Animation.play("wait")

func _on_video_stream_player_finished() -> void:	
	$Animation.play("fade_in")
	await get_tree().create_timer(4).timeout 
	$Animation.play("fade_out")
	await $Animation.animation_finished
	get_tree().change_scene_to_file("res://scenes/Main Scenes/main_menu_ui.tscn")
