extends ProtoCSGTorus3D

signal ring_collected

@onready var mesh = $"."
@onready var area = $Area3D

func _ready():
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		$"../../Collect".play()
		# Play collection effect/sound
		ring_collected.emit()
		# Fade out and delete
		var tween = create_tween()
		tween.tween_property(mesh, "transparency", 1.0, 0.3)
		tween.tween_callback(queue_free)
