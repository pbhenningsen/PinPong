extends Node

@export var input_motion: float

func _ready():
	print("INPUT AUTHORITY ID: " + str(get_multiplayer_authority()))

func _process(delta):
	# Is the master of the paddle.
	if is_multiplayer_authority(): #Checking to make sure you're the peer that has control of the player. 
		input_motion = Input.get_axis(&"move_up", &"move_down")
