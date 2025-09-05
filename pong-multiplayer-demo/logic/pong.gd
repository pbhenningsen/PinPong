extends Node2D

signal game_finished()

const SCORE_TO_WIN = 10

var score_left = 0
var score_right = 0

var players_in_match = 0

var connected_players = {}

@onready var score_left_node = $ScoreLeft
@onready var score_right_node = $ScoreRight
@onready var winner_left = $WinnerLeft
@onready var winner_right = $WinnerRight

func _ready():
	if not multiplayer.is_server():
		return
		
	multiplayer.peer_connected.connect(_on_player_connected) ##This represents clients connecting to the server. 
	multiplayer.peer_disconnected.connect(del_player)
	multiplayer.connected_to_server.connect(_on_connected_ok)
		
	#for id in multiplayer.get_peers():
		#add_player(id)
		

	print("Unique id: ", multiplayer.get_unique_id())
	
func _on_player_connected(id: int):
	print("_on_player_connected is running")
	print("I am " + str(multiplayer.get_unique_id()) + " and this is the player that just connected to us: " + str(id),)
	#FIX THIS PART
	awaken_client.rpc_id(id)
	print("THIS IS WHERE WE NEED TO REGISTER THE PLAYER")
	print("Let's take a look at what the Globals player_entry looks like: " + str(Globals.player_entry))
	#if !multiplayer.is_server():
		#register_player.rpc_id(1, Globals.player_entry["name"], Globals.player_entry["pin"])
	print("This is where we call add_player")
	add_player(id)

func _on_connected_ok():
	var player_id = multiplayer.get_unique_id()
	print("on_connected just ran, and I am the one running it: " + str(player_id))
	print(str)
	
	
@rpc("any_peer", "call_local")
func awaken_client():
	print("register player is running, and I, " + str(multiplayer.get_unique_id()) + " am the one running it")
	print("register player is runing and I, " + str(multiplayer.get_remote_sender_id()) + " am the one sending it.") 
	var player_id = multiplayer.get_unique_id()
	var player_name = Globals.player_entry["name"]
	var player_pin = Globals.player_entry["pin"]
	register_player.rpc(player_id, player_name, player_pin)
	print("This is what my global player entry currently looks like " + str(Globals.player_entry))

	
	
@rpc("any_peer", "call_local")
func register_player(player_id, player_name, player_pin):
	connected_players[player_id] = {}
	connected_players[player_id]["name"] = player_name
	connected_players[player_id]["pin"] = player_pin
	print("This is what connected players looks like(after the register_player rpc call: " + str(connected_players))
	
	

	
	
#func request_spawn():
	#var player_name = Globals.player_entry["name"]
	#var player_pin = Globals.player_entry["pin"]
	#var player_id = multiplayer.get_unique_id()
	#register_player.rpc_id(1, player_id, player_name, player_pin)
	#add_player.rpc_id(1, player_id, player_name, player_pin)
	
	
	
	
@rpc("any_peer", "call_local")
func add_player(id):
	players_in_match += 1
	print("add_player is running")
	var paddle = preload("res://paddle.tscn").instantiate()
	var player_name = Globals.player_entry["name"]
	var player_pin = Globals.player_entry["pin"]
	var player_id = multiplayer.get_unique_id()
	awaken_client.rpc_id(id)
	paddle.player = id
	if players_in_match == 1:
		paddle.position = Vector2(32, 180)
	elif players_in_match == 2:
		paddle.position = Vector2(600, 180)
		paddle.left = true
	paddle.name = str(id)
	$Players.add_child(paddle, true)
	
	
func del_player():
	print("SOME BITCH DISCONNECTED")

@rpc("any_peer", "call_local") #Remember, the client is PART of the game. It may be easier, in your case, to usee a synchronizer of some kind. Or, you might have to adjust this RPC call. You should be using "call_remote"
func update_score(add_to_left):
	if add_to_left:
		score_left += 1
		score_left_node.set_text(str(score_left))
	else:
		score_right += 1
		score_right_node.set_text(str(score_right))

	var game_ended = false
	if score_left == SCORE_TO_WIN:
		winner_left.show()
		game_ended = true
	elif score_right == SCORE_TO_WIN:
		winner_right.show()
		game_ended = true

	if game_ended:
		$ExitGame.show()
		$Ball.stop.rpc()
		
func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)

func _on_exit_game_pressed():
	game_finished.emit()
