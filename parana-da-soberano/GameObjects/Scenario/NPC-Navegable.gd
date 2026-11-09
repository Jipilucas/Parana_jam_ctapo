extends CharacterBody3D
class_name NpcNavegable

@onready var nav_agent = $NavigationAgent3D
@export var velocidad = 3.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Buscamos la meta
	var metas = get_tree().get_nodes_in_group("Meta")
	Signals.clean.connect(eliminar)
	
	if metas.size() > 0:
		nav_agent.target_position = metas[0].global_position
		print("¡Meta encontrada en: ", nav_agent.target_position, "!")
	else:
		print("ERROR: No encontré ningún nodo con el grupo 'Meta'")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if nav_agent.is_navigation_finished():
		queue_free() # Destruye y borra al enemigo del mapa
		return # Corta la ejecución para que no haya errores
	else:
		var siguiente_posicion = nav_agent.get_next_path_position()
		
		# Calculamos la dirección y forzamos a que mire solo al frente (sin contar altura)
		var direccion = global_position.direction_to(siguiente_posicion)
		direccion.y = 0 
		direccion = direccion.normalized()
		
		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad
	move_and_slide()
	
func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.is_in_group("Meta"):
		eliminar()
	pass # Replace with function body.
func eliminar():
	queue_free()
