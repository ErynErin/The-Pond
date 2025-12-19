extends Area2D

var anglerfish

func _ready():
	anglerfish = get_node("../../AnglerFish")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if anglerfish.has_method("set_player_hidden"):
			print("player hiding")
			anglerfish.set_player_hidden(true) # Not visible to boss

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if anglerfish.has_method("set_player_hidden"):
			print("player seen")
			anglerfish.set_player_hidden(false) # Visible to boss
