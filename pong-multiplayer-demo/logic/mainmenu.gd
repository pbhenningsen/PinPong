extends Control

signal host_options_submitted
signal host_options_cancelled

signal join_options_submitted
signal join_options_cancelled

@export_category("Buttons")
@export var host_options_button: Button
@export var join_options_button: Button

@export_category("Options Panels")
@export var main_options_panel: Panel
@export var host_options_panel_scene: PackedScene
@export var join_options_panel_scene: PackedScene

func _ready():
	# Connect all the callbacks related to networking.
	
	BADMP.add_scene(BADSceneManager.MAIN, "res://MainMenu.tscn")
	BADMP.add_scene(BADSceneManager.GAME, "res://Game.tscn")
	BADMP.add_scene(BADSceneManager.LOADING, "res://Loading.tscn")

	
