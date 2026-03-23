extends Area2D
@export var scene_to_load: PackedScene
@export var end_game=false

func _load_next_scene():
	GameManager.player.can_move=false
	if end_game:
		GameManager.end_game()
	else:
		GameManager.load_new_scene(scene_to_load)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	_load_next_scene()
