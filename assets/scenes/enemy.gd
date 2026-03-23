extends CharacterBody2D

@export var max_hp=3.0
@export var base_move_speed=120.0
@export var base_bullet_speed=200.0
@export var sust_dist=100.0
@export var sway=0.0
@export var bullet: PackedScene
@export var base_shot_cd=1.0
@export var base_drop_rate = 15
@export var shoot_while_moving = true
@export var sust_dist_fixed=false
@export var stop_moving=true
var drop_rate
var move_speed
var bullet_speed
var cur_hp
var player
var can_shoot=true
var can_move=true
var rng = RandomNumberGenerator.new()
var active=true
var moving_back=false
var _has_reacted=false
var _reaction_timer=0.0
var can_take_dmg=true
func _ready() -> void:
	$HitParticle.emitting=true
	await get_tree().process_frame
	$HitParticle.emitting=false
	cur_hp = max_hp
	move_speed=base_move_speed
	bullet_speed = base_bullet_speed
	$ShotCd.wait_time = base_shot_cd
	drop_rate = base_drop_rate
	if GameManager.adaptive_difficulty:
		apply_difficulty()
		GameManager.updated_difficulty.connect(apply_difficulty)

func take_damage(amt):
	if !can_take_dmg:return
	if player==null:
		player = GameManager.player
		for e in $AlertArea.get_overlapping_bodies():
			e.player=player
	cur_hp-=amt
	
	$HitParticle.emitting=true
	$Hit.show()
	$Pivot.modulate = Color.RED
	if cur_hp <= 0:
		can_take_dmg=false
		var chance = rng.randi_range(0,100)
		if chance <= drop_rate:
			var ni = GameManager.droppable_items.pick_random().instantiate()
			add_sibling(ni)
			ni.global_position = global_position
			
		active=false
		GameManager.kill.emit()
		$Pivot.hide()
		$CollisionShape2D.set_deferred("disabled",true)
		
	await get_tree().create_timer(0.1).timeout
	$Hit.hide()
	await get_tree().create_timer(0.1).timeout
	$Pivot.modulate = Color.WHITE

func apply_difficulty():
	move_speed = base_move_speed*GameManager.global_movespeed_multiplier
	bullet_speed = base_bullet_speed * GameManager.global_bulletspeed_multiplier
	$ShotCd.wait_time = base_shot_cd * GameManager.global_cooldown_multiplier
	drop_rate = base_drop_rate * GameManager.global_drop_multiplier
	sway = GameManager.global_sway
	


func _physics_process(delta: float) -> void:
	if player==null:return
	if !active: return

	if !_has_reacted:
		_reaction_timer += delta
		var react_delay = GameManager.global_reaction_delay if GameManager.adaptive_difficulty else 0.0
		if _reaction_timer < react_delay:
			return
		_has_reacted = true

	var pdir = player.global_position - global_position
	var pdist = pdir.length()
	if pdist == null:
		return

	var effective_sust_dist = sust_dist
	if GameManager.adaptive_difficulty && !sust_dist_fixed:
		effective_sust_dist = clampf(
			sust_dist * GameManager.global_sustain_dist_multiplier,
			GameManager.min_sustain_dist,
			GameManager.max_sustain_dist
		)

	if can_move:
		if pdist > effective_sust_dist:
			moving_back=false
			velocity = pdir.normalized()*move_speed
			$Pivot/Legs.animation="move"
		elif pdist < effective_sust_dist*0.8:
			velocity = -pdir.normalized()*move_speed
			moving_back=true
			$Pivot/Legs.animation="move"
		else:
			moving_back=false
			velocity = Vector2.ZERO
			$Pivot/Legs.animation="idle"
			if can_shoot:
				await get_tree().process_frame
				shoot()
		$Pivot.look_at(player.global_position)
	else:
		if stop_moving: velocity = Vector2.ZERO



	move_and_slide()




func shoot():
	if !active: return
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
	await $ShotCd.timeout
	$Pivot/Torso.animation="idle"
	can_shoot=true
	can_move=true

func _on_detection_circle_body_entered(body: Node2D) -> void:
	if player==null:
		player = body
		for e in $AlertArea.get_overlapping_bodies():
			e.player=player


func _on_move_timer_timeout() -> void:
	if player==null: return
	if moving_back && can_shoot:
		var aggression = GameManager.global_aggression if GameManager.adaptive_difficulty else 1.0
		if rng.randf() <= aggression:
			await get_tree().process_frame
			shoot()
