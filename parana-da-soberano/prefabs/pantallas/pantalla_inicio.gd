extends Node


func _ready() -> void:
	if get_tree() != null:
		get_tree().paused = false


func _on_comenzar_pressed() -> void:
	Partida.reiniciar_partida(false)
	get_tree().change_scene_to_file("res://Gestores/TestScene2.tscn")


func _on_sandbox_pressed() -> void:
	Partida.reiniciar_partida(true)
	get_tree().change_scene_to_file("res://Gestores/TestScene2.tscn")


func _on_jam_link_pressed() -> void:
	OS.shell_open("https://itch.io/jam/liberen-el-parana-gamejam")
