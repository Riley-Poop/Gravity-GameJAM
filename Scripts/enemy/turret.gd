extends Node3D

@export var rotate_speed = 2.0
@export var detection_range = 20.0
@export var fire_rate = 0.5
@export var bullet_speed = 20.0

@onready var turret_head = $RootNode/Head
@onready var muzzle = $RootNode/Head/Marker3D
@onready var detection_area = $Area3D
@onready var player = get_tree().get_first_node_in_group("player")
@onready var ray_cast = $RootNode/Head/RayCast3D

var bullet_scene = preload("res://Scenes/enemy/bullet.tscn")
var can_fire = true
var player_detected = false

func _ready():
	# Setup detection area
	
	
	# Connect signals
	detection_area.connect("body_entered", Callable(self, "_on_body_entered"))
	detection_area.connect("body_exited", Callable(self, "_on_body_exited"))

func _physics_process(delta):
	if player_detected and player:
		# Check line of sight
		ray_cast.look_at(player.global_position + Vector3(0, 1, 0))
		ray_cast.force_raycast_update()
		
		if ray_cast.is_colliding() and ray_cast.get_collider() == player:
			# Rotate turret head smoothly
			var target_rotation = turret_head.global_position.direction_to(player.global_position)
			var current_rotation = -turret_head.global_transform.basis.z
			var new_rotation = current_rotation.lerp(target_rotation, rotate_speed * delta)
			turret_head.look_at(turret_head.global_position + new_rotation)
			
			# Shoot if facing player
			if current_rotation.dot(target_rotation) > 0.98 and can_fire:
				shoot()

func shoot():
	can_fire = false
	
	# Instance bullet
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	
	# Set bullet position and direction
	bullet.global_position = muzzle.global_position
	bullet.direction = -muzzle.global_transform.basis.z
	bullet.speed = bullet_speed
	
	# Reset fire rate timer
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true




func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_detected = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_detected = false
