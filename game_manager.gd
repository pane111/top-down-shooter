extends Node

@export var start_scene: PackedScene

@export var global_movespeed_multiplier = 1.0
@export var global_bulletspeed_multiplier = 1.0
@export var global_sway = 0.0
@export var global_drop_multiplier = 1.0
@export var global_cooldown_multiplier = 1.0

var cur_scene
var last_loaded

var pstats
var saved_data = false

var hits=0
var misses=0

var adaptive_difficulty=false
var rng

signal updated_difficulty
var player

func move_cam_to_node(nd,dur):
	var cam = get_viewport().get_camera_2d()
	var pss = cam.position_smoothing_speed
	player.can_move=false
	player.velocity = Vector2.ZERO
	cam.position_smoothing_speed=1.5
	cam.global_position = nd.global_position
	await get_tree().create_timer(dur).timeout
	cam.position_smoothing_speed=pss
	cam.global_position=player.global_position
	player.can_move=true

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	pstats = PlayerStats.new()
	var ad_chance = rng.randi_range(0,100)
	if ad_chance <= 50:
		adaptive_difficulty=true
		pstats.stats["version"]="A"
	else:
		pstats.stats["version"]="B"

func set_hpbar(val):
	if $HUD/HpBar.value > val:
		$HUD/HurtFlash.play("RESET")
		$HUD/HurtFlash.play("flash")
	$HUD/HpBar.value = val

func set_difficulty(ms,bs,sway,drop,cd):
	global_bulletspeed_multiplier = bs
	global_movespeed_multiplier = ms
	global_sway = sway
	global_drop_multiplier = drop
	global_cooldown_multiplier = cd
	updated_difficulty.emit()


func calculate_accuracy():
	var totalshots = hits+misses
	var acc = (misses/totalshots)*100
	return acc

func apply_pstats():
	pstats.stats["accuracy"] = calculate_accuracy()

func start_game():
	load_new_scene(start_scene)
func export_pstats():
	var data = [pstats.stats]
	var jsonstring = JSON.stringify(data)
	var save_file = FileAccess.open("res://playerdata.json", FileAccess.WRITE)
	save_file.store_line(jsonstring)
	print_debug("Saved data at " + save_file.get_path_absolute())
	saved_data = true

func send_pstats():
	print_debug("Sending player stats...")
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(self._http_request_completed)
	
	var body = JSON.stringify(pstats.stats)
	var headers = ["Content-Type: application/json"]
	
	var error = http_request.request("https://www.mediadrom.at/wp-json/gameapi/v1/score", headers,HTTPClient.METHOD_POST,body)
	if error != OK:
		push_error("Error occurred in the HTTP request")
	else:
		print_debug("Sent!")
# Called when the HTTP request is completed.
func _http_request_completed(_result, response_code, headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	
	# Access the response data from your WordPress endpoint
	print("Status: ", response.status)
	print("Message: ", response.message)
	print("Data: ", response.data)
	
	# If you need to check headers, iterate through the headers array:
	for header in headers:
		print(header)

func load_new_scene(newSc):
	last_loaded=newSc
	var ns = newSc.instantiate()
	if cur_scene != null:
		cur_scene.queue_free()
	add_child(ns)
	cur_scene = ns
