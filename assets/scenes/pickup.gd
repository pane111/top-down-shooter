extends Area2D

func on_pickup():
	print_debug("Picked up an item")

func _on_body_entered(body: Node2D) -> void:
	on_pickup()
	queue_free()
