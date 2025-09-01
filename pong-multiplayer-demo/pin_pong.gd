extends Node2D

signal game_finished()

const SCORE_TO_WIN = 4
const LOCAL_HOST_MODE = true

var score_left = 0
var score_right = 0

var pin_left = "1234"#PLACEHOLDER
var pin_right = "5678"#PLACEHOLDER


@onready var score_left_label: Label = $Score/Control/ScoreLeft
@onready var score_right_label: Label = $Score/Control/ScoreRight

@onready var winner_left = $WinnerLeft
@onready var winner_right = $WinnerRight

func _ready():
	print("level ready")
	
	if not multiplayer.is_server():
		return 
	
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)
	
	for id in multiplayer.get_peers():
		add_player(id)#I THINK THIS MIGHT BE WHERE WE'RE RUNNING INTO PROBLEMS

	if LOCAL_HOST_MODE && not OS.has_feature("dedicated_server"):
		add_player(1)
	score_left_label.text = "XXXX"
	score_right_label.text = "XXXX"
	
func add_player(id: int):
	print("add player: " + str(id))
	var character = preload("res://multiplayer_player.tscn").instantiate()
	character.player = id
	
	#MAYBE CONTROL WHICH IS LEFT AND WHICH IS RIGHT HERE?
	character.position = Vector2(32.49, 188.622)
	#var rng = RandomNumberGenerator.new()
	#var random_x = rng.randf_range(100.0, 150.0)
	#var random_z = rng.randf_range(100.0, 200.0)
	#character.position = Vector3(random_x, 10, random_z)

	character.name = str(id)
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
		#score_left_label.set_text(str(score_left))

	else:
		score_right += 1
		#score_right_label.set_text(str(score_right))
		
	match score_right:
		0:
			score_left_label.text = "XXXX"
		1:
			score_left_label.text = pin_left[0] + "XXX"
		2: 
			score_left_label.text = pin_left[0] + pin_left[1] + "XX"
		3: 
			score_left_label.text = pin_left[0] + pin_left[1] + pin_left[2] + "X"
		4:
			score_left_label.text = pin_left
			
	match score_left:
		0:
			score_right_label.text = "XXXX"
		1:
			score_right_label.text = pin_right[0] + "XXX"
		2: 
			score_right_label.text = pin_right[0] + pin_right[1] + "XX"
		3: 
			score_right_label.text = pin_right[0] + pin_right[1] + pin_right[2] + "X"
		4:
			score_right_label.text = pin_right
		
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
