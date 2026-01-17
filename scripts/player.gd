class_name Player extends CharacterBody2D

@export var max_speed := 20.0
@export var acceleration := 5.0
@export var friction := 7.0

@export var jump_velocity := 100.0

@export var jump_buffering := 0.1
@export var coyote_time := 0.1
var jump_buffer := 0.0
var coyote_timer := 0.0


func _physics_process(delta: float) -> void:
	coyote_timer = move_toward(coyote_timer, 0, delta)
	jump_buffer = move_toward(jump_buffer, 0, delta)
	
	# Gravity
	if not is_on_floor(): velocity += get_gravity() * delta
	
	# Jumping
	else: coyote_timer = coyote_time
	
	if Input.is_action_just_pressed("Jump"): jump_buffer = jump_buffering
	
	if coyote_timer and jump_buffer:
		velocity.y -= jump_velocity
		
		coyote_timer = 0
		jump_buffer = 0
	
	# Movement
	var direction = Input.get_axis("Left", "Right")
	
	if direction:
		velocity.x = move_toward(velocity.x, max_speed * direction, acceleration * 60 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * 60 * delta)
	
	move_and_slide()
