extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(0.2)
	if GameManager.adaptive_difficulty:
		$VBoxContainer/VersionLabel.text = "Version A"
	else:
		$VBoxContainer/VersionLabel.text = "Version B"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_exp_button_pressed() -> void:
	GameManager.export_pstats()


func _on_send_button_pressed() -> void:
	GameManager.send_pstats()
	$VBoxContainer/SendButton.disabled=true


func _on_start_btn_pressed() -> void:
	GameManager.start_game()
	queue_free()


func _on_accept_button_pressed() -> void:
	$Disclaimer.hide()
