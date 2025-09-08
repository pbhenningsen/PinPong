extends Node2D

signal game_finished()

const SCORE_TO_WIN = 4

var score_left = 0
var score_right = 0

var players_in_match = 0

var left_pin
var right_pin

@onready var winner_left = $WinnerLeft
@onready var winner_right = $WinnerRight

func _ready():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.connect(_on_player_connected) ##This represents clients connecting to the server. 
	multiplayer.peer_disconnected.connect(del_player)
	$LeftGoal.area_entered.connect(_on_left_goal_area_entered)
	$RightGoal.area_entered.connect(_on_right_goal_area_entered)
	
func _on_player_connected(id: int):
	if multiplayer.is_server():
		add_player(id)

func _on_connected_ok():
	if multiplayer.is_server():
		var player_id = multiplayer.get_unique_id()
	

func add_player(id):
	players_in_match += 1
	
	var paddle = preload("res://paddle.tscn").instantiate()
	
	paddle.set_name_and_pin.connect(_fill_name_and_pin.rpc)
	
	var player_id = multiplayer.get_unique_id()
	paddle.player = id
	paddle.name = str(id)
	
	if players_in_match == 1:
		paddle.position = Vector2(32, 180)
		paddle.left = true
	elif players_in_match == 2:
		paddle.position = Vector2(600, 180)
		_ball_start()

	$Players.add_child(paddle, true)
	
func _ball_start():
	print("_ball_start_running")
	await get_tree().create_timer(1.0).timeout
	$Ball2.stopped = false

	
@rpc()
func _fill_name_and_pin(player_side, player_name, player_pin):
	if player_side == 2:
		right_pin = str(player_pin)
		$Pin2.set_text("XXXX")
		$Name2.set_text(player_name)
	else:
		left_pin = str(player_pin)
		$Pin1.set_text("XXXX")
		$Name1.set_text(player_name)
	
	
func _reveal_pin(player_side, score):
	if player_side == "right":
		match score:
			1:
				$Pin1.text = left_pin[0] + "XXX"
			2:
				$Pin1.text = left_pin[0] + left_pin[1] + "XX"
			3:
				$Pin1.text = left_pin[0] + left_pin[1] + left_pin[2] + "X"
			4: 
				$Pin1.text= left_pin
	else:
		match score:
			1:
				$Pin2.text = right_pin[0] + "XXX"
			2:
				$Pin2.text = right_pin[0] + right_pin[1] + "XX"
			3:
				$Pin2.text = right_pin[0] + right_pin[1] + right_pin[2] + "X"
			4: 
				$Pin2.text= right_pin
	

func del_player():
	pass

#Remember, the client is PART of the game. It may be easier, in your case, to usee a synchronizer of some kind. Or, you might have to adjust this RPC call. You should be using "call_remote"
@rpc()
func update_score(add_to_left):
	if add_to_left:
		score_left+=1
		_reveal_pin("left", score_left)
	else:
		score_right += 1
		_reveal_pin("right", score_right)

	var game_ended = false
	if score_left == SCORE_TO_WIN:
		winner_left.show()
		game_ended = true
	elif score_right == SCORE_TO_WIN:
		winner_right.show()
		game_ended = true

	if game_ended:
		$ExitGame.show()
		$Ball2.visible = false
		
func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)

func _on_exit_game_pressed():
	game_finished.emit()
	



func _on_left_goal_area_entered(area: Area2D) -> void:
	update_score.rpc(false)


func _on_right_goal_area_entered(area: Area2D) -> void:
	update_score.rpc(true)
