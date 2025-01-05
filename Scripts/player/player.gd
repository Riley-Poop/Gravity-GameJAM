extends CharacterBody3D

@onready var footstep_player = $Audio/FootStepsPlayer
@onready var jump_player = $Audio/JumpPlayer
@onready var slide_player = $Audio/SlidePlayer
@onready var land_player = $Audio/LandingPlayer

var momentum_enabled = true  # Add at top with other variables

@onready var momentum_bar = $Camera3D/UI/MomentumBar
@export var MAX_MOMENTUM = 100.0
@export var FLIP_MOMENTUM_BONUS = 10.0  # Amount of momentum gained from flipping
@export var MOMENTUM_DRAIN_RATE = 30.0  # How fast it drains when idle
@export var MOMENTUM_GAIN_RATE = 5.0   # How fast it fills when moving
var current_momentum = MAX_MOMENTUM
# Audio timing variables
var footstep_time = 0.0
@export var WALK_STEP_DELAY = 0.4 # Time between walking footsteps
@export var SPRINT_STEP_DELAY = 0.35  # Time between running footsteps
var was_in_air = false  # For tracking landing

var original_collision_height = 2.0  # Adjust to match your default height
var slide_collision_height = 0.55    # Height during slide
@onready var collision = $CollisionShape3D # Reference to your collision shape

# Player movement parameters
@export var WALK_SPEED = 7.0
@export var SPRINT_SPEED = 12.0
@export var JUMP_VELOCITY = 6.0
@export var MOUSE_SENSITIVITY = 0.002

@onready var speed_lines = $Camera3D/ColorRect # Adjust path to match your scene structure
@export var SPEED_LINES_THRESHOLD = 6.0  # Speed at which lines start appearing
@export var MAX_SPEED_LINES = 1.0  # Maximum intensity of speed lines

# Add these parameters at the top
var camera_tilt_target = 0.0
var camera_height_target = 0.0
var camera_transition_speed = 8.0  # Adjust this for faster/slower transitions

# Sprint and stamina parameters
@export var MAX_STAMINA = 200.0
@export var STAMINA_DRAIN_RATE = 10.0
@export var STAMINA_REGEN_RATE = 50.0
var current_stamina = MAX_STAMINA
var is_sprinting = false
var can_sprint = true
# FOV parameters

@export var BASE_FOV = 90.0  # Wider base FOV
@export var SPRINT_FOV_INCREASE = 15.0  # More dramatic sprint FOV
@export var SLIDE_FOV_INCREASE = 20.0  # More dramatic slide FOV
@export var FOV_CHANGE_SPEED = 15.0  # Faster FOV transitions
var target_fov = BASE_FOV

# View bob parameters

@export var MOVEMENT_TILT_AMOUNT = 0.03  # How much the camera tilts when moving
@export var MOVEMENT_TILT_SPEED = 8.0  # How fast the camera tilts
var movement_tilt = 0.0
var target_movement_tilt = 0.0

@export var BOB_FREQUENCY = 2.0  # Faster bob when walking
@export var BOB_AMPLITUDE = 0.05  # Smaller but faster bob
@export var SPRINT_BOB_FREQUENCY = 3.5  # Much faster when sprinting
@export var SPRINT_BOB_AMPLITUDE = 0.08  # More noticeable sprint bob
var bob_time = 0.0
var original_camera_pos = Vector3.ZERO

# Slide animation parameters
@export var SLIDE_JUMP_BOOST = 1.5  # Multiplier for jump momentum when sliding
@export var SLIDE_COYOTE_TIME = 0.15  # Time window to allow sliding after leaving ground
@export var SLIDE_JUMP_CONTROL = 0.8  # How much air control during slide jump (0-1)
@export var SLIDE_JUMP_MOMENTUM = 0.8  # How much slide momentum is preserved in jump
var slide_coyote_timer = 0.0
var wants_to_slide = false
var last_grounded_velocity = Vector3.ZERO
@export var SLIDE_TILT_AMOUNT = 0.08  # Reduced tilt amount
@export var SLIDE_COOLDOWN = 0.8  # Time in seconds before can slide again
var slide_cooldown_timer = 0.0
var can_slide = true
@export var SLIDE_SPEED_BOOST = 1.5  # More initial slide speed
@export var SLIDE_DURATION = 1.0  # Slightly shorter but more powerful slides
@export var SLIDE_SMOOTH_SPEED = 15.0  # Faster slide transitions 
@export var SLIDE_HEIGHT_CHANGE = 0.10  # How much to lower camera during slide
@export var SLIDE_CAMERA_TILT = 0.6  # How much camera tilts during slide
var is_sliding = false
var slide_timer = 0.0
var slide_direction = Vector3.ZERO
var initial_slide_speed = 0.0
var slide_camera_tilt = 0.0
var original_camera_height = 0.0
var slide_camera_height = 0.5  # Height of camera during slide

# Gravity parameters
@export var normal_gravity = -9.8
var current_gravity = -9.8
var gravity_direction = Vector3.DOWN
var is_flipping = false
var flip_duration = 0.5
var flip_timer = 0.0
var initial_rotation = Vector3.ZERO
var target_rotation = Vector3.ZERO

# Node references
@onready var camera = $Camera3D
@onready var ray_cast = $RayCast3D
@onready var collision_shape = $CollisionShape3D

# Camera limits (in radians)
var MIN_VERTICAL_ANGLE = deg_to_rad(-80)
var MAX_VERTICAL_ANGLE = deg_to_rad(80)

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	current_stamina = MAX_STAMINA
	original_camera_height = camera.position.y
	original_camera_pos = camera.position
	camera.fov = BASE_FOV
	momentum_bar.max_value = MAX_MOMENTUM
	momentum_bar.value = MAX_MOMENTUM


func handle_movement_tilt(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Calculate target tilt based on left/right movement
	target_movement_tilt = -input_dir.x * MOVEMENT_TILT_AMOUNT
	
	# Apply speed multiplier when sprinting
	if is_sprinting:
		target_movement_tilt *= 1.5
	
	# Smoothly interpolate to target tilt
	movement_tilt = lerp(movement_tilt, target_movement_tilt, delta * MOVEMENT_TILT_SPEED)
	
	# Apply the tilt if not sliding (since sliding has its own tilt)
	if !is_sliding:
		camera.rotation.z = movement_tilt

# Add these variables at the top with your other variables
var current_line_density = 0.0
var target_line_density = 0.0
var density_smooth_speed = 5.0  # Adjust this to control how fast the effect fades

func handle_speed_lines(delta):
	var shader_material = speed_lines.material as ShaderMaterial
	if !shader_material:
		return
		
	# Calculate speed factor
	var current_speed = velocity.length()
	var speed_factor = clamp((current_speed - SPEED_LINES_THRESHOLD) / (SPRINT_SPEED - SPEED_LINES_THRESHOLD), 0.0, 0.75)
	
	# Set target density based on state
	if is_sprinting and !can_jump():
		# High intensity for air sprinting
		target_line_density = speed_factor * 0.5  # Full effect
	elif is_sliding:
		# High intensity for sliding
		target_line_density = speed_factor * 0.5  # Full effect
	elif is_sprinting:
		# Low intensity for normal sprinting
		target_line_density = speed_factor * 0.4  # Reduced effect
	else:
		# No effect for normal movement
		target_line_density = 0.0
	
	# Smoothly interpolate current density to target
	current_line_density = lerp(current_line_density, target_line_density, delta * density_smooth_speed)
	
	# Apply shader parameters
	shader_material.set_shader_parameter("line_density", current_line_density)
	shader_material.set_shader_parameter("line_count", lerp(0.0, 2.0, current_line_density / 0.5))
	
	# Only animate if there's any effect
	if current_line_density > 0.01:
		shader_material.set_shader_parameter("animation_speed", lerp(1.0, 20.0, current_line_density / 0.5))
	else:
		shader_material.set_shader_parameter("animation_speed", 0.0)
	
	
func handle_audio(delta):
	# Handle footsteps - add check for not sliding
	if can_jump() and (velocity.x != 0 or velocity.z != 0) and !is_sliding:
		footstep_time += delta
		var step_delay = SPRINT_STEP_DELAY if is_sprinting else WALK_STEP_DELAY
		
		if footstep_time >= step_delay:
			footstep_time = 0.0
			if is_sprinting:
				# Running footsteps - faster playback
				footstep_player.pitch_scale = 1.2
			else:
				# Walking footsteps - random pitch
				footstep_player.pitch_scale = randf_range(0.8, 1.1)
			footstep_player.play()
	
	# Handle jump sound
	if Input.is_action_just_pressed("jump") and can_jump():
		jump_player.pitch_scale = randf_range(0.95, 1.05)  # Slight pitch variation
		jump_player.play()
	
	# Handle slide sound
	if is_sliding:
		if !slide_player.playing:
			slide_player.play()
	else:
		slide_player.stop()
	
	# Handle landing sound
	if can_jump() and was_in_air:
		# Only play if we had significant air time
		if was_in_air:
			land_player.pitch_scale = randf_range(0.95, 1.05)
			land_player.play()
		was_in_air = false
	elif !can_jump():
		was_in_air = true
		
func handle_momentum(delta):
	if !momentum_enabled:
		# Keep momentum at max if not enabled
		current_momentum = MAX_MOMENTUM
		momentum_bar.value = current_momentum
		return
		
	# Rest of your existing momentum code
	var is_moving = is_sprinting or is_sliding
	
	if is_moving:
		current_momentum = min(current_momentum + MOMENTUM_GAIN_RATE * delta, MAX_MOMENTUM)
	else:
		current_momentum = max(current_momentum - MOMENTUM_DRAIN_RATE * delta, 0)
	
	momentum_bar.value = current_momentum
	
	if current_momentum <= 0:
		current_momentum = 0
		die()
		return
		

# Add function to enable momentum loss
func enable_momentum_system():
	momentum_enabled = false
	
func add_momentum(amount):
	current_momentum = min(current_momentum + amount, MAX_MOMENTUM)
	

func restore_stamina():
	current_stamina = MAX_STAMINA
	can_sprint = true
	
# Add this new function to preserve momentum when jumping from slide:
func handle_slide_jump():
	if is_sliding and Input.is_action_just_pressed("jump") and can_jump():
		# Get current slide speed and direction
		var current_speed = velocity.length()
		
		# Calculate jump velocity with preserved momentum
		var jump_velocity = -gravity_direction * JUMP_VELOCITY
		
		# Preserve horizontal momentum
		var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
		
		# Add jump velocity while keeping momentum
		velocity = jump_velocity + (horizontal_velocity * SLIDE_JUMP_MOMENTUM)
		
		# End slide but keep track that we came from a slide
		end_slide()
		return true
	return false
	
func die():
	# Handle player death
	print("Player died!")
	# You might want to:
	# - Play death animation
	# - Show game over screen
	# - Restart level
	get_tree().reload_current_scene()  # Simple restart for now
	
func handle_view_bob(delta):
	if !is_sliding and can_jump() and (velocity.x != 0 or velocity.z != 0):
		var bob_speed = SPRINT_BOB_FREQUENCY if is_sprinting else BOB_FREQUENCY
		var bob_amount = SPRINT_BOB_AMPLITUDE if is_sprinting else BOB_AMPLITUDE
		
		bob_time += delta * bob_speed * velocity.length() / WALK_SPEED
		
		# Vertical bob
		var bob_y = sin(bob_time * PI) * bob_amount
		# Horizontal bob
		var bob_x = cos(bob_time * PI * 0.5) * bob_amount * 0.5
		
		# Smoothly interpolate camera position
		var target_pos = original_camera_pos + Vector3(bob_x, bob_y, 0)
		camera.position = camera.position.lerp(target_pos, delta * 10.0)
	else:
		# Reset camera position smoothly
		camera.position = camera.position.lerp(original_camera_pos, delta * 10.0)

func handle_fov(delta):
	var new_target_fov = BASE_FOV
	
	if is_sprinting:
		new_target_fov += SPRINT_FOV_INCREASE
	if is_sliding:
		new_target_fov += SLIDE_FOV_INCREASE
	
	target_fov = new_target_fov
	camera.fov = lerp(camera.fov, target_fov, delta * FOV_CHANGE_SPEED)
	
func _input(event):
	if event is InputEventMouseMotion and !is_flipping:
		var mouse_factor = -1.0 if gravity_direction.y > 0 else 1.0
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY * mouse_factor)
		var new_rotation = camera.rotation.x - event.relative.y * MOUSE_SENSITIVITY
		camera.rotation.x = clamp(new_rotation, MIN_VERTICAL_ANGLE, MAX_VERTICAL_ANGLE)
	
	if event.is_action_pressed("flip_gravity") and !is_flipping:
		start_gravity_flip()
	
	# Store slide input intent
	if event.is_action_pressed("slide"):
		wants_to_slide = true
	elif event.is_action_released("slide"):
		wants_to_slide = false
	
	# Try to start slide if we want to
	if wants_to_slide and can_start_slide():
		start_slide()

func can_start_slide():
	return !is_sliding and can_slide and (
		(is_sprinting and can_jump()) or 
		(is_sprinting and slide_coyote_timer > 0)
	)

func start_slide():
	is_sliding = true
	slide_timer = 0.0
	
	# Store slide direction and initial speed
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	slide_direction = (transform.basis.z * input_dir.y + transform.basis.x * input_dir.x).normalized()
	initial_slide_speed = SPRINT_SPEED * SLIDE_SPEED_BOOST

	
	# Don't modify collision shape anymore
	# Let the camera handle the sliding feel


func handle_slide(delta):
	if !is_sliding:
		return
		
	slide_timer += delta
	var slide_progress = slide_timer / SLIDE_DURATION
	
	# Smoother slide transitions
	var tilt_factor = smoothstep(0, 0.2, slide_progress) * (1 - smoothstep(0.8, 1, slide_progress))
	
	# Safely adjust collision height
	var target_height = lerp(original_collision_height, slide_collision_height, tilt_factor)
	var old_height = collision.shape.height
	collision.shape.height = target_height
	
	# Only move camera
	var target_height_cam = original_camera_height - (SLIDE_HEIGHT_CHANGE * tilt_factor)
	camera.position.y = lerp(camera.position.y, target_height_cam, delta * 6.0)
	
	# Calculate slide speed with smooth deceleration
	var speed_factor = 1 - smoothstep(0.2, 0.8, slide_progress)
	var current_slide_speed = lerp(WALK_SPEED, initial_slide_speed, speed_factor)
	
	if slide_direction != Vector3.ZERO:
		velocity.x = slide_direction.x * current_slide_speed
		velocity.z = slide_direction.z * current_slide_speed
	
	if slide_timer >= SLIDE_DURATION:
		end_slide()


func end_slide():
	is_sliding = false
	can_slide = false
	slide_cooldown_timer = SLIDE_COOLDOWN
	
	# Create a smoother tween for transitions
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Smooth collision height reset
	tween.tween_method(
		func(h): collision.shape.height = h,
		collision.shape.height,
		original_collision_height,
		0.4
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Smooth camera position transition
	tween.tween_property(camera, "position:y", original_camera_height, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Reset slide properties smoothly
	slide_camera_tilt = 0.0



func handle_sprint(delta):
	# Check if player is trying to sprint
	if Input.is_action_pressed("sprint") and can_sprint and current_stamina > 0:
		is_sprinting = true
		current_stamina = max(0, current_stamina - STAMINA_DRAIN_RATE * delta)
		
		# Disable sprinting if stamina is depleted
		if current_stamina == 0:
			can_sprint = false
	else:
		is_sprinting = false
		# Regenerate stamina when not sprinting
		if !Input.is_action_pressed("sprint"):
			current_stamina = min(MAX_STAMINA, current_stamina + STAMINA_REGEN_RATE * delta)
			# Re-enable sprinting if stamina is above 25%
			if current_stamina > MAX_STAMINA * 0.25:
				can_sprint = true

func get_current_speed():
	return SPRINT_SPEED if is_sprinting else WALK_SPEED

func start_gravity_flip():
	is_flipping = true
	flip_timer = 0.0
	
	initial_rotation = rotation
	target_rotation = rotation
	target_rotation.z += PI
	
	current_gravity = -current_gravity
	gravity_direction = -gravity_direction
	
	ray_cast.target_position = gravity_direction * 2
	
	# Add momentum bonus when flipping
	current_momentum = min(current_momentum + FLIP_MOMENTUM_BONUS, MAX_MOMENTUM)

func can_jump():
	if gravity_direction.y >= 0:
		return is_on_ceiling()
	return is_on_floor()


func _physics_process(delta):
	if is_flipping:
		handle_flip_animation(delta)
	
	# Update coyote timer
	if can_jump():
		slide_coyote_timer = SLIDE_COYOTE_TIME
		last_grounded_velocity = velocity
	else:
		slide_coyote_timer = max(0, slide_coyote_timer - delta)
	if !can_slide:
		slide_cooldown_timer -= delta
		if slide_cooldown_timer <= 0:
			can_slide = true
	
	handle_sprint(delta)
	handle_momentum(delta)
	handle_audio(delta)
	handle_slide(delta)
	handle_view_bob(delta)
	handle_fov(delta)
	handle_movement_tilt(delta)  # Add this line
	handle_speed_lines(delta)  # Add this line
	
	# Jump handling (both regular and slide jumps)
	if Input.is_action_just_pressed("jump") and can_jump():
		if is_sliding:
			# Slide jump - preserve momentum and add jump velocity
			var current_speed = velocity.length()
			var jump_velocity = -gravity_direction * JUMP_VELOCITY
			var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
			velocity = jump_velocity + (horizontal_velocity * SLIDE_JUMP_MOMENTUM)
			end_slide()
		else:
			# Regular jump
			velocity = -gravity_direction * JUMP_VELOCITY
	
	# Air movement and control
	if !can_jump():
		# Apply gravity
		velocity += gravity_direction * abs(current_gravity) * delta
		
		# Air control
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if input_dir != Vector2.ZERO:
			var forward = transform.basis.z
			var right = transform.basis.x
			var direction = (right * input_dir.x + forward * input_dir.y).normalized()
			
			# Apply air control with momentum preservation
			velocity.x = lerp(velocity.x, direction.x * get_current_speed(), SLIDE_JUMP_CONTROL * delta * 10)
			velocity.z = lerp(velocity.z, direction.z * get_current_speed(), SLIDE_JUMP_CONTROL * delta * 10)
	
	# Ground movement when not sliding
	if !is_sliding and can_jump():
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var forward = transform.basis.z
		var right = transform.basis.x
		var direction = (right * input_dir.x + forward * input_dir.y).normalized()
		
		if direction:
			velocity.x = direction.x * get_current_speed()
			velocity.z = direction.z * get_current_speed()
		else:
			velocity.x = move_toward(velocity.x, 0, get_current_speed())
			velocity.z = move_toward(velocity.z, 0, get_current_speed())

	move_and_slide()

func take_damage(amount):
	current_momentum = max(current_momentum - amount, 0)
	# Check for death immediately when taking damage
	if current_momentum <= 0:
		die()
	
func handle_flip_animation(delta):
	flip_timer += delta
	
	if flip_timer >= flip_duration:
		is_flipping = false
		rotation = target_rotation
	else:
		var t = flip_timer / flip_duration
		t = smoothstep(0, 1, t)
		rotation.z = lerp_angle(initial_rotation.z, target_rotation.z, t)

func smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
