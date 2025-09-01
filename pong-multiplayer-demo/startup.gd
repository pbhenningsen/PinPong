extends Node

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1" # change this to your IP if you're using a remote server

const gameplay_level = "res://pong_experiment.tscn"
const lobby_room = "res://lobby_room.tscn"

@onready var ui: Control = $UI
@onready var lobby_placeholder: Node = $LobbyPlaceholder
@onready var level_node: Node = $Level
@onready var player_name: LineEdit = $UI/StartupPanel/Name
@onready var player_pin: LineEdit = $UI/StartupPanel/Pin


func _ready():
	if OS.has_feature("dedicated_server"):
		# if this is a dedicated server, run as a server
		_on_host_pressed()

func _on_host_pressed():
	print("host pressed")
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(SERVER_PORT)
	multiplayer.multiplayer_peer = peer
	start_game()

func start_game():
	$UI.hide()
	
	if multiplayer.is_server():
		print("server changing to level scene...")
		change_level.call_deferred(load(gameplay_level))
		
func change_level(scene: PackedScene):
	var level = level_node
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
		
	level.add_child(scene.instantiate())

func _on_client_pressed(ip = SERVER_IP, port = SERVER_PORT):
	print("client pressed")
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	multiplayer.multiplayer_peer = peer
	start_game()
#
func _on_find_match_pressed():
	print("Find match pressed!")
	$UI.hide()
	
	var player_id = str(randi() % 1000)
	var player_entry = {
		"playerId": player_id,
		"username": player_name.text + " " + player_id,
		"rank": "311",
	}
	print(player_entry)
	
	var lobby = preload(lobby_room).instantiate()
	lobby.player_entry = player_entry
	
	lobby.start_client.connect(start_client)
	lobby_placeholder.add_child(lobby)

func start_client(ip = SERVER_IP, port = SERVER_PORT):
	print("start_client %s, %s" % [ip, port])
	_on_client_pressed(ip,port)
