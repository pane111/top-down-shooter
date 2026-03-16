extends RigidBody2D

@export var target_group = "enemy"
@export var is_pb=false
@export var damage = 5.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_destroy_timer_timeout() -> void:
	queue_free()
	if is_pb:
		GameManager.misses+=1


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(target_group):
		body.take_damage(damage)
		if is_pb:
			GameManager.hits+=1
	else:
		if is_pb:
			GameManager.misses+=1
	queue_free()
