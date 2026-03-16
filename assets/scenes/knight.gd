extends "res://assets/scenes/enemy.gd"
@export var damage = 10.0
func shoot():
	
	velocity = Vector2.ZERO
	can_shoot=false
	can_move=false
	$Pivot/Torso.animation="shoot"
	await get_tree().process_frame
	await $Pivot/Torso.frame_changed
	var bodies = $Pivot/HitArea.get_overlapping_bodies()
	for b in bodies:
		b.take_damage(damage)
	$ShotCd.start()
	await $Pivot/Torso.animation_looped
	$Pivot/Torso.animation="idle"
	await $ShotCd.timeout
	can_shoot=true
	can_move=true
