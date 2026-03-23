extends "res://buff_prefab.gd"



func _on_buff_apply():
	GameManager.player.set_move_mult(1.8)

func _on_buff_end():
	GameManager.player.set_move_mult(1.0)
