extends Label

func _ready():
	GameManager.coins_updated.connect(self._on_coins_updated)
	_on_coins_updated(GameManager.coins)

func _on_coins_updated(new_coins):
	text = "Coins: " + str(new_coins)
