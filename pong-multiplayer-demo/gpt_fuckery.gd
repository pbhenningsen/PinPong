extends Node2D

@onready var players := $Players
@onready var ball := $Ball

var player_positions = [Vector2(32, 180), Vector2(600, 180)]
var next_slot := 0

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	if multiplayer.is_server():
		print("Server: Pong scene ready")
		# spawn ball on server
		#_spawn_ball()

func _on_peer_connected(id: int):
	if not multiplayer.is_server():
		return
	print("Server: spawning paddle for %s" % id)
	_spawn_paddle(id)

func _on_peer_disconnected(id: int):
	if players.has_node(str(id)):
		players.get_node(str(id)).queue_free()

func _spawn_paddle(id: int):
	if id == 1: # skip dedicated server
		return
	var paddle = preload("res://paddle.tscn").instantiate()
	paddle.name = str(id)
	paddle.position = player_positions[next_slot]
	paddle.set_multiplayer_authority(id)
	if next_slot == 1:
		paddle.left = true
	next_slot = (next_slot + 1) % 2
	players.add_child(paddle, true)

#func _spawn_ball():
	#if not multiplayer.is_server():
		#return
	#var ball_scene = preload("res://ball.tscn").instantiate()
	#$Ball.add_child(ball_scene, true)
