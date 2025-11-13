extends RigidBody3D

const MIN_VEL = 1.0

var p_vel = Vector3.ZERO

func _physics_process(delta):
	if (linear_velocity - p_vel).length() >= MIN_VEL:
		$AudioImpact.play()
	p_vel = linear_velocity
