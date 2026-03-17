extends Label

@export var appear_on_ready=false
@export var time=5.0
@export var camfocus: Node2D
@export var move_cam=false
@export var remove_barrier=false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if appear_on_ready:
		appear()
	else:
		hide()


func appear():
	show()
	if move_cam:
		GameManager.move_cam_to_node(camfocus,time)
	if remove_barrier:
		GameManager.remove_barrier()
	await get_tree().create_timer(time).timeout
	hide()
