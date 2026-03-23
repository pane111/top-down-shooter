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
	var stop_chance = 70 * GameManager.global_prediction_factor if GameManager.adaptive_difficulty else 35
	while true:
		var newb = bullet.instantiate()
		add_sibling(newb)
		
		var predict = GameManager.global_prediction_factor if GameManager.adaptive_difficulty else 0.5
		var predicted_pos = player.global_position + (player.velocity/1.6) * predict
		newb.global_position = predicted_pos
		await get_tree().create_timer(0.35).timeout
		var chance_to_stop = rng.randi_range(0,100)
		if chance_to_stop >= stop_chance:
			break
	$ShotCd.start()
	await $ShotCd.timeout
	$Pivot/Torso.animation="idle"
	await get_tree().create_timer(0.5).timeout
	can_shoot=true
	can_move=true
	$MoveTimer.start()
