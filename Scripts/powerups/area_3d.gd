extends Area3D

@export var time_amount = 25.0  # Amount of time/momentum added
@onready var mesh = $Sketchfab_Scene
@onready var pickup_sound = $Guts  # Optional

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Reset stamina to max
		body.restore_stamina()
		# Add time to player's momentum
		body.add_momentum(time_amount)
		
		# Optional: Play sound
		if pickup_sound:
			pickup_sound.play()
		
		# Hide mesh
		mesh.hide()
		
		# Wait for sound to finish if there is one
		if pickup_sound:
			await pickup_sound.finished
		
		# Remove pickup
		queue_free()
