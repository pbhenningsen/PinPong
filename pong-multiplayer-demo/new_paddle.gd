extends Area2D

const MOTION_SPEED = 150

@onready var player_input: Node = $PlayerInput

@export var player := 1:
	set(id):
		player = id
		$PlayerInput.set_multiplayer_authority(id)

@export var left = false
@export var _motion = 0#represents its speed
@export var _pos: Vector2

@onready var _screen_size_y = 400

signal set_name_and_pin(paddle_side, player_name, player_pin)

func _ready():
	if multiplayer.is_server():
		Globals._both_players_registered.connect(_set_label_text)
		_pos = position
		area_entered.connect(_on_paddle_area_enter)
	if not multiplayer.is_server():
		set_process(false)
		set_physics_process(false)
		
func _physics_process(delta):
	_apply_input(delta)

func _apply_input(delta: float):
	_motion = player_input.input_motion *MOTION_SPEED
	translate(Vector2(0, _motion * delta))
	# Set screen limits.
	position.y = clamp(position.y, 17, _screen_size_y - 17)
	

func _set_label_text():
	var player_name = Globals.connected_players[player]["name"]
	var player_pin = Globals.connected_players[player]["pin"]
	var paddle_side
	if left == true: 
		paddle_side = 1
	else:
		paddle_side = 2
	set_name_and_pin.emit(paddle_side, player_name, player_pin)
	

func set_player_name(value):
	$You.text = value

func _on_paddle_area_enter(area):
	if multiplayer.is_server():
	
		## Random for new direction generated checked each peer.
			area.bounce(left, randf())#As you can see, the clients are allowed to call the bounce RPC. 
