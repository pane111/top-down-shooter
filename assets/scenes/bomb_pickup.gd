extends "res://assets/scenes/pickup.gd"

@export var buffname="bomb"

func on_pickup():
	GameManager.add_buff(buffname)
