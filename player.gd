extends CharacterBody3D

const ACCEL_SPEED = 0.2
const DECEL_SPEED = 0.1
const RUN_SPEED = 4.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.0015

const MAX_WOBBLE = 0.005

@onready var camera = $Camera3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var trip_level : float = 0.0;
var time := 0.0;

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	time += delta
	var offset = Vector2(sin(time * 1.53 + 4.8), sin(time * 2.8)) * MAX_WOBBLE * trip_level;
	
	rotate_y(offset.y)
	camera.rotate_x(offset.x)
	camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var input_dir = Input.get_vector("Left", "Right", "Forwards", "Backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() #+ (MAX_WOBBLE * trip_level * offset)
	
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * RUN_SPEED, ACCEL_SPEED)
		velocity.z = move_toward(velocity.z, direction.z * RUN_SPEED, ACCEL_SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, DECEL_SPEED)
		velocity.z = move_toward(velocity.z, 0, DECEL_SPEED)
	
	move_and_slide()
