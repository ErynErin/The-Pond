extends AnimatedSprite2D

func _ready() -> void:
	var anim_name := "closed_" + str(GameManager.phase_num)
	play(anim_name)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var anim_name := "bud_" + str(GameManager.phase_num)
		play(anim_name)
