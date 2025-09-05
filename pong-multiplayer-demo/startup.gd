extends Node

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1" # change this to your IP if you're using a remote server

const gameplay_level = "res://pong.tscn"
const lobby_room = "res://lobby_room.tscn"

@onready var ui: Control = $UI
@onready var lobby_placeholder: Node = $LobbyPlaceholder
@onready var level_node: Node = $Level
@onready var player_name: LineEdit = $UI/StartupPanel/Name
@onready var player_pin: LineEdit = $UI/StartupPanel/Pin

#Player Info For Game
var player_name_for_game
var player_pin_for_game

#var connected_players = {}

signal both_players_registered

func _ready():
	multiplayer.connected_to_server.connect(_send_player_data)
	if OS.has_feature("dedicated_server"):
		# if this is a dedicated server, run as a server
		_on_host_pressed()

func _send_player_data():
	var player_id = multiplayer.get_unique_id()
	var player_name = Globals.player_entry["name"]
	var player_pin = Globals.player_entry["pin"]
	register_player.rpc(player_id, player_name, player_pin)
	
@rpc("any_peer", "call_local")
func register_player(player_id, player_name, player_pin):
	Globals.connected_players[player_id] = {}
	Globals.connected_players[player_id]["name"] = player_name
	Globals.connected_players[player_id]["pin"] = player_pin
	print("This is what connected players looks like(after the register_player rpc call: " + str(Globals.connected_players))
	print("This is the size of global.connected_players: " + str(Globals.connected_players.size()))
	if Globals.connected_players.size() > 1:
		Globals._both_players_registered.emit()
	
	

func _on_host_pressed():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(SERVER_PORT)
	multiplayer.multiplayer_peer = peer
	start_game()

func start_game():
	print("start_game is running")
	$UI.hide()
	if multiplayer.is_server():#notice that only the sever is being told to change levels. 
		print("server changing to level scene...")
		change_level.call_deferred(load(gameplay_level))#TTHIS IS WHERE WE FIRST CONNECT TO THE SERVER, THIS IS WHERE I COULD CAUSE THE CLIENTS TO COME TO LIFE. 
		
		
func change_level(scene: PackedScene):
	print("change_level is running")
	var level = level_node
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	level.add_child(scene.instantiate())
	

func _on_client_pressed(ip = SERVER_IP, port = SERVER_PORT):
	print("about to start game")
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	multiplayer.multiplayer_peer = peer
	start_game()
#
func _on_find_match_pressed():
	#print("Find match pressed!")
	$UI.hide()
	var player_id = str(randi() % 1000)
	var player_entry = {
		"pin": player_pin.text,
		"playerId": player_id,
		"username": player_name.text,
		"rank": "311",
		"team": 0
	}

	var player_name = player_name.text
	var lobby = preload(lobby_room).instantiate()
	print("This is where we initially store the player's name and pin, first in their Globals folder, and next in the variable in lobby.gd called player_entry")
	lobby.player_entry = player_entry # I NEED TO STORE THIS IN THE GAMEPLAY LEVEL TOO
	Globals.player_entry["name"] = player_entry["username"]
	Globals.player_entry["pin"] = player_entry["pin"]
	lobby.start_client.connect(start_client)# The host has already connected to the server, but we (the client )haven't...we're wiating until the lobby (tell sus
	lobby_placeholder.add_child(lobby)

func start_client(ip = SERVER_IP, port = SERVER_PORT):
	_on_client_pressed(ip,port)
	lobby_placeholder.get_child(0).hide()


	
