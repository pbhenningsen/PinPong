extends Control

signal hide_title

func _on_button_pressed() -> void:
	hide_title.emit()
