extends Node

const SERVER_PORT = 8080
#const SERVER_IP = "ec2-3-131-137-106.us-east-2.compute.amazonaws.com" # change this to your IP if you're using a remote server
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
	if OS.has_feature("dedicated_server"):
		_become_host()
	$GameTitle/Logo.hide()
	Globals.new_match.connect(_new_match_pressed)

func _on_start_game_pressed() -> void:
	$GameTitle/TitleLabel.hide()
	$GameTitle/StartButton.hide()
	$GameTitle/Logo.show()
	$GameTitle/AnimationPlayer.play("logo_fade_in")
	multiplayer.connected_to_server.connect(_send_player_data)
	if OS.has_feature("dedicated_server"):
		# if this is a dedicated server, run as a server
		_become_host()
	await get_tree().create_timer(3.0).timeout
	$GameTitle.hide()



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
	if Globals.connected_players.size() > 1:
		Globals._both_players_registered.emit()
	
	

func _become_host():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(SERVER_PORT)
	multiplayer.multiplayer_peer = peer
	start_game()
	

func start_game():
	$UI.hide()
	if multiplayer.is_server():#notice that only the sever is being told to change levels. 
		change_level.call_deferred(load(gameplay_level))#TTHIS IS WHERE WE FIRST CONNECT TO THE SERVER, THIS IS WHERE I COULD CAUSE THE CLIENTS TO COME TO LIFE. 
		
		
func change_level(scene: PackedScene):
	var level = level_node
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	level.add_child(scene.instantiate())
	
#
#func _on_client_pressed(ip = SERVER_IP, port = SERVER_PORT):
	#var peer = ENetMultiplayerPeer.new()
	#peer.create_client(SERVER_IP, SERVER_PORT)
	#multiplayer.multiplayer_peer = peer
	#start_game()
##

#I THINK THIS NEEDS TO BE AN RPC?
func _new_match_pressed():
	if multiplayer.is_server():
		_clear_game.rpc()
	
	
	
@rpc("call_local")
func _clear_game():
	print("clear game called")
	$Level.get_child(0).queue_free()	
	$LobbyPlaceholder.get_child(0).queue_free()

	

func _on_find_match_pressed():
	if !(player_pin.text.is_valid_int() && player_pin.text.length() == 4):
		$UI/ValidPIN.show()
		await get_tree().create_timer(1.0).timeout
		$UI/ValidPIN.hide()
		return
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
	lobby.player_entry = player_entry # I NEED TO STORE THIS IN THE GAMEPLAY LEVEL TOO
	Globals.player_entry["name"] = player_entry["username"]
	Globals.player_entry["pin"] = player_entry["pin"]
	lobby.start_client.connect(start_client)# The host has already connected to the server, but we (the client )haven't...we're wiating until the lobby (tell sus
	lobby_placeholder.add_child(lobby)

func start_client(ip = SERVER_IP, port = SERVER_PORT):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	multiplayer.multiplayer_peer = peer
	start_game()
	lobby_placeholder.get_child(0).hide()
