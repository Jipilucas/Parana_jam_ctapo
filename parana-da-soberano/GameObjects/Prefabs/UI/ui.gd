extends Control


func _on_comun_pressed() -> void:
	Signals.create_npc_1.emit()
	pass # Replace with function body.

func _on_fire_pressed() -> void:
	Signals.create_npc_2.emit()
	pass # Replace with function body.

func _on_cold_pressed() -> void:
	Signals.create_npc_3.emit()
	pass # Replace with function body.

func _on_lighting_pressed() -> void:
	Signals.create_npc_4.emit()
	pass # Replace with function body.

func _on_clean_pressed() -> void:
	Signals.clean.emit()
	pass # Replace with function body.
