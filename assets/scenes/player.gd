extends CharacterBody2D

@export var move_speed= 10.0
var move_mult=1.0
@export var bullet_speed=500.0

@export var bullet: PackedScene
var initbullet
@export var bomb_bullet: PackedScene

@export var max_hp = 100.0
@export var start_hp = 100.0
@export var goal: Node2D
var cur_hp
var can_take_dmg = true
@export var can_shoot=true
var can_move=true
@export var delay = 1.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	toggle_shield(false)
	if goal != null:
		$GoalArrow.show()
	can_move=false
	initbullet = bullet
	cur_hp = start_hp
	GameManager.set_hpbar(cur_hp)
	GameManager.player = self
	GameManager.set_hud(true)
	await get_tree().create_timer(delay).timeout
	can_move=true
	

func shoot():
	var newb = bullet.instantiate()
	add_sibling(newb)
	newb.global_position = global_position
	newb.global_rotation = $Pivot.global_rotation
	newb.linear_velocity = Vector2.from_angle($Pivot.global_rotation).normalized() * bullet_speed

func _unhandled_input(event: InputEvent) -> void:
	if !can_move: return
	var inputdir = Input.get_vector("mleft","mright","mup","mdown")
	if inputdir.length() > 0:
		$Pivot/PlayerLegs.animation="move"
		velocity = inputdir.normalized() * move_speed * move_mult
	else:
		$Pivot/PlayerLegs.animation="idle"
		velocity = Vector2.ZERO

func take_damage(amt):
	if !can_take_dmg:return
	cur_hp -= amt
	GameManager.on_player_hit(amt)
	GameManager.set_hpbar(cur_hp)
	if cur_hp <= 0:
		GameManager.on_player_death()
		can_move=false
		can_shoot=false
		can_take_dmg=false
		velocity = Vector2.ZERO
		$Pivot.hide()
		$KOSprite.show()
		await get_tree().create_timer(1).timeout
		GameManager.loss()
		await get_tree().create_timer(5).timeout
		GameManager.load_new_scene(GameManager.last_loaded)
		
	$Pivot.modulate = Color.RED
	can_take_dmg=false
	await get_tree().create_timer(GameManager.player_invul_time).timeout
	$Pivot.modulate = Color.WHITE
	can_take_dmg=true

func set_move_mult(val):
	move_mult=val
func set_bomb_bullet(val):
	if val:
		bullet = bomb_bullet
	else:
		bullet = initbullet
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if goal != null:
		$GoalArrow.look_at(goal.global_position)
	$Pivot.look_at(get_global_mouse_position())
	if Input.is_action_pressed("click") && can_shoot && cur_hp > 0:
		$Pivot/PlayerTorso.animation = "shoot"
		$Pivot/PlayerTorso.play()
		shoot()
		can_shoot=false
		await $Pivot/PlayerTorso.animation_finished
		can_shoot=true
		$Pivot/PlayerTorso.animation = "idle"

func _physics_process(delta: float) -> void:
	move_and_slide()

func toggle_shield(val):
	if val:
		$ShieldBubble.show()
		$ShieldBubble/ShieldArea.monitoring=true
	else:
		$ShieldBubble.hide()
		$ShieldBubble/ShieldArea.monitoring=false
func _on_shield_area_body_entered(body: Node2D) -> void:
	body.queue_free()
