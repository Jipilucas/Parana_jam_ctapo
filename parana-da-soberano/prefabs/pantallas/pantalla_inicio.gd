extends Node


func _on_comenzar_pressed() -> void:
	get_tree().change_scene_to_file("res://Gestores/TestScene2.tscn")


func _on_jam_link_pressed() -> void:
	OS.shell_open("https://itch.io/jam/liberen-el-parana-gamejam")
