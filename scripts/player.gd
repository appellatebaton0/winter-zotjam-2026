class_name Player extends CharacterBody2D

# Light

var light_amount := 1.0
@onready var light := $PointLight2D

# Gun

@onready var gun_pivot := $Pivot
@onready var shoot_point := $Pivot/ShootPoint

@onready var bullet_scene := preload("res://scenes/bullet.tscn")

# Movement

@export var max_speed := 40.0
@export var acceleration := 5.0
@export var friction := 7.0

@export var jump_velocity := 100.0

@export var jump_buffering := 0.1
@export var coyote_time := 0.1
var jump_buffer := 0.0
var coyote_timer := 0.0

var wall_normal := 0.0
var is_wall_jump = false

func _physics_process(delta: float) -> void:
	coyote_timer = move_toward(coyote_timer, 0, delta)
	jump_buffer = move_toward(jump_buffer, 0, delta)
	
	# Gravity
	if not is_on_floor(): 
		velocity += get_gravity() * delta
	
	# Jumping
	else: 
		coyote_timer = coyote_time
		is_wall_jump = false
	
	if is_on_wall_only(): 
		coyote_timer = coyote_time
		wall_normal = get_wall_normal().x
		is_wall_jump = true
	
	if Input.is_action_just_pressed("Jump"): jump_buffer = jump_buffering
	
	if coyote_timer and jump_buffer:
		velocity.y = -jump_velocity
		
		if is_wall_jump: velocity.x = jump_velocity * wall_normal * 0.9
		
		coyote_timer = 0
		jump_buffer = 0
	
	# Movement
	var direction = Input.get_axis("Left", "Right")
	
	if direction:
		velocity.x = move_toward(velocity.x, max_speed * direction, acceleration * 60 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * 60 * delta * (1.0 if is_on_floor() else 0.4))
	
	move_and_slide()

func _process(delta: float) -> void:
	
	# Light
	
	light_amount = move_toward(min(light_amount, 2.0), 0.0, delta)
	
	light.texture_scale = clamp(light_amount, 0.4, 1.5)
	
	
	# Gun
	
	var mouse_pos := get_global_mouse_position()
	
	gun_pivot.look_at(mouse_pos)
	
	if Input.is_action_just_pressed("Fire") and has_bullets():
		# Fire
		
		var new:Bullet = bullet_scene.instantiate()
		
		var level := get_tree().get_first_node_in_group("Level")
		
		level.add_child(new)
		
		new.direction = global_position.direction_to(shoot_point.global_position)
		new.global_position = shoot_point.global_position

func has_bullets() -> bool: return true
