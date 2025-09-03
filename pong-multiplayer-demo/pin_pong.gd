extends Node2D

signal game_finished()

const SCORE_TO_WIN = 4

var score_left = 0
var score_right = 0

var players_in_match = 0


@onready var score_left_node: Label = $Score/Control/ScoreLeft
@onready var score_right_node: Label = $Score/Control/ScoreRight
@onready var winner_left = $WinnerLeft
@onready var winner_right = $WinnerRight


func _ready():
	print("level ready")
	
	if not multiplayer.is_server():
		return 
	#print out multiplayer peers. 
	multiplayer.peer_connected.connect(add_player) ##This represents clients connecting to the server. 
	multiplayer.peer_disconnected.connect(del_player)
	
	for id in multiplayer.get_peers():
		add_player(id)

	if not OS.has_feature("dedicated_server"):
		add_player(1)
	

func add_player(id: int):
	players_in_match += 1
	var character = preload("res://multiplayer_player.tscn").instantiate()
	character.player = id
	
	
	#MAYBE CONTROL WHICH IS LEFT AND WHICH IS RIGHT HERE?
	if players_in_match == 1:
		character.position = Vector2(32.49, 188.622)
	elif players_in_match == 2:
		character.position = Vector2(608.88, 188.622)
		character.left = true
	$Players.add_child(character, true)
	
	


func del_player(id: int):
	if not $Players.has_node(str(id)):
		return
	$Players.get_node(str(id)).queue_free()
	
func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)

@rpc("any_peer", "call_local")
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
