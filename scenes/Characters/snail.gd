extends CharacterBody2D

@onready var label: RichTextLabel = $Label
@onready var timer: Timer = $Timer

var showing: bool = true

func _ready() -> void:
	label.install_effect(WavyText.new())
	label.text = "[wavy]*blub blub*[/wavy]"
	label.visible = false
	showing = false
	_set_next_timer()

func _on_timer_timeout() -> void:
	if showing:
		label.visible = false
		showing = false
	else:
		label.visible = true
		showing = true
	_set_next_timer() # Set next cycle

func _set_next_timer() -> void:
	if showing: # stay visible for exactly 3s
		timer.wait_time = 3.0
	else: # random delay before reappearing (3–5s)
		timer.wait_time = randf_range(3.0, 5.0)
	timer.start()
