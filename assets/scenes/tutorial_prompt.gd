extends Label

@export var next: Node
@export var next_text: Node
@export var active=true
@export var inputs: Dictionary[String,bool]
@export var disappear_time=1.0
@export var show_help: Node2D
@export var camfocus: Node2D
@export var move_cam=false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if move_cam:
		GameManager.move_cam_to_node(camfocus,4)
	if show_help != null:
		show_help.hide()
		
func _input(event: InputEvent) -> void:
	if !active: return
	var pressedcount = 0
	for inp in inputs:
		if event.is_action(inp):
			inputs[inp]=true
		if inputs[inp]==true:
			pressedcount+=1
	if pressedcount >= inputs.size():
		oncomplete()
		
func activate():
	show()
	active=true
	if show_help != null:
		show_help.show()

func oncomplete():
	if show_help!=null:
		show_help.hide()
	active = false
	add_theme_color_override("font_color",Color.GREEN)
	text += " ✔"
	await get_tree().create_timer(disappear_time).timeout
	if next != null:
		next.activate()
	if next_text != null:
		next_text.appear()
	hide()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
