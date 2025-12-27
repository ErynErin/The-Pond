extends Button

@export var ripple_overlay: NodePath

func _pressed():
	var overlay = get_node(ripple_overlay)
	overlay.trigger_ripple_from_global(global_position + size * 0.5)
