extends Node

@onready var audio_player = $AudioStreamPlayer

var music_list = [
	preload("res://Assets/Music/DavidKBD - Code injection Pack - 01 - Underbeat.ogg"),
	preload("res://Assets/Music/DavidKBD - Code injection Pack - 02 - Behind the Darkness-loop.ogg"),
	preload("res://Assets/Music/DavidKBD - Code injection Pack - 03 - Synthetic Whisper-loop.ogg"),
	preload("res://Assets/Music/DavidKBD - Code injection Pack - 04 - Secret Dissonance-loop.ogg"),
	preload("res://Assets/Music/DavidKBD - Code injection Pack - 05 - Into the Code Abyss-loop.ogg"),
	preload("res://Assets/Music/DavidKBD - Code injection Pack - 06 - Electric Inferno-loop.ogg"),
	preload("res://Assets/Music/DavidKBD - Code injection Pack - 07 - Binary Chaos-loop.ogg"),
	preload("res://Assets/Music/DavidKBD - Code injection Pack - 08 - Sentinel Cloud-loop.ogg")
]

var current_track = 0

func _ready():
	# Connect to the finished signal to know when to play next song
	audio_player.finished.connect(_on_song_finished)
	play_music()

func play_music():
	audio_player.stream = music_list[current_track]
	audio_player.play()

func _on_song_finished():
	# Move to next song
	current_track = (current_track + 1) % music_list.size()
	play_music()

func play_from_track(track_number: int):
	if track_number >= 0 and track_number < music_list.size():
		current_track = track_number
		play_music()

# Optional: Add control functions


func set_volume(value: float):
	audio_player.volume_db = linear_to_db(value)
