extends Tile

class_name EndTile


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("NPC"):
		body.queue_free()
	pass # Replace with function body.
