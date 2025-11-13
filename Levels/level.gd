extends Node3D

const FADE_T = 1.0
const DIE_T = 3.0
const HOLD_R_TIME = 3.0

var start_f : float = 0.0
var hold_r : float = 0.0
var player_dead : bool = false
var die_f : float = 0.0
var fade_f : float = 0.0

var fullscreen := false

var fade_in := true

@onready var player = get_tree().root.find_child("CharacterBody3D", true, false);
@onready var shader = get_tree().root.find_child("ColorRect", true, false);

func _process(delta: float) -> void:
	if Input.is_action_pressed("Quit"):
		get_tree().quit()
	
	if start_f < FADE_T:
		start_f += delta
		shader.fade(start_f/FADE_T)
	else:
		if fade_in:
			fade_in = false
			shader.fade(1.0)
		
		if Input.is_action_pressed("Restart"):
			hold_r += delta
			if hold_r >= HOLD_R_TIME:
				player_die()
		else:
			hold_r = 0.0
		
		if player_dead:
			if die_f < DIE_T:
				die_f += delta
			else:
				fade_f += delta
				shader.fade(1 - fade_f/FADE_T)
				if fade_f >= FADE_T:
					get_tree().reload_current_scene()

func player_die() -> void:
	player_dead = true
	if !player.tripped:
		player.die()
