extends TextureProgressBar

@export var duration=30.0
signal ended

func _ready() -> void:
	$BTimer.wait_time = duration
	max_value=$BTimer.wait_time
	value = max_value
	$BTimer.start()
	_on_buff_apply()

func _process(delta: float) -> void:
	value = $BTimer.time_left

func reset_timer():
	$BTimer.start()
func clear():
	_on_buff_end()
func _on_b_timer_timeout() -> void:
	_on_buff_end()
	queue_free()

func _on_buff_apply():
	print_debug("Buff applied")

func _on_buff_end():
	print_debug("Buff ended")
