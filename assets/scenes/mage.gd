extends "res://assets/scenes/enemy.gd"

func shoot():
	if !active: return
	
	velocity = Vector2.ZERO
	can_shoot=false
	can_move=false
	$MoveTimer.stop()
	$Pivot/Torso.animation="shoot"
	var rndsway = rng.randf_range(-sway,sway)
	await get_tree().process_frame

	# Predict where the player is heading
	var predict = GameManager.global_prediction_factor if GameManager.adaptive_difficulty else 0.5
	var dist = global_position.distance_to(player.global_position)
	var travel_time = dist / bullet_speed if bullet_speed > 0.0 else 0.0
	var predicted_pos = player.global_position + player.velocity * travel_time * predict
	var aim_angle = (predicted_pos - global_position).angle() + deg_to_rad(rndsway)

	var newb = bullet.instantiate()
	add_sibling(newb)
	newb.global_position = global_position
	newb.global_rotation = aim_angle
	newb.linear_velocity = Vector2.from_angle(aim_angle).normalized() * bullet_speed
	$ShotCd.start()
	await $ShotCd.timeout
	$Pivot/Torso.animation="idle"
	can_shoot=true
	can_move=true
	$MoveTimer.start()
