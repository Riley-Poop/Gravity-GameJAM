extends Area3D

@onready var label = $jump

func _ready():
	# Hide label initially
	label.hide()
	
	# Connect signals
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		label.show()
		# Optional: Add a fade-in effect
		var tween = create_tween()
		tween.tween_property(label, "modulate", Color(1,1,1,1), 0.5)
