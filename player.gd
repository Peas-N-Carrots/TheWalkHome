extends CharacterBody3D

const ACCEL_SPEED = 12
const DECEL_SPEED = 6
const RUN_SPEED = 2.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.0015
const JUMP_BUFFER = 0.5
const COYOTE_TIME = 0.5

const MAX_WOBBLE = 0.005

@onready var camera : Camera3D = $Camera3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var trip_level : float = 0.0
var time := 0.0

var input_dir := Vector2.ZERO

var ground_frame := 0.0
var jump_frame := 0.0

var tripped := false

@onready var col_foot : RayCast3D = $Rays/FootRaycast
@onready var col_body : RayCast3D = $Rays/BodyRaycast

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	time += delta
	get_input()
	
	if !tripped:
		wobble_cam()
		
		apply_gravity(delta)
		get_jump()
		input_to_velocity(delta)
		
		move_and_slide()
		
		check_trip()

func get_jump_frame() -> bool:
	return time - jump_frame < JUMP_BUFFER

func get_ground_frame() -> bool:
	return time - ground_frame < COYOTE_TIME

func wobble_cam() -> void:
	var offset = Vector2(sin(time * 1.53 + 4.8), sin(time * 2.8)) * MAX_WOBBLE * trip_level
	rotate_y(offset.y)
	camera.rotate_x(offset.x)
	camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func get_input() -> void:
	input_dir = Input.get_vector("Left", "Right", "Forwards", "Backwards")
	if Input.is_action_just_pressed("Jump"): jump_frame = time
	if is_on_floor(): ground_frame = time

func get_jump() -> void:
	if get_jump_frame() and get_ground_frame():
		velocity.y = JUMP_VELOCITY
		jump_frame = -100
		ground_frame = -100

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func input_to_velocity(delta: float) -> void:
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() #+ (MAX_WOBBLE * trip_level * offset)
	
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * RUN_SPEED, ACCEL_SPEED * delta)
		velocity.z = move_toward(velocity.z, direction.z * RUN_SPEED, ACCEL_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, DECEL_SPEED * delta)
		velocity.z = move_toward(velocity.z, 0, DECEL_SPEED * delta)

func check_trip() -> void:
	if (col_foot.is_colliding() && !col_body.is_colliding()):
		tripped = true
		var tween = create_tween()
		tween.tween_property(camera, "position", Vector3(0, 3, 5), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
