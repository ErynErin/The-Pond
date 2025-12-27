extends ColorRect

@onready var mat: ShaderMaterial = material as ShaderMaterial

func trigger_ripple_from_global(pos: Vector2) -> void:
	if mat == null: return

	# Ensure the UV is calculated based on the screen/viewport size 
	var screen_size = get_viewport_rect().size
	var uv = pos / screen_size

	mat.set_shader_parameter("center", uv)
	mat.set_shader_parameter("time", 0.0)

	var tween := create_tween()

	tween.tween_property(mat, "shader_parameter/time", 1.2, 1.2)
