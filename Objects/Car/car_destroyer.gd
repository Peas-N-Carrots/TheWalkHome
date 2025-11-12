extends Area3D

func _on_area_entered(area: Area3D) -> void:
	if area.has_method("destroy_car"):
		area.destroy_car()
