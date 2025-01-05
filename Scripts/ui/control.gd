extends Control

@onready var settings_panel = $SettingsPanel
@onready var resolution_option = $SettingsPanel/VBoxContainer/ResolutionMode
@onready var window_mode_option = $SettingsPanel/VBoxContainer/WindowMode
@onready var music_slider = $SettingsPanel/VBoxContainer/HSlider
@onready var sfx_slider = $SettingsPanel/VBoxContainer/HSlider2

var resolutions = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	settings_panel.hide()
	
	# Setup resolution options
	for resolution in resolutions:
		resolution_option.add_item(str(resolution.x) + "x" + str(resolution.y))
	
	# Setup window mode options
	window_mode_option.add_item("Windowed")
	window_mode_option.add_item("Fullscreen")
	
	# Setup volume sliders
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.value = 80
	
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.value = 80
	
	# Connect signals
	$VBoxContainer/Settings.pressed.connect(_on_settings_button_pressed)
	$SettingsPanel/VBoxContainer/ApplyButton.pressed.connect(_on_apply_pressed)
	$SettingsPanel/VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	
	# Connect volume change signals
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

func _on_music_volume_changed(value: float):
	var volume_db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), volume_db)

func _on_sfx_volume_changed(value: float):
	var volume_db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), volume_db)



func _on_settings_button_pressed():
	settings_panel.show()

func _on_back_pressed():
	settings_panel.hide()

func _on_apply_pressed():
	
	_on_music_volume_changed(music_slider.value)
	_on_sfx_volume_changed(sfx_slider.value)
	
	save_settings()
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
	
	
	# Save settings
	save_settings()

func save_settings():
	var settings = {
		"resolution": resolution_option.selected,
		"window_mode": window_mode_option.selected,
		"music_volume": music_slider.value,
		"sfx_volume": sfx_slider.value
	}
	
	var save_file = FileAccess.open("user://settings.save", FileAccess.WRITE)
	save_file.store_var(settings)

func load_settings():
	if FileAccess.file_exists("user://settings.save"):
		var save_file = FileAccess.open("user://settings.save", FileAccess.READ)
		var settings = save_file.get_var()
		
		resolution_option.selected = settings.resolution
		window_mode_option.selected = settings.window_mode
		music_slider.value = settings.music_volume
		sfx_slider.value = settings.sfx_volume
		
		_on_apply_pressed()



# Called every frame. 'delta' is the elapsed time since the previous frame.



func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/levels.tscn")


func _on_button_pressed() -> void:
	$Shoot.play()


func _on_quit_pressed() -> void:
	get_tree().quit()
