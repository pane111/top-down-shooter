extends RigidBody2D

@export var target_group = "enemy"
@export var is_pb=false
@export var damage = 5.0
@export var explodes=false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func explode():
	if !explodes: return
	$ExplosionArea/ExpParticle.emitting=true
	for b in $ExplosionArea.get_overlapping_bodies():
		b.take_damage(damage/1.5)
	$ExplosionArea/ExpParticle.reparent(get_parent())

func _on_destroy_timer_timeout() -> void:
	
	if is_pb:
		GameManager.misses+=1
		GameManager.on_player_bullet_miss()
	explode()
	queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(target_group):
		body.take_damage(damage)
		if is_pb:
			GameManager.hits+=1
			GameManager.on_player_bullet_hit()
	else:
		if is_pb:
			GameManager.misses+=1
			GameManager.on_player_bullet_miss()
	explode()
	queue_free()
