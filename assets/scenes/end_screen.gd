extends CanvasLayer


func _on_return_btn_pressed() -> void:
	$VBoxContainer/ReturnBtn.disabled=true
	GameManager.load_new_scene(GameManager.title_screen)
