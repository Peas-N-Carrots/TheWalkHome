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

const TOTAL_TRIP_TIME = 15 # 200
const MAX_WOBBLE = 0.005

const FOOTSTEP_TIME = 0.4

@onready var camera : Camera3D = $Camera3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var trip_level : float = 0.0
@export var wobble_curve : Curve
@export var chroma_curve : Curve
@export var nausia_curve : Curve
@export var afterimage_curve : Curve
@export var vignette_curve : Curve
@onready var shader = get_tree().root.find_child("ColorRect", true, false);

@export var audio_curve : Curve
@onready var bus_idx = AudioServer.get_bus_index("Master")
enum effect_id {
	DELAY, LOWPASS, PITCHSHIFT, REVERB, CHORUS, DISTORTION
}
@onready var effects : Dictionary = {
	effect_id.DELAY : AudioServer.get_bus_effect(bus_idx, effect_id.DELAY),
	effect_id.LOWPASS : AudioServer.get_bus_effect(bus_idx, effect_id.LOWPASS),
	effect_id.PITCHSHIFT : AudioServer.get_bus_effect(bus_idx, effect_id.PITCHSHIFT),
	effect_id.REVERB : AudioServer.get_bus_effect(bus_idx, effect_id.REVERB),
	effect_id.CHORUS : AudioServer.get_bus_effect(bus_idx, effect_id.CHORUS),
	effect_id.DISTORTION : AudioServer.get_bus_effect(bus_idx, effect_id.DISTORTION)
}
# Pitch Shift
const AUDIO_PITCH_SCALE = Vector2(1.0, 0.85)
# LPF
const AUDIO_LPF_CUTOFF = Vector2(20000, 2000)
const AUDIO_LPF_RESONANCE = Vector2(0.5, 0.7)
# Reverb
const AUDIO_REVERB_ROOMSIZE = Vector2(0.2, 0.8)
const AUDIO_REVERB_DAMPING = Vector2(0.5, 0.3)
const AUDIO_REVERB_WET = Vector2(0.0, 0.4)
const AUDIO_REVERB_DRY = Vector2(1.0, 0.7)
# Chorus
const AUDIO_CHORUS_VOICE_COUNT = Vector2(2, 4)
const AUDIO_CHORUS_RATE_HZ = Vector2(0.5, 2.0)
const AUDIO_CHORUS_DEPTH_MS = Vector2(2.0, 8.0)
const AUDIO_CHORUS_WET = Vector2(0.0, 0.3)
# Delay
const AUDIO_DELAY_TAP1_MS = Vector2(0, 50)
const AUDIO_DELAY_TAP1_LEVEL_DB = Vector2(-60, -12)
const AUDIO_DELAY_FEEDBACK_LEVEL_DB = Vector2(-60, -20)
# Distortion
const AUDIO_DISTORTION_PRE_GAIN = Vector2(0.0, 3.0)
const AUDIO_DISTORTION_DRIVE = Vector2(0.0, 0.1)
const AUDIO_DISTORTION_POST_GAIN = Vector2(0.0, -2.0)

var time := 1.0

var input_dir := Vector2.ZERO

var walk_time := 0.0

var ground_frame := -100.0
var jump_frame := -100.0

@onready var foot_area = $TripCheck/FootArea
@onready var body_area = $TripCheck/BodyArea
@onready var trip_areas = $TripCheck
var foot_col := false
var body_col := false
var tripped := false

@onready var ragdoll : PackedScene = preload("res://Objects/Player/PlayerDead.tscn")
@onready var spawn_point = get_tree().root.find_child("WorldItems", true, false);
@onready var level = get_tree().root.find_child("Node3D", true, false);

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	foot_area.body_entered.connect(_on_foot_area_enter)
	foot_area.body_exited.connect(_on_foot_area_exit)
	body_area.body_entered.connect(_on_body_area_enter)
	body_area.body_exited.connect(_on_body_area_exit)
	
	set_trip_level(0.0)
	
	$AudioAbience.play()

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
		footstep_audio(delta)
		
		wobble_cam()
		
		apply_gravity(delta)
		get_jump()
		input_to_velocity(delta)
		
		var p_vel := velocity
		
		move_and_slide()
		
		check_trip(p_vel)
		check_fall(p_vel)

func footstep_audio(delta: float) -> void:
	if input_dir && is_on_floor():
		if walk_time >= FOOTSTEP_TIME:
			walk_time = 0.0
			$AudioFootstep.play()
		walk_time += delta
	else:
		walk_time = FOOTSTEP_TIME/2

func update_trip_level() -> void:
	if (calc_trip_level(time) - trip_level > 0.005 || (calc_trip_level(time) == 1.0 && trip_level != 1.0)):
		set_trip_level(calc_trip_level(time))

func calc_trip_level(t: float) -> float:
	return clamp(t / TOTAL_TRIP_TIME, 0.0, 1.0)

func set_trip_level(level: float) -> void:
	trip_level = level
	shader.update(chroma_curve.sample(trip_level), nausia_curve.sample(trip_level), afterimage_curve.sample(trip_level), vignette_curve.sample(trip_level))
	update_audio(audio_curve.sample(trip_level))

func update_audio(progress: float) -> void:
	effects[effect_id.LOWPASS].cutoff_hz = lerpf(AUDIO_LPF_CUTOFF[0], AUDIO_LPF_CUTOFF[1], progress)
	effects[effect_id.LOWPASS].resonance = lerpf(AUDIO_LPF_RESONANCE[0], AUDIO_LPF_RESONANCE[1], progress)
	effects[effect_id.REVERB].room_size = lerpf(AUDIO_REVERB_ROOMSIZE[0], AUDIO_REVERB_ROOMSIZE[1], progress)
	effects[effect_id.REVERB].damping = lerpf(AUDIO_REVERB_DAMPING[0], AUDIO_REVERB_DAMPING[1], progress)
	effects[effect_id.REVERB].wet = lerpf(AUDIO_REVERB_WET[0], AUDIO_REVERB_WET[1], progress)
	effects[effect_id.REVERB].dry = lerpf(AUDIO_REVERB_DRY[0], AUDIO_REVERB_DRY[1], progress)

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
		die(p_vel)

func die(p_vel : Vector3 = Vector3.ZERO) -> void:
		if !tripped:
			tripped = true
			var tween = create_tween()
			tween.tween_property(camera, "position", Vector3(0, 1.5, 2), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			spawn_ragdoll(p_vel)
			visible = false
			$AudioFall.play()
			level.player_die()

func spawn_ragdoll(p_vel: Vector3 = Vector3.ZERO) -> void:
	var new_ragdoll = ragdoll.instantiate()
	spawn_point.add_child(new_ragdoll)
	new_ragdoll.global_transform = self.global_transform
	
	if p_vel != Vector3.ZERO:
		new_ragdoll.linear_velocity = p_vel
	else:
		new_ragdoll.linear_velocity = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized() * 2
	
	new_ragdoll.angular_velocity = Vector3(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))

func win_game() -> void:
	print("Won!")
