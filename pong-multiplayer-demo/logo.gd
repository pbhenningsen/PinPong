extends Control


func _ready() -> void:
	get_tree().create_timer(2.0)
	get_tree().change_scene_to_file("res://startup.tscn")
