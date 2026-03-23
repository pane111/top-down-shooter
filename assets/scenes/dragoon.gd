extends "res://assets/scenes/enemy.gd"

@export var damage = 15.0
@export var dash_force=200.0
@export var windup_time=0.75
var final_dash_force=200.0

func _ready() -> void:
	super._ready()
	final_dash_force=dash_force

func apply_difficulty():
	super.apply_difficulty()
	final_dash_force = dash_force * GameManager.global_bulletspeed_multiplier
	windup_time = 1.5 - GameManager.global_aggression
	


func shoot():
	
	velocity = Vector2.ZERO
	can_shoot=false
	can_move=false
	$Pivot/Torso.animation="windup"
	await get_tree().create_timer(windup_time).timeout
	var rndsway = rng.randf_range(-sway,sway)
	await get_tree().process_frame
	var predict = GameManager.global_prediction_factor if GameManager.adaptive_difficulty else 0.5
	var dist = global_position.distance_to(player.global_position)
	var travel_time = dist / final_dash_force if final_dash_force > 0.0 else 0.0
	var predicted_pos = player.global_position + player.velocity * travel_time * (predict*0.3)
	var aim_angle = (predicted_pos - global_position).angle() + deg_to_rad(rndsway)
	$Pivot/Torso.animation="dash"
	$Pivot/Afterimage.emitting=true
	$Pivot.global_rotation = aim_angle
	velocity = Vector2.from_angle(aim_angle).normalized() * final_dash_force
	$Pivot/HitArea.monitoring=true
	await get_tree().create_timer(travel_time*1.25).timeout
	$Pivot/Afterimage.emitting=false
	velocity = Vector2.ZERO
	$Pivot/HitArea.monitoring=false
	$Pivot/Torso.animation="idle"
	await get_tree().create_timer(windup_time+0.3).timeout
	can_shoot=true
	can_move=true
	

func _on_hit_area_body_entered(body: Node2D) -> void:
	body.take_damage(damage)
