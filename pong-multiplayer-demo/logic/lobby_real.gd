extends Control

# Default game server port. Can be any number between 1024 and 49151.
# Not present on the list of registered or common ports as of December 2022:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 8910# Remember, a port is a label for a process.

@onready var address = $Address
@onready var host_button = $HostButton
@onready var join_button = $JoinButton
@onready var status_ok = $StatusOk
@onready var status_fail = $StatusFail
@onready var port_forward_label = $PortForward
@onready var find_public_ip_button = $FindPublicIP
@onready var pin: LineEdit = $Pin


var peer = null

func _ready():
	# Connect all the callbacks related to networking.

	multiplayer.peer_connected.connect(_player_connected) #Emitted when this MultiplayerAPI's multiplayer_peer connects with a new peer. 
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok)# Emitted when this Multiplayer API's multiplayer_peer successfully connected to a server. Only emitted on clients. 
	multiplayer.connection_failed.connect(_connected_fail) # Only emitted on clients. 
	multiplayer.server_disconnected.connect(_server_disconnected) # Only emitted on clients. 

#### Network callbacks from SceneTree ####

# Callback from SceneTree.
func _player_connected(_id):
	# Someone connected, start the game!
	var pong = load("res://pong.tscn").instantiate()
	# Connect deferred so we can safely erase it from the callback.
	pong.game_finished.connect(_end_game, CONNECT_DEFERRED) #Deferred connections trigger their callables on idle time (at the end of the frame), rather than instantly. 

	get_tree().get_root().add_child(pong)
	hide()


func _player_disconnected(_id):
	if multiplayer.is_server():
		_end_game("Client disconnected")
	else:
		_end_game("Server disconnected")


# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	pass # This function is not needed for this project.


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	_set_status("Couldn't connect.", false)

	multiplayer.set_multiplayer_peer(null) # Remove peer.
	host_button.set_disabled(false)
	join_button.set_disabled(false)


func _server_disconnected():
	_end_game("Server disconnected.")

##### Game creation functions ######

func _end_game(with_error = ""):
	if has_node("/root/Pong"):
		# Erase immediately, otherwise network might show
		# errors (this is why we connected deferred above).
		get_node(^"/root/Pong").free()
		show()

	multiplayer.set_multiplayer_peer(null) # Remove peer.
	host_button.set_disabled(false)
	join_button.set_disabled(false)

	_set_status(with_error, false)


func _set_status(text, isok):
	# Simple way to show status.
	if isok:
		status_ok.set_text(text)
		status_fail.set_text("")
	else:
		status_ok.set_text("")
		status_fail.set_text(text)


func _on_host_pressed():
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(DEFAULT_PORT, 1) # Maximum of 1 peer, since it's a 2-player game. Creates a server that listens to connections via port. 
	if err != OK:
		# Is another server running?
		_set_status("Can't host, address in use.",false)
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)# Compress Range Coder is good for small packets, but not things above 4 kb. 

	multiplayer.set_multiplayer_peer(peer)
	host_button.set_disabled(true)
	join_button.set_disabled(true)
	_set_status("Waiting for opponent...", true)

	## Only show hosting instructions when relevant.# Note to self: YOU MAY WANT TO UNTOGGLE THESE COMMENTS
	#port_forward_label.visible = true
	#find_public_ip_button.visible = true


func _on_join_pressed():
	Globals.pin = pin.get_text()
	var ip = address.get_text()
	if not ip.is_valid_ip_address():
		_set_status("IP address is invalid.", false)
		return

	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, DEFAULT_PORT)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

	_set_status("Connecting...", true)


func _on_find_public_ip_pressed():
	OS.shell_open("https://icanhazip.com/")
