extends "res://assets/scenes/enemy.gd"
func shoot():
	
	velocity = Vector2.ZERO
	can_shoot=false
	can_move=false
	$Pivot/Torso.animation="shoot"
	await get_tree().process_frame
	await $Pivot/Torso.frame_changed
	var bodies = $Pivot/HitArea.get_overlapping_bodies()
	# Player damage if overlapping
	$ShotCd.start()
	await $Pivot/Torso.animation_looped
	$Pivot/Torso.animation="idle"
	await $ShotCd.timeout
	can_shoot=true
	can_move=true
