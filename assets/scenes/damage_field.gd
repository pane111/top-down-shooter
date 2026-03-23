extends Area2D

@export var damage = 15.0
@export var time_to_dmg=1.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	if GameManager.adaptive_difficulty:
		time_to_dmg /= GameManager.global_bulletspeed_multiplier * 1.4
		if time_to_dmg < 1:
			time_to_dmg=1
	$DmgTimer.wait_time=time_to_dmg
	$DmgTimer.start()

func _process(delta: float) -> void:
	var scalemult = (1-lerpf(0.0,1.0,$DmgTimer.time_left/time_to_dmg))
	$Indicator.scale = Vector2.ONE * scalemult

func _on_dmg_timer_timeout() -> void:
	$ExpParticle.emitting = true
	$Indicator.hide()
	$IndicatorBg.hide()
	var bodies = get_overlapping_bodies()
	for b in bodies:
		b.take_damage(damage)
	await $ExpParticle.finished
	queue_free()
		
