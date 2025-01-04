extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	# Show mouse in menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# Called every frame. 'delta' is the elapsed time since the previous frame.



func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/levels.tscn")
