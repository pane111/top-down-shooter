extends "res://assets/scenes/pickup.gd"

func on_pickup():
	if GameManager.player.cur_hp < GameManager.player.max_hp:
		GameManager._on_potion()
	GameManager.player.cur_hp += 20
	if GameManager.player.cur_hp > GameManager.player.max_hp:
		GameManager.player.cur_hp = GameManager.player.max_hp
	GameManager.set_hpbar(GameManager.player.cur_hp)
	GameManager.potion.emit()
