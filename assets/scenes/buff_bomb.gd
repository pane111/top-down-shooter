extends "res://buff_prefab.gd"


func _on_buff_apply():
	GameManager.player.set_bomb_bullet(true)

func _on_buff_end():
	GameManager.player.set_bomb_bullet(false)
