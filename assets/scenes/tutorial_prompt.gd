extends Label

@export var next: Node
@export var next_text: Node
@export var active=true
@export var inputs: Dictionary[String,bool]
@export var disappear_time=1.0
@export var show_help: Node2D
@export var camfocus: Node2D
@export var move_cam=false
@export var signal_to_await=""
@export var await_signal = false
@export var player_var = ""
@export var set_player_var = true
@export var delay = 1.0
@export var activate_on_ready = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if activate_on_ready:
		activate()
	if move_cam:
		GameManager.move_cam_to_node(camfocus,4)
	if show_help != null:
		await get_tree().process_frame
		show_help.hide()
		
	if GameManager.has_signal(signal_to_await):
		GameManager.connect(signal_to_await,oncomplete)
		
func _input(event: InputEvent) -> void:
	if !active: return
	if await_signal: return
	var pressedcount = 0
	for inp in inputs:
		if event.is_action(inp):
			inputs[inp]=true
		if inputs[inp]==true:
			pressedcount+=1
	if pressedcount >= inputs.size():
		oncomplete()
		
func activate():
	await get_tree().create_timer(delay).timeout
	show()
	active=true
	
	if show_help != null:
		show_help.show()
		if show_help.is_in_group("pickups"):
			show_help.monitoring=true
	if player_var=="":return
	if player_var in GameManager.player:
		GameManager.player.set(player_var,set_player_var)
	

func oncomplete():
	if show_help!=null:
		show_help.hide()
	active = false
	add_theme_color_override("font_color",Color.GREEN)
	text += "\n(Completed)"
	await get_tree().create_timer(disappear_time).timeout
	if next != null:
		next.activate()
	if next_text != null:
		next_text.appear()
	queue_free()
