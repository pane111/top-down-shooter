extends Node

@export var start_scene: PackedScene
@export var end_scene: PackedScene
@export var title_screen: PackedScene

@export var global_movespeed_multiplier = 1.0
@export var global_bulletspeed_multiplier = 1.0
@export var global_sway = 0.0
@export var global_drop_multiplier = 1.0
@export var global_cooldown_multiplier = 1.0
@export var global_reaction_delay = 0.4
@export var global_sustain_dist_multiplier = 1.0
@export var global_aggression = 0.5
@export var global_prediction_factor = 0.0
@export var min_sustain_dist = 150.0
@export var max_sustain_dist = 400.0
@export var player_invul_time = 0.2

@export var droppable_items: Array[PackedScene]

@export var buffs: Dictionary[String,PackedScene]
var active_buffs: Dictionary[String,Node]

var cur_scene
var last_loaded

var pstats
var saved_data = false

var hits=0
var misses=0

@export var adaptive_difficulty=false
var rng

# Adaptive difficulty state
@export var max_difficulty = 3.0
var difficulty_score = 1.5
@export var min_difficulty = 0.0
@export var max_upward_adjustment=0.2
var _last_damage_time = 0.0
var _time_since_death = 0.0
var _recent_kills_without_damage = 0
var _consecutive_deaths = 0

# Rolling accuracy window
var _recent_hits = 0
var _recent_misses = 0
var _recent_damage_count = 0
const ACCURACY_WINDOW_RESET = 30.0
var _accuracy_window_timer = 0.0

signal updated_difficulty
signal kill
signal potion
signal transition
var player
var hpbartween
var barricade

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

func add_buff(nm):
	if !active_buffs.has(nm) || active_buffs[nm]==null:
		var b = buffs[nm].instantiate()
		$HUD/Buffs.add_child(b)
		active_buffs[nm]=b
	else:
		active_buffs[nm].reset_timer()
func remove_barrier():
	barricade.queue_free()
func loss():
	$TransitionLayer/Defeat.show()
	$TransitionLayer/LossAnim.play("loss")
	await $TransitionLayer/LossAnim.animation_finished
	$TransitionLayer/LossAnim.play("RESET")

func end_game():
	set_hud(false)
	load_new_scene(end_scene)

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	pstats = PlayerStats.new()
	if !adaptive_difficulty:
		var ad_chance = rng.randi_range(0,100)
		if ad_chance <= 50:
			adaptive_difficulty=true
			pstats.stats["version"]="A"
		else:
			pstats.stats["version"]="B"
	kill.connect(_on_kill)

func _process(delta: float) -> void:
	if !adaptive_difficulty: return
	_time_since_death += delta
	_accuracy_window_timer += delta
	pstats.stats["time_alive"] = _time_since_death
	if _accuracy_window_timer >= ACCURACY_WINDOW_RESET:
		_recent_hits = 0
		_recent_misses = 0
		_recent_damage_count = 0
		_accuracy_window_timer = 0.0

func _on_kill():
	pstats.stats["kills"] += 1
	if adaptive_difficulty:
		var time_since_dmg = _time_since_death - _last_damage_time
		if time_since_dmg > 5.0:
			_recent_kills_without_damage += 1
		recalculate_difficulty()

func _on_potion():
	pstats.stats["potions_used"] += 1

func on_player_hit(damage_amt: float):
	pstats.stats["hits"] += 1
	pstats.stats["damage_taken"] += damage_amt
	_last_damage_time = _time_since_death
	_recent_kills_without_damage = 0
	_recent_damage_count += 1
	if adaptive_difficulty:
		recalculate_difficulty()

func on_player_death():
	pstats.stats["failures"] += 1
	_consecutive_deaths += 1
	pstats.stats["consecutive_deaths"] = _consecutive_deaths
	_time_since_death = 0.0
	_recent_kills_without_damage = 0
	if adaptive_difficulty:
		recalculate_difficulty()

func on_level_cleared():
	_consecutive_deaths = 0
	pstats.stats["consecutive_deaths"] = 0

func on_player_bullet_hit():
	_recent_hits += 1

func on_player_bullet_miss():
	_recent_misses += 1

func recalculate_difficulty():
	var adjustment = 0.0

	# Factor 1: Recent accuracy (high accuracy = player is skilled)
	var recent_total = _recent_hits + _recent_misses
	if recent_total >= 5:
		var recent_acc = float(_recent_hits) / float(recent_total)
		
		if recent_acc > 0.85:
			adjustment += 0.06
		elif recent_acc > 0.6:
			adjustment += 0.02
		elif recent_acc < 0.25:
			adjustment -= 0.03

	# Factor 2: Consecutive deaths (struggling hard)
	if _consecutive_deaths >= 3:
		adjustment -= 0.08
	elif _consecutive_deaths >= 2:
		adjustment -= 0.05
	elif _consecutive_deaths == 1:
		adjustment -= 0.03

	# Factor 3: Clean kills without taking damage
	if _recent_kills_without_damage >= 5:
		adjustment += 0.06
	elif _recent_kills_without_damage >= 3:
		adjustment += 0.05
	elif _recent_kills_without_damage >= 1:
		adjustment += 0.03

	# Factor 4: Survival streak
	if _time_since_death > 120.0:
		adjustment += 0.02
	elif _time_since_death > 60.0:
		adjustment += 0.01

	# Factor 5: Taking frequent damage (struggling)
	if _recent_damage_count >= 5:
		adjustment -= 0.03
	elif _recent_damage_count >= 3:
		adjustment -= 0.02
	elif _recent_damage_count >= 1:
		adjustment -= 0.01
	if adjustment > max_upward_adjustment:
		adjustment = max_upward_adjustment
	difficulty_score = clampf(difficulty_score + adjustment, min_difficulty, max_difficulty)
	pstats.stats["difficulty"] = difficulty_score
	_apply_difficulty_score()

func set_hpbar(val):
	if $HUD/HpBar.value > val:
		$HUD/HurtFlash.play("RESET")
		$HUD/HurtFlash.play("flash")
		$HUD/HpBar.modulate=Color.DIM_GRAY
		var t = get_tree().create_tween()
		t.tween_property($HUD/HpBar,"modulate",Color.WHITE,0.1)
	else:
		$HUD/HurtFlash.play("flash_heal")
	hpbartween = get_tree().create_tween()
	hpbartween.tween_property($HUD/HpBar,"value",val,0.1)
	

func set_difficulty(ms,bs,sway,drop,cd):
	global_bulletspeed_multiplier = bs
	global_movespeed_multiplier = ms
	global_sway = sway
	global_drop_multiplier = drop
	global_cooldown_multiplier = cd
	updated_difficulty.emit()



func _apply_difficulty_score():
	var d = difficulty_score/max_difficulty
	global_movespeed_multiplier = lerpf(0.4, 1.2, d)
	global_bulletspeed_multiplier = lerpf(0.45, 1.8, d)
	global_sway = lerpf(15.0, 0, d)
	global_drop_multiplier = lerpf(2.5, 0.9, d)
	global_cooldown_multiplier = lerpf(2.25, 0.8, d)
	global_reaction_delay = lerpf(1, 0.1, d)
	global_sustain_dist_multiplier = lerpf(0.75, 1.3, d)
	global_aggression = lerpf(0.1, 0.9, d)
	global_prediction_factor = lerpf(0.0, 0.75, d)
	player_invul_time = lerpf(0.6,0.15,d)
	$HUD/Debug/VBoxContainer/DiffLabel.text="(DEBUG) Difficulty: " + str(difficulty_score)
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
func set_hud(val):
	if val:
		$HUD.show()
	else:
		$HUD.hide()
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
	$TransitionLayer/TransitionAnim.play("fade_to_black")
	await $TransitionLayer/TransitionAnim.animation_finished
	transition.emit()
	for b in active_buffs:
		if active_buffs[b]!= null:
			active_buffs[b].clear()
	last_loaded=newSc
	var ns = newSc.instantiate()
	if cur_scene != null:
		cur_scene.queue_free()
	await get_tree().create_timer(1).timeout
	$TransitionLayer/Defeat.hide()
	add_child(ns)
	cur_scene = ns
	if cur_scene.has_meta("area_name"):
		$HUD/AreaLabel.text = cur_scene.get_meta("area_name")
	else:
		$HUD/AreaLabel.text = ""
	$TransitionLayer/TransitionAnim.play("fade_to_transp")

func set_debug_mode(val):
	if val:
		$HUD/Debug.show()
	else:
		$HUD/Debug.hide()

func _on_diff_slider_drag_ended(value_changed: bool) -> void:
	difficulty_score = $HUD/Debug/VBoxContainer/DiffSlider.value
	_apply_difficulty_score()
