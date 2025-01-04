extends Control

@onready var settings_panel = $SettingsPanel
@onready var resolution_option = $SettingsPanel/VBoxContainer/ResolutionMode
@onready var window_mode_option = $SettingsPanel/VBoxContainer/WindowMode
@onready var volume_slider = $SettingsPanel/VBoxContainer/HBoxContainer/HSlider

var resolutions = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Hide settings panel initially
	settings_panel.hide()
	
	# Setup resolution options
	for resolution in resolutions:
		resolution_option.add_item(str(resolution.x) + "x" + str(resolution.y))
	
	# Setup window mode options
	window_mode_option.add_item("Windowed")
	window_mode_option.add_item("Fullscreen")
	
	# Setup volume slider
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.value = 80  # Default value
	
	# Connect signals
	$VBoxContainer/Settings.pressed.connect(_on_settings_button_pressed)
	$SettingsPanel/VBoxContainer/ApplyButton.pressed.connect(_on_apply_pressed)
	$SettingsPanel/VBoxContainer/BackButton.pressed.connect(_on_back_pressed)

func _on_settings_button_pressed():
	settings_panel.show()

func _on_back_pressed():
	settings_panel.hide()

func _on_apply_pressed():
	# Get selected resolution
	var selected_res = resolutions[resolution_option.selected]
	
	if window_mode_option.selected == 0:  # Windowed
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
		get_window().min_size = Vector2i(640, 480)
		
		# Center the window on the screen
		var screen_size = DisplayServer.screen_get_size()
		var window_position = (screen_size - selected_res) / 2
		DisplayServer.window_set_position(window_position)
	else:  # Fullscreen
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Set window size
	get_window().size = selected_res
	
	# Update viewport size to match resolution
	get_tree().root.content_scale_size = selected_res
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	
	# Apply volume
	var volume_db = linear_to_db(volume_slider.value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)
	
	# Save settings
	save_settings()

func save_settings():
	var settings = {
		"resolution": resolution_option.selected,
		"window_mode": window_mode_option.selected,
		"volume": volume_slider.value
	}
	
	var save_file = FileAccess.open("user://settings.save", FileAccess.WRITE)
	save_file.store_var(settings)

func load_settings():
	if FileAccess.file_exists("user://settings.save"):
		var save_file = FileAccess.open("user://settings.save", FileAccess.READ)
		var settings = save_file.get_var()
		
		resolution_option.selected = settings.resolution
		window_mode_option.selected = settings.window_mode
		volume_slider.value = settings.volume
		
		# Apply loaded settings
		_on_apply_pressed()




# Called every frame. 'delta' is the elapsed time since the previous frame.



func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/levels.tscn")
