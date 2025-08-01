extends Node

var ws_client : WebSocketPeer
var is_connected = false

# Called when the node enters the scene tree for the first time.
func _ready():
	ws_client = WebSocketPeer.new()
	#ws_client.connect("data_received", self, "_on_data_received")
	#ws_client.connect("connection_error", self, "_on_connection_error")
	#ws_client.connect("connection_closed", self, "_on_connection_closed")
	ws_client.data_received.connect(_on_data_received)
	ws_client.connection_error.connect(_on_connection_error)
	ws_client.connection_closed.connect(_on_connection_closed)
	
	# Connect to the matchmaking server
	ws_client.connect_to_url("ws://localhost:8080")
	print("Attempting to connect to matchmaking server...")
	
	# Wait for the connection to be established
	#yield(ws_client, "connection_established")
	await ws_client.connection_established
	print("Connected to matchmaking server")
	
	# Send "JOIN" message to start the matchmaking process
	ws_client.send_text_message("JOIN")

# Handle messages received from the server
func _on_data_received():
	var message = ws_client.get_peer(1).get_data().get_string_from_utf8()
	#var data = parse_json(message)
	var data = JSON.parse_string(message)
	if data.has("action"):
		var action = data["action"]
		
		if action == "MATCHED":
			print("Matched with: " + data["opponent"])
			# Proceed with the game logic, e.g., change scene to the game scene
			
		elif action == "START_GAME":
			print("The game is starting!")
			# Start the actual game here (you could change the scene to your Pong game)

# Handle connection error
func _on_connection_error():
	print("Failed to connect to the server")

# Handle server disconnection
func _on_connection_closed():
	print("Connection to the server was closed")
