extends Area3D

const CAR_SPEED = 14.5

var vel: Vector3 = Vector3.ZERO

func _process(delta: float) -> void:
	global_position += vel * delta

func set_speed() -> void:
	vel = global_transform.basis.z * CAR_SPEED

func destroy_car() -> void:
	queue_free()
