extends ProgressBar

func _ready():
	GameManager.health_changed.connect(self._on_health_changed)
	_on_health_changed(GameManager.starting_health, GameManager.max_health)

func _on_health_changed(current_health: float, max_health: float):
	max_value = max_health
	value = current_health
	
