extends CharacterBody3D

const ACCEL_SPEED = 8
const DECEL_SPEED = 6
const RUN_SPEED = 2.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.0015
const JUMP_BUFFER = 0.5
const COYOTE_TIME = 0.5

const TRIP_VEL_THRESH = 0.7
const FALL_VEL_THRESH = 10.0

const TOTAL_TRIP_TIME = 20
const MAX_WOBBLE = 0.005

@onready var camera : Camera3D = $Camera3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var trip_level : float = 0.0
@export var wobble_curve : Curve
@export var chroma_curve : Curve
@export var nausia_curve : Curve
@export var afterimage_curve : Curve
@export var vignette_curve : Curve
@onready var shader = get_tree().root.find_child("ColorRect", true, false);

var time := 1.0

var input_dir := Vector2.ZERO

var ground_frame := -100.0
var jump_frame := -100.0

@onready var foot_area = $TripCheck/FootArea
@onready var body_area = $TripCheck/BodyArea
@onready var trip_areas = $TripCheck
var foot_col := false
var body_col := false
var tripped := false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	foot_area.body_entered.connect(_on_foot_area_enter)
	foot_area.body_exited.connect(_on_foot_area_exit)
	body_area.body_entered.connect(_on_body_area_enter)
	body_area.body_exited.connect(_on_body_area_exit)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
	time += delta
	
	update_trip_level()
	
	get_input()
	
	if !tripped:
		wobble_cam()
		
		apply_gravity(delta)
		get_jump()
		input_to_velocity(delta)
		
		var p_vel := velocity
		
		move_and_slide()
		
		check_trip(p_vel)
		check_fall(p_vel)

func update_trip_level() -> void:
	if (calc_trip_level(time) - trip_level > 0.01 || (calc_trip_level(time) == 1.0 && trip_level != 1.0)):
		set_trip_level(calc_trip_level(time))

func calc_trip_level(t: float) -> float:
	return clamp(t / TOTAL_TRIP_TIME, 0.0, 1.0)

func set_trip_level(level: float) -> void:
	trip_level = level
	shader.update(chroma_curve.sample(trip_level), nausia_curve.sample(trip_level), afterimage_curve.sample(trip_level), vignette_curve.sample(trip_level))

func get_jump_frame() -> bool:
	return time - jump_frame < JUMP_BUFFER

func get_ground_frame() -> bool:
	return time - ground_frame < COYOTE_TIME

func wobble_cam() -> void:
	var offset = Vector2(sin(time * 1.53 + 4.8), sin(time * 2.8)) * MAX_WOBBLE * wobble_curve.sample(trip_level)
	rotate_y(offset.y)
	camera.rotate_x(offset.x)
	camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func get_input() -> void:
	input_dir = Input.get_vector("Left", "Right", "Forwards", "Backwards")
	if Input.is_action_just_pressed("Jump"): jump_frame = time
	if is_on_floor(): ground_frame = time
	
	trip_areas.rotation.y = atan2(-input_dir.x, -input_dir.y)

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

func _on_foot_area_enter(body) -> void:
	foot_col = true;

func _on_foot_area_exit(body) -> void:
	foot_col = false;

func _on_body_area_enter(body) -> void:
	body_col = true;

func _on_body_area_exit(body) -> void:
	body_col = false;

func check_fall(p_vel: Vector3) -> void:
	if (-(p_vel.y - velocity.y) > FALL_VEL_THRESH && is_on_floor()):
		die()

func check_trip(p_vel: Vector3) -> void:
	if (foot_col && !body_col && is_on_wall() &&
	(Vector2(p_vel.x, p_vel.z).length() / RUN_SPEED) - (Vector2(velocity.x, velocity.z).length() / RUN_SPEED)
	> TRIP_VEL_THRESH):
		die()

func die() -> void:
		if !tripped:
			tripped = true
			var tween = create_tween()
			tween.tween_property(camera, "position", Vector3(0, 1.5, 2), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
