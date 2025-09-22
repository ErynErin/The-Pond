extends Control

@onready var shop_panel: Panel = $"Shop Panel"

@onready var health_label: Label = $"Shop Panel/Current Stats/Health Label"
@onready var strength_label: Label = $"Shop Panel/Current Stats/Strength Label"
@onready var speed_label: Label = $"Shop Panel/Current Stats/Speed Label"

@onready var health_icon: TextureRect = $"Shop Panel/Buttons/Health Button/HBoxContainer/Health Icon"
@onready var speed_icon: TextureRect = $"Shop Panel/Buttons/Speed Button/HBoxContainer/Speed Icon"
@onready var strength_icon: TextureRect = $"Shop Panel/Buttons/Strength Button/HBoxContainer/Strength Icon"
@onready var insufficient: Label = $Insufficient

func _ready() -> void:
	health_icon.texture = load("res://assets/Merchant Items/P" + str(GameManager.phase_num) + "_health.png")
	speed_icon.texture = load("res://assets/Merchant Items/P" + str(GameManager.phase_num) + "_speed.png")
	strength_icon.texture = load("res://assets/Merchant Items/P" + str(GameManager.phase_num) + "_strength.png")
	insufficient.visible = false

func _on_health_button_pressed():
	if GameManager.coins < 5:
		insufficientLabelCall()
		return
	$AudioStreamPlayer2.play()
	GameManager.reduce_coin(5)
	GameManager.heal(40)
	health_label.text = "Health: " + str(GameManager.max_health)
	GameManager.hide_shop()
	
func _on_strength_button_pressed():
	if GameManager.coins < 10:
		insufficientLabelCall()
		return
	$AudioStreamPlayer2.play()
	GameManager.reduce_coin(10)
	GameManager.add_strength()
	strength_label.text = "Strength: " + str(GameManager.strength)
	GameManager.hide_shop()

func _on_speed_button_pressed():
	if GameManager.coins < 10:
		insufficientLabelCall()
		return
	$AudioStreamPlayer2.play()
	GameManager.reduce_coin(10)
	GameManager.add_speed()
	speed_label.text = "Speed: " + str(GameManager.speed)
	GameManager.hide_shop()

func _on_exit_pressed() -> void:
	GameManager.hide_shop()

func insufficientLabelCall():
	insufficient.visible = true
	$AudioStreamPlayer3.play()
	await get_tree().create_timer(3).timeout
	insufficient.visible = false
