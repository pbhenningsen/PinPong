extends Control

var websocket_url = "wss://w0jm78oqx6.execute-api.us-east-2.amazonaws.com/production/"

@onready var _client : WebSocketClient = $WebSocketClient
@onready var matches_container: Panel = $MatchesContainer
@onready var matchmaking_status: RichTextLabel = $MatchmakingStatus
@onready var available_matches: VBoxContainer = $MatchesContainer/AvailableMatches
@onready var match_status: RichTextLabel = $MatchesContainer/MatchStatus
@onready var waiting_label: Label = $WaitingLabel

var player_entry = {}#THIS IS THE PLAYER ENTRY THAT I'M TRYING TO ADJUST
var matches_remaining

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
signal create_new_matches


func _ready():
	print("We have now entered the lobby")
	print("Player name: " + player_entry["username"] + " Player pin: " + player_entry["pin"])
	$WaitingLabel.visible = true
	print("Attempting to connect to Lambda server...")
	
	_connect_to_matchmaking_server()

func _connect_to_matchmaking_server():
	var error = _client.connect_to_url(websocket_url)
	
	if error != OK:
		print("Error connecting to websocket: %s" % [websocket_url])
	else:
		print("websocket connected")

func _process_received_message(message):
	if typeof(message) == TYPE_STRING:
		var response_msg = str_to_var(message)
		
		if response_msg.op:
			print("Process message op: %s" % response_msg.op)
			
			if response_msg.op == REQUEST_MATCHES:
				print("REQUEST_MATCHES")
				# populate the list of matches buttons
				var matches = response_msg.response #THIS IS WHERE WE ESTABLISH THE MATCHES VARIABLE
				matches_remaining = matches
				#if matches.size() < 5:
					#create_new_matches.emit()
				if matches && matches.size() > 0:
					#I Could have everyone create a single match just so they replenish what was lost. 
					_join_match(matches[0])
					#_add_matches_to_ui(matches)
					#matchmaking_status.text = "[center]Choose a match to enter game![center]" # I SHOULD ADD SOMETHING HERE ABOUT STARTING A MATCH
					
			elif response_msg.op == MATCH_PLAYERS:
				print("MATCH_PLAYERS")
				#print("MESSAGE AFTER MATCH PLAYERS" + message)
				
				_enter_match_lobby(response_msg.response)
		
			
			elif response_msg.op == MATCH_READY:
				print("MATCH_READY")
				print("Connection info: %s, %s" % [response_msg.response.ip, response_msg.response.port])
				
				
				matchmaking_status.text = "[center]Game Full, Entering Match![center]"
				
				start_client.emit(response_msg.response.ip, response_msg.response.port) #IP and Port of the Godot Server with the actual game. 
				
				_client.close(1000, "Game started, lobby session ended normally.")
			
			elif response_msg.op == PLAYER_JOINED:
				print("PLAYER_JOINED")
				var match_with_players = response_msg.response # MAYBE ADD ANOTHER MATCH HERE IF IT'S EMPTY
				#_build_player_lobby_lists(match_with_players.users)
				#print("Player 1 team" + response_msg.response.users[0].team)#I'VE GOT THE TEAM NUMBERS, NOW HOW CAN I USE THEM?
				#print("Player 2 team" + response_msg.response.users[1].team)
				
			elif response_msg.op == PLAYER_DROPPED:
				print("PLAYER_DROPPED")
				var match_with_players = response_msg.response
				print("Dropped player: %s " % match_with_players.userId)
				#_build_player_lobby_lists(match_with_players.users)
				


# I Think I have to fix this...
func _add_matches_to_ui(matches):
	#for match_index in range(matches.size()):
	var next_match = matches[0]
		
		
	#var button_text = matches[0].map
		#var button_text = "Join a match!"
		
		#button
	var match_button := Button.new()
		#match_button.text = matches[match_index].map
	match_button.text = "Join the next match!"
		
	
		
	match_button.pressed.connect(self._join_match.bind(matches[0]))#If this is like the example video, clicking this is actually what triggers the game starting. 
	available_matches.add_child(match_button)

		
		
func _join_match(match: Dictionary):
	print("join_match is running")#RIGHT NOW IT IS NOT BEING CALLED!
	available_matches.hide()
	#match_status.text = "Entering match lobby: \n " + match.teamMakeup + " | " + match.map
	
	var join_match_message = {
		"op": JOIN_MATCH,
		"matchId": match.matchId, ##DOES THIS HAVE SOMETHING TO DO WITH TEAM SIZE?
		"playerId": player_entry.playerId,
		"rank": player_entry.rank,
		"username": player_entry.username,
		"team": player_entry.team,#ADDED THIS JUST NOW
		"pin": player_entry.pin,
	}
	
	_send_message(join_match_message)

func _enter_match_lobby(match_with_players):
	print("enter_match_lobby is running")	
	
	$MatchesContainer.hide()
	#LobbyContainer.show()
	matchmaking_status.hide()
	#waiting_label.visible = true
	
	# this part is bad practice!! (I think he said "Server side should be doing this for you")
	var match_id = match_with_players.matchInfo.matchId
	var check_match_ready = {
		"op": CHECK_MATCH_READY,
		"matchId": match_id
	}
	_send_message(check_match_ready)
	
func _build_player_lobby_lists(match_players):
	pass #This function is named the same as in the other game, but that's not what I'm actually going to do with it. 

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
	#$MatchmakingStatus.text = "[center]Looking for matches...[center]"
	
	var request_matches = {
		"op": REQUEST_MATCHES
	}
	
	_send_message(request_matches)

# Create mock matches
func _create_mock_matches():
	var messageToSend = {
		"op": CREATE_MATCHES
	}
	print("create mock matches just ran")
	_send_message(messageToSend)
