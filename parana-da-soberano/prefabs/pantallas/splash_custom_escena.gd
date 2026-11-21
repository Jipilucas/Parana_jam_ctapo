extends Node2D


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
### Cambiar la ruta por la pantalla de inicio
	#SignalBus.BGM_Song_3.emit(true)
	get_tree().change_scene_to_file("res://prefabs/Pantalla_inicio.tscn")
