extends Area2D

const SPEED = 200
var motion := 0.0
@export var left := false

@onready var screen_h := get_viewport_rect().size.y

func _init():
	var player_name = Globals.player_entry["name"]
	var player_pin = Globals.player_entry["pin"]


func _process(delta):
	if is_multiplayer_authority():
		var dir = Input.get_axis(&"move_up", &"move_down")
		_send_input.rpc_id(1, dir) # always send to server (ID 1)

func _physics_process(delta):
	position.y = clamp(position.y + motion * delta, 16, screen_h - 16)

# Client → Server
@rpc("authority")
func _send_input(dir: float):
	if multiplayer.is_server():
		motion = dir * SPEED
		_sync_state.rpc(position, motion)

# Server → Clients
@rpc("unreliable")
func _sync_state(pos: Vector2, mot: float):
	position = pos
	motion = mot
