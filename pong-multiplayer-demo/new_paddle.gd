extends Area2D

const MOTION_SPEED = 150

@onready var player_input: Node = $PlayerInput

@onready var you: Label = $You

@export var player := 1:
	set(id):
		print("Set ID ran, here is the ID it set:" + str(id))
		player = id
		$PlayerInput.set_multiplayer_authority(id)
		print("This is what Global.connected_players looks like in init " + str(Globals.connected_players) + "for player " + str(player))
		#$You.text = Globals.connected_players[player]["name"]


@export var left = false

var _motion = 0
var _you_hidden = false


@onready var _screen_size_y = get_viewport_rect().size.y

signal set_name_and_pin(paddle_side, player_name, player_pin)

#
#func _init():
	#print("running_init")
	#if left == true:
		#var player_1_name = Globals.connected_players[player]["name"]
		#var player_1_pin = Globals.connected_players[player]["pin"]
		#paddle_side_set.emit(1, player_1_name, player_1_pin)
	#else:
		#var player_2_name = Globals.connected_players[player]["name"]
		#var player_2_pin = Globals.connected_players[player]["pin"]
		#paddle_side_set.emit(2, player_2_name, player_2_pin)
	#for key in Globals.connected_players:
		#print(str(key))

func _ready():
	Globals._both_players_registered.connect(_set_label_text)
	if not multiplayer.is_server():
		set_process(false)
		
func _physics_process(delta):
	if multiplayer.is_server():
		_apply_input(delta)
	else: 
		move(delta)

func _apply_input(delta: float):
	_motion = player_input.input_motion *MOTION_SPEED
	translate(Vector2(0, _motion * delta))
	# Set screen limits.
	position.y = clamp(position.y, 16, _screen_size_y - 16)
	
func move(delta):
	pass

func _set_label_text():
	$You.text = Globals.connected_players[player]["name"]
	var player_name = Globals.connected_players[player]["name"]
	var player_pin = Globals.connected_players[player]["pin"]
	var paddle_side
	if left == true: 
		paddle_side = 1
	else:
		paddle_side = 2
	set_name_and_pin.emit(paddle_side, player_name, player_pin)
	

func _process(delta):
	# Is the master of the paddle.
	if is_multiplayer_authority(): #Checking to make sure you're the peer that has control of the player. 
		_motion = Input.get_axis(&"move_up", &"move_down")# the & symbols are just there for the sake of efficiency. 

		if not _you_hidden and _motion != 0:
			_hide_you_label()

		_motion *= MOTION_SPEED

		# Using unreliable to make sure position is updated as fast
		# as possible, even if one of the calls is dropped.
		set_pos_and_motion.rpc(position, _motion)# I guess that instead of calling this, the PlayerInput will replicate it? T
	else:
		if not _you_hidden:
			_hide_you_label()

	translate(Vector2(0, _motion * delta)) # I think this is sort of its move_and_slide (but not, because its an Area2D)

	# Set screen limits.
	position.y = clamp(position.y, 16, _screen_size_y - 16)

#Synchronize position and speed to the other peers.
@rpc("authority", "unreliable", "call_remote") #This is where the RPC synchronization shit is hap
func set_pos_and_motion(pos, motion):
	position = pos
	_motion = motion


func _hide_you_label():
	_you_hidden = true
	get_node(^"You").hide()

func set_player_name(value):
	$You.text = value

#func _on_paddle_area_enter(area):
	#if is_multiplayer_authority():
		## Random for new direction generated checked each peer.
		#area.bounce.rpc(left, randf())#As you can see, the clients are allowed to call the bounce RPC. 
