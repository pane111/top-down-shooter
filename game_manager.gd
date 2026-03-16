extends Node

@export var start_scene: PackedScene

var cur_scene

var pstats
var saved_data = false

var hits=0
var misses=0

var adaptive_difficulty=false
var rng

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	pstats = PlayerStats.new()
	var ad_chance = rng.randi_range(0,100)
	if ad_chance <= 50:
		adaptive_difficulty=true
		pstats.stats["version"]="A"
	else:
		pstats.stats["version"]="B"
	

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
	var ns = newSc.instantiate()
	if cur_scene != null:
		cur_scene.queue_free()
	add_child(ns)
	cur_scene = ns
