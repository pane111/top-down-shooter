extends "res://buff_prefab.gd"



func _on_buff_apply():
	GameManager.player.toggle_shield(true)

func _on_buff_end():
	GameManager.player.toggle_shield(false)
