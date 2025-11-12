extends RigidBody3D

const MIN_VEL = 2.0

var p_vel = Vector3.ZERO

#func _on_body_entered(body: Node) -> void:
	#if true || linear_velocity.length() > MIN_VEL:
		#$AudioImpact.play()

func _physics_process(delta):
	if (linear_velocity - p_vel).length() >= MIN_VEL:
		$AudioImpact.play()
	p_vel = linear_velocity
