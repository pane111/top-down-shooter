extends CharacterBody2D

@export var move_speed= 10.0
@export var bullet_speed=500.0

@export var bullet: PackedScene
var can_shoot=true
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func shoot():
	var newb = bullet.instantiate()
	add_sibling(newb)
	newb.global_position = global_position
	newb.global_rotation = $Pivot.global_rotation
	newb.linear_velocity = Vector2.from_angle($Pivot.global_rotation).normalized() * bullet_speed

func _unhandled_input(event: InputEvent) -> void:
	var inputdir = Input.get_vector("mleft","mright","mup","mdown")
	if inputdir.length() > 0:
		$Pivot/PlayerLegs.animation="move"
		velocity = inputdir.normalized() * move_speed
	else:
		$Pivot/PlayerLegs.animation="idle"
		velocity = Vector2.ZERO
		
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Pivot.look_at(get_global_mouse_position())
	if Input.is_action_pressed("click") && can_shoot:
		$Pivot/PlayerTorso.animation = "shoot"
		$Pivot/PlayerTorso.play()
		shoot()
		can_shoot=false
		await $Pivot/PlayerTorso.animation_finished
		can_shoot=true
		$Pivot/PlayerTorso.animation = "idle"

func _physics_process(delta: float) -> void:
	move_and_slide()
