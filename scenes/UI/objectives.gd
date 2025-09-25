extends Control

@onready var e_check_box: CheckBox = $AspectRatioContainer/Panel/VBoxContainer/HBoxContainer/ECheckBox
@onready var e_label: Label = $AspectRatioContainer/Panel/VBoxContainer/HBoxContainer/ELabel
@onready var a_check_box: CheckBox = $AspectRatioContainer/Panel/VBoxContainer/HBoxContainer2/ACheckBox
@onready var a_label: Label = $AspectRatioContainer/Panel/VBoxContainer/HBoxContainer2/ALabel
@onready var c_check_box: CheckBox = $AspectRatioContainer/Panel/VBoxContainer/HBoxContainer3/CCheckBox
@onready var c_label: Label = $AspectRatioContainer/Panel/VBoxContainer/HBoxContainer3/CLabel
@onready var b_1_check_box: CheckBox = $AspectRatioContainer/Panel/VBoxContainer/B1CheckBox
@onready var b_2_check_box: CheckBox = $AspectRatioContainer/Panel/VBoxContainer/B2CheckBox
@onready var m_check_box: CheckBox = $AspectRatioContainer/Panel/VBoxContainer/MCheckBox
@onready var t_check_box: CheckBox = $AspectRatioContainer/Panel/VBoxContainer/TCheckBox
@onready var aspect_ratio_container: HBoxContainer = $AspectRatioContainer
@onready var open: Button = $Open

func _ready():
	aspect_ratio_container.visible = true
	open.visible = false
	e_check_box.button_pressed = false
	a_check_box.button_pressed = false
	c_check_box.button_pressed = false
	b_1_check_box.button_pressed = false
	b_2_check_box.button_pressed = false
	m_check_box.button_pressed = false
	t_check_box.button_pressed = false
	
	match GameManager.phase_num:
		1:
			self.visible = false
			c_check_box.visible = true
			b_1_check_box.visible = false
			b_2_check_box.visible = false
			m_check_box.visible = true
			t_check_box.visible = false
			c_label.visible = true
		2:
			c_check_box.visible = true
			b_1_check_box.visible = false
			b_2_check_box.visible = false
			m_check_box.visible = true
			t_check_box.visible = false
			c_label.visible = true
		3:
			c_check_box.visible = false
			b_1_check_box.visible = false
			b_2_check_box.visible = false
			m_check_box.visible = false
			t_check_box.visible = false
			c_label.visible = false
	
	GameManager.minimum_enemies_killed.connect(_on_enemies_killed_updated)
	GameManager.minimum_algae_eaten.connect(_on_algae_eaten_updated)
	GameManager.minimum_caps_collected.connect(_on_caps_collected_updated)

	_on_enemies_killed_updated(GameManager.enemies_killed)
	_on_algae_eaten_updated(GameManager.algae_eaten)
	_on_caps_collected_updated(GameManager.caps_collected)

func update_checkbox(checkbox: CheckBox, current_value: int, objective_index: int):
	var required_value = GameManager.phase_objectives["p" + str(GameManager.phase_num)][objective_index]
	if current_value == required_value:
		checkbox.button_pressed = true

func _on_enemies_killed_updated(new_enemy):
	e_check_box.text = "Kill " + str(GameManager.phase_objectives["p" + str(GameManager.phase_num)][0]) + " enemies"
	e_label.text = "("+ str(GameManager.enemies_killed) + "/" + str(GameManager.phase_objectives["p" + str(GameManager.phase_num)][0]) + ")"
	update_checkbox(e_check_box, new_enemy, 0)
	
func _on_algae_eaten_updated(new_algae):
	a_check_box.text = "Eat " + str(GameManager.phase_objectives["p" + str(GameManager.phase_num)][1]) + " algae"
	a_label.text = "("+ str(GameManager.algae_eaten) + "/" + str(GameManager.phase_objectives["p" + str(GameManager.phase_num)][1]) + ")"
	update_checkbox(a_check_box, new_algae, 1)

func _on_caps_collected_updated(new_caps):
	c_check_box.text = "Collect " + str(GameManager.phase_objectives["p" + str(GameManager.phase_num)][2]) + " bottle caps"
	c_label.text = "("+ str(GameManager.caps_collected) + "/" + str(GameManager.phase_objectives["p" + str(GameManager.phase_num)][2]) + ")"
	update_checkbox(c_check_box, new_caps, 2)

func _on_open_pressed() -> void:
	aspect_ratio_container.visible = true
	open.visible = false

func _on_exit_pressed() -> void:
	aspect_ratio_container.visible = false
	open.visible = true
