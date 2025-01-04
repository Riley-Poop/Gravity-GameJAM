extends CanvasLayer

@onready var pause_panel = $"."

func _ready():
	pause_panel.hide()

func _input(event):
	if event.is_action_pressed("pause"):  # Add "pause" to Input Map (ESC key)
		toggle_pause()

func toggle_pause():
	if pause_panel.visible:
		resume_game()
	else:
		pause_game()

func pause_game():
	pause_panel.show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func resume_game():
	pause_panel.hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_pressed():
	resume_game()




func _on_quittomenu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")
