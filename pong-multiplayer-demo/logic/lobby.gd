extends Control

const DEFAULT_PORT = 8910
@onready var address = $Address  # Address input field where players enter the server IP.
@onready var join_button = $JoinButton
@onready var status_ok = $StatusOk
@onready var status_fail = $StatusFail
@onready var pin: LineEdit = $Pin

var peer = null

func _ready():
	# Connect the "Join" button
	#join_button.pressed.connect(_on_join_pressed)
	_set_status("Click 'Join' to start!", true)

# Function to handle player joining and matchmaking
func _on_join_pressed():
	Globals.pin = pin.get_text()  # Use the pin entered by the player
	var ip = address.get_text()  # Get the IP address entered by the player.

	# Validate the IP address
	if not ip.is_valid_ip_address():
		_set_status("IP address is invalid.", false)
		return

	# Create the ENet multiplayer peer and connect as a client
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, DEFAULT_PORT)  # Try to connect as a client to the server.

	# Use compression for smaller packet sizes
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)

	# Set the multiplayer peer
	multiplayer.set_multiplayer_peer(peer)
	_set_status("Connecting...", true)

# Status updating helper function
func _set_status(text, isok):
	if isok:
		status_ok.set_text(text)
		status_fail.set_text("")
	else:
		status_ok.set_text("")
		status_fail.set_text(text)
