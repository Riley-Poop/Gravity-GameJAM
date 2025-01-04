extends Node3D

var direction = Vector3.FORWARD
var speed = 15.0
var damage = 10.0


func _physics_process(delta):
	position += direction * speed * delta
	
	# Optional: Delete bullet after certain time
	await get_tree().create_timer(5.0).timeout
	queue_free()




func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)  # Add this function to your player script
	queue_free()
