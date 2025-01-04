extends StaticBody3D

@export var detection_range = 20.0
@export var rotation_speed = 3.0
@export var shoot_interval = 0.05
@export var bullet_speed = 60.0
@export var damage = 10.0
@export var aim_threshold = 0.3

@onready var charge_sound = $Charge  # AudioStreamPlayer3D
@onready var shoot_sound = $Shoot   # AudioStreamPlayer3D

@onready var head = $RootNode/Head
@onready var guns = $RootNode/Head/Guns
@onready var ray_cast = $RayCast3D
@onready var shoot_point_left = $RootNode/Head/Guns/Marker3D  # Add these Marker3Ds to your guns
@onready var shoot_point_right = $RootNode/Head/Guns/Marker3D2
@onready var detection_area = $Area3D

var player = null
var can_shoot = true
var bullet_scene = preload("res://Scenes/enemy/bullet.tscn")
var current_gun = 0  # Alternate between guns

func _ready():
	var collision_shape = detection_area.get_node("CollisionShape3D")
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = detection_range
	collision_shape.shape = sphere_shape
	
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _physics_process(delta):
	if player and can_see_player():
		var direction = player.global_position - global_position
		direction.y = 0
		
		var target_head_rotation = atan2(direction.x, direction.z)
		var gun_direction = player.global_position - guns.global_position
		var target_gun_rotation = -atan2(gun_direction.y, sqrt(gun_direction.x * gun_direction.x + gun_direction.z * gun_direction.z))
		
		head.rotation.y = lerp_angle(head.rotation.y, target_head_rotation, rotation_speed * delta)
		guns.rotation.x = lerp_angle(guns.rotation.x, target_gun_rotation, rotation_speed * delta)
		
		var angle_diff = abs(angle_difference(head.rotation.y, target_head_rotation))
		if angle_diff < aim_threshold and !charge_sound.playing:
			# Play charge sound when first aiming at player
			charge_sound.play()
		if can_shoot and angle_diff < aim_threshold:
			shoot()

func shoot():
	can_shoot = false
	
	var shoot_point = shoot_point_right if current_gun == 0 else shoot_point_left
	current_gun = (current_gun + 1) % 2
	
	# Play shoot sound with random pitch
	shoot_sound.pitch_scale = randf_range(0.9, 1.1)
	shoot_sound.play()
	
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_position = shoot_point.global_position
	
	var bullet_direction = (player.global_position - shoot_point.global_position).normalized()
	bullet.direction = bullet_direction
	bullet.speed = bullet_speed
	bullet.damage = damage
	
	await get_tree().create_timer(shoot_interval).timeout
	can_shoot = true


func angle_difference(a: float, b: float) -> float:
	var diff = fmod(b - a + PI, PI * 2) - PI
	return diff

func can_see_player() -> bool:
	if !player:
		return false
	
	# Update raycast
	var direction = player.global_position - global_position
	ray_cast.target_position = ray_cast.to_local(player.global_position)
	ray_cast.force_raycast_update()
	
	return ray_cast.is_colliding() and ray_cast.get_collider() == player



func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_body_exited(body):
	if body == player:
		player = null
