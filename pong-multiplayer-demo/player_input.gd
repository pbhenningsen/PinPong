extends Node

@onready var paddle: Area2D = $".."
@onready var screen_size_y_for_input
@onready var INPUT_MOTION_SPEED = 150.0

@export 
var input_motion = Vector2():
	set(value):
		input_motion = clamp(paddle.position.y, 16, screen_size_y_for_input - 16)


func update():
	var m = Vector2()
	m = Input.get_axis(&"move_up", &"move_down") * INPUT_MOTION_SPEED
	input_motion = m
	
	
	
