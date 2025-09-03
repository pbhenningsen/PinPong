extends Node2D

signal game_finished()

const SCORE_TO_WIN = 10

var score_left = 0
var score_right = 0

@onready var player2 = $Player2
@onready var score_left_node = $ScoreLeft
@onready var score_right_node = $ScoreRight
@onready var winner_left = $WinnerLeft
@onready var winner_right = $WinnerRight

func _ready():
	# By default, all nodes in server inherit from master,
	# while all nodes in clients inherit from puppet.
	# set_multiplayer_authority is tree-recursive by default.
	if multiplayer.is_server():
		# For the server, give control of player 2 to the other peer.
		player2.set_multiplayer_authority(multiplayer.get_peers()[0]) #YOU COULD HAVE THE SERVER TRY AND DO THIS SHIT. SAY "IF SERVER, TELL ME MULTIPLAYER PEERS AND THEN...." because get_peers won't include itself. 
		print(multiplayer.get_peers()[0])
		print(multiplayer.get_unique_id())
	else:
		# For the client, give control of player 2 to itself.
		player2.set_multiplayer_authority(multiplayer.get_unique_id()) #get_unique_id gives you YOUR id. 

	print("Unique id: ", multiplayer.get_unique_id())


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


func _on_exit_game_pressed():
	game_finished.emit()
