extends Control

var websocket_url = "wss://w7gitit5fh.execute-api.us-east-2.amazonaws.com/production/"

@onready var _client : WebSocketClient = $WebSocketClient
@onready var matches_container: Panel = $MatchesContainer
@onready var matchmaking_status: RichTextLabel = $MatchmakingStatus
@onready var available_matches: VBoxContainer = $MatchesContainer/AvailableMatches
@onready var match_status: RichTextLabel = $MatchesContainer/MatchStatus

## preload button textures
#var match_button_texture = preload("res://assets/ui/match-button.png")
#var match_button_texture_hover = preload("res://assets/ui/match-button-hov.png")
#var match_button_texture_pressed = preload("res://assets/ui/match-button-pressed.png")
#var match_button_texture_blue = preload("res://assets/ui/match-button-blue.png")
#var match_button_texture_blue_hover = preload("res://assets/ui/match-button-blue-hov.png")
#var match_button_texture_red_hover = preload("res://assets/ui/match-button-red-hov.png")

var mock_user = {}

#OP CODES
const REQUEST_MATCHES = "REQUEST_MATCHES" #SERVER(LAMBDA): Retreives matches from DB, returns matches
const JOIN_MATCH = "JOIN_MATCH" #SERVER(LAMBDA): Adds users to match using DB
const MATCH_PLAYERS = "MATCH_PLAYERS" #This message is sent from the server, returns all players in match, triggers "load lobby with other players in match"
const PLAYER_JOINED = "PLAYER_JOINED" #When the server sends "Match Players" to the client, "PLAYER_JOINED" gets sent to all the other clients. 
const PLAYER_DROPPED = "PLAYER_DROPPED"
const CHECK_MATCH_READY = "CHECK_MATCH_READY" #SERVER(LAMBDA): Checks if match is full
const MATCH_READY = "MATCH_READY" #SERVER(LAMBDA): Once the match is ready, it will send this back along with the IP address and Port # of the actual Godot server that's hosting the game. 
const CREATE_MATCHES = "CREATE_MATCHES"

signal start_client(ip, port)

func _ready():
	print("Attempting to connect to server...")

	#$LobbyContainer.hide()
	#$MatchesContainer/UserInfo/Username.text = "[center]" + mock_user.username + "[center]"
	
	_connect_to_matchmaking_server()

func _connect_to_matchmaking_server():
	var error = _client.connect_to_url(websocket_url)
	
	if error != OK:
		print("Error connecting to websocket: %s" % [websocket_url])

func _process_received_message(message):
	if typeof(message) == TYPE_STRING:
		var response_msg = str_to_var(message)
		
		if response_msg.op:
			print("Process message op: %s" % response_msg.op)
			
			if response_msg.op == REQUEST_MATCHES:
				print("REQUEST_MATCHES")
				# populate the list of matches buttons
				var matches = response_msg.response
				if matches && matches.size() > 0:
					_add_matches_to_ui(matches)
					matchmaking_status.text = "[center]Choose a match to enter game![center]"
					
			elif response_msg.op == MATCH_PLAYERS:
				print("MATCH_PLAYERS")
				_enter_match_lobby(response_msg.response)
			
			elif response_msg.op == MATCH_READY:
				print("MATCH_READY")
				print("Connection info: %s, %s" % [response_msg.response.ip, response_msg.response.port])
				
				matchmaking_status.text = "[center]Game Full, Entering Match![center]"
				
				start_client.emit(response_msg.response.ip, response_msg.response.port) #IP and Port of the Godot Server with the actual game. 
				
				_client.close(1000, "Game started, lobby session ended normally.")
			
			elif response_msg.op == PLAYER_JOINED:
				print("PLAYER_JOINED")
				var match_with_players = response_msg.response
				_build_player_lobby_lists(match_with_players.users)
				
			elif response_msg.op == PLAYER_DROPPED:
				print("PLAYER_DROPPED")
				var match_with_players = response_msg.response
				print("Dropped player: %s " % match_with_players.userId)
				_build_player_lobby_lists(match_with_players.users)
				

func _add_matches_to_ui(matches):
	for match_index in range(matches.size()):
		print(matches[match_index])
		
		var button_text = "# %s | %s | %s " % [str(match_index), matches[match_index].teamMakeup, matches[match_index].map]
		
		#button label
		var button_label := RichTextLabel.new()
		button_label.set_text(button_text)
		button_label.set_size(Vector2(800.0, 100.0))
		button_label.set_position(Vector2(45.0, 30.0))
		button_label.add_theme_font_size_override("normal_font_size", 50)
		button_label.fit_content = true
		button_label.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
		
		# button
		var button := TextureButton.new()
		#button.texture_normal = match_button_texture
		#button.texture_hover = match_button_texture_hover
		#button.texture_pressed = match_button_texture_pressed
		button.add_child(button_label)
		button.set_stretch_mode(TextureButton.STRETCH_SCALE)
		
		button.pressed.connect(self._join_match.bind(matches[match_index]))
		available_matches.add_child(button)
		
func _join_match(match: Dictionary):
	available_matches.hide()
	match_status.text = "Entering match lobby: \n " + match.teamMakeup + " | " + match.map
	
	var join_match_message = {
		"op": JOIN_MATCH,
		"matchId": match.matchId,
		"playerId": mock_user.playerId,
		"rank": mock_user.rank,
		"username": mock_user.username
	}
	
	_send_message(join_match_message)

func _enter_match_lobby(match_with_players):
	print("Enter match lobby")
	print(match_with_players)
	
	$MatchesContainer.hide()
	$LobbyContainer.show()
	$MatchmakingStatus.text = "[center]Waiting for players...[center]"
	$LobbyContainer/MapInfo.text = "[center]" + match_with_players.matchInfo.map + " | " + match_with_players.matchInfo.teamMakeup + "[center]"
	
	_build_player_lobby_lists(match_with_players.users)
	
	# this part is bad practice!! (I think he said "Server side should be doing this for you")
	var match_id = match_with_players.matchInfo.matchId
	var check_match_ready = {
		"op": CHECK_MATCH_READY,
		"matchId": match_id
	}
	_send_message(check_match_ready)
	
func _build_player_lobby_lists(match_players):
	
	for team_child in $LobbyContainer/Teams/Team1.get_children():
		team_child.queue_free()
	for team_child in $LobbyContainer/Teams/Team2.get_children():
		team_child.queue_free()
		
	for player in match_players:
		print(player)
		
		var button_text = " %s | %s " % [player.username, player.rank]
		
		# button label
		var button_label := RichTextLabel.new()
		button_label.set_text(button_text)
		button_label.set_size(Vector2(800.0, 100.0))
		button_label.set_position(Vector2(45.0, 30.0))
		button_label.add_theme_font_size_override("normal_font_size", 50)
		button_label.fit_content = true
		button_label.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
		
		# button
		var button := TextureButton.new()
		button.add_child(button_label)
		button.set_stretch_mode(TextureButton.STRETCH_SCALE)
		
		if player.team == "1":
			#button.texture_normal = match_button_texture_blue
			#button.texture_hover = match_button_texture_blue_hover
			$LobbyContainer/Teams/Team1.add_child(button)
			
		elif player.team == "2":
			#button.texture_normal = match_button_texture_pressed
			#button.texture_hover = match_button_texture_red_hover
			$LobbyContainer/Teams/Team2.add_child(button)
		else:
			print("Player not assigned a team!!")
		

# lifecycle
func _send_message(message_to_send):
	var json_message = JSON.stringify(message_to_send)
	_client.send(json_message)
	
func _on_websocket_message_received(message):
	print("Message received: %s" % message)
	_process_received_message(message)

func _on_websocket_client_connection_close():
	var ws = _client.get_socket()
	print("Client disconnected with code: %s, reason: %s" % [ws.get_close_code(), ws.get_close_reason()])
	
func _on_websocket_client_connected_to_server():
	print("Client connected to server...")
	$MatchmakingStatus.text = "[center]Looking for matches...[center]"
	
	var request_matches = {
		"op": REQUEST_MATCHES
	}
	
	_send_message(request_matches)

func _on_send_test_message_pressed():
	print("Sending test message...")
#	var dict = {
#		"id": "1234",
#		"op": "card_played_123"
#	}
	var dict = {
		"id": "1234",
		"op": "my_cool_op"
	}
	var jsonMessage = JSON.stringify(dict)
	_client.send(jsonMessage)

# Create mock matches
func _create_mock_matches():
	var messageToSend = {
		"op": CREATE_MATCHES
	}
	_send_message(messageToSend)


func _on_websocket_client_connection_closed() -> void:
	pass # Replace with function body.


func _on_websocket_client_message_received(message: Variant) -> void:
	pass # Replace with function body.
