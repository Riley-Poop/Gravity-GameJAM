extends Control


# Called when the node enters the scene tree for the first time.



# Called every frame. 'delta' is the elapsed time since the previous frame.



func _on_texture_button_5_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/maps/level_5.tscn")


func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/maps/level_1.tscn")


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")


func _on_texture_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/maps/level_2.tscn")


func _on_texture_button_6_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/maps/tutorial.tscn")


func _on_texture_button_3_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/maps/level_3.tscn")


func _on_texture_button_4_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/maps/level_4.tscn")
	
