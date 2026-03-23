extends Node2D
var active=true
var hp = 3
@export var drop_item=true
@export var dropped_item: PackedScene
func take_damage(amt):
	if !active: return
	$HitParticle.emitting=false
	$HitParticle.emitting=true
	$Hit.show()
	hp-=1
	if hp <= 0:
		if drop_item:
			var ni = dropped_item.instantiate()
			add_sibling(ni)
			ni.global_position = global_position
		GameManager.kill.emit()
		active=false
		$Sprite2D.hide()
		$CollisionShape2D.set_deferred("disabled",true)
	$Sprite2D.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	$Hit.hide()
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.modulate = Color.WHITE
	
