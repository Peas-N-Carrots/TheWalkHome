extends Node3D

const MAX_COOLDOWN = 11.0
const MIN_COOLDOWN = 5.0
const QUICK_COOLDOWN = 0.7

const QUICK_COOLDOWN_CHANCE = 0.2

var cooldown : float

@onready var car : PackedScene = preload("res://Objects/Car/Car.tscn")
@onready var spawn_point = get_tree().root.find_child("WorldItems", true, false);

func _ready() -> void:
	visible = false;
	set_cooldown()

func _process(delta: float) -> void:
	cooldown -= delta
	if cooldown <= 0:
		set_cooldown()
		spawn_car()

func set_cooldown() -> void:
	if randf() < QUICK_COOLDOWN_CHANCE:
		cooldown = QUICK_COOLDOWN
	else:
		cooldown = randf_range(MIN_COOLDOWN, MAX_COOLDOWN)

func spawn_car() -> void:
	var new_car = car.instantiate()
	spawn_point.add_child(new_car)
	new_car.global_transform = self.global_transform
	new_car.set_speed()
