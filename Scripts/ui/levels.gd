extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_texture_button_5_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/maps/level_5.tscn")


func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/maps/test_scene.tscn")


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")
