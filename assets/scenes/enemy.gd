extends CharacterBody2D

@export var max_hp=3.0
@export var base_move_speed=120.0
@export var base_bullet_speed=200.0
@export var sust_dist=100.0
@export var sway=0.0
@export var bullet: PackedScene
@export var base_shot_cd=1.0
@export var base_drop_rate = 15
var drop_rate
var move_speed
var bullet_speed
var cur_hp
var player
var can_shoot=true
var can_move=true
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	cur_hp = max_hp
	move_speed=base_move_speed
	bullet_speed = base_bullet_speed
	$ShotCd.wait_time = base_shot_cd
	drop_rate = base_drop_rate
	if GameManager.adaptive_difficulty:
		apply_difficulty()
		GameManager.updated_difficulty.connect(apply_difficulty)

func take_damage(amt):
	if player==null:
		player = GameManager.player
	cur_hp-=amt
	$Pivot.modulate = Color.RED
	if cur_hp <= 0:
		var chance = rng.randi_range(0,100)
		if chance >= drop_rate:
			print_debug("Dropped item")
		queue_free()
	await get_tree().create_timer(0.2).timeout
	$Pivot.modulate = Color.WHITE

func apply_difficulty():
	move_speed = base_move_speed*GameManager.global_movespeed_multiplier
	bullet_speed = base_bullet_speed * GameManager.global_bulletspeed_multiplier
	$ShotCd.wait_time = base_shot_cd * GameManager.global_cooldown_multiplier
	drop_rate = base_drop_rate * GameManager.global_drop_multiplier


func _physics_process(delta: float) -> void:
	if player==null:return
	
	var pdir = player.global_position - global_position
	var pdist = pdir.length()
	if pdist == null:
		return
	if can_move:
		if pdist > sust_dist:
			velocity = pdir.normalized()*move_speed
			$Pivot/Legs.animation="move"
		elif pdist < sust_dist*0.8:
			velocity = -pdir.normalized()*move_speed
			$Pivot/Legs.animation="move"
		else:
			velocity = Vector2.ZERO
			$Pivot/Legs.animation="idle"
			if can_shoot:
				await get_tree().process_frame
				shoot()
		$Pivot.look_at(player.global_position)
	else:
		velocity = Vector2.ZERO
	
	
	
	move_and_slide()




func shoot():
	
	velocity = Vector2.ZERO
	can_shoot=false
	can_move=false
	$Pivot/Torso.animation="shoot"
	var rndsway = rng.randf_range(-sway,sway)
	await get_tree().process_frame
	var newb = bullet.instantiate()
	add_sibling(newb)
	newb.global_position = global_position
	newb.global_rotation = $Pivot.global_rotation + deg_to_rad(rndsway)
	newb.linear_velocity = Vector2.from_angle(newb.global_rotation).normalized() * bullet_speed
	$ShotCd.start()
	await $Pivot/Torso.animation_looped
	$Pivot/Torso.animation="idle"
	await $ShotCd.timeout
	can_shoot=true
	can_move=true

func _on_detection_circle_body_entered(body: Node2D) -> void:
	player = body
