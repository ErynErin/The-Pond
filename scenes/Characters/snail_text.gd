extends RichTextEffect
class_name WavyText

var bbcode = "wavy"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var t = Time.get_ticks_msec() / 1000.0
	char_fx.offset.y = sin(char_fx.relative_index * 0.5 + t * 5.0) * 5.0
	return true
