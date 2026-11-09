extends Node3D

# Al usar @export, nos aparecerán casilleros en el Inspector para arrastrar las escenas
@export var common_scene: PackedScene
@export var fire_scene: PackedScene
@export var cold_scene: PackedScene
@export var lightning_scene: PackedScene
@export var poison_scene: PackedScene

# Variable para controlar qué escupir (cumple la consigna de controles)
# Opciones válidas: "random", "common", "fire", "cold", "lightning", "poison"
var modo_generacion: String = "random" 

func _ready():
	$Timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	var escena_a_crear: PackedScene
	
	# Decidimos qué enemigo crear según el modo actual
	match modo_generacion:
		"common": escena_a_crear = common_scene
		"fire": escena_a_crear = fire_scene
		"cold": escena_a_crear = cold_scene
		"lightning": escena_a_crear = lightning_scene
		"poison": escena_a_crear = poison_scene
		"random", _:
			var opciones = [common_scene, fire_scene, cold_scene, lightning_scene, poison_scene]
			escena_a_crear = opciones.pick_random()
			
	# Si por algún motivo falta asignar una escena, cancelamos para que no tire error
	if not escena_a_crear: return 
	
	# Instanciamos y agregamos al mapa
	var nuevo_enemigo = escena_a_crear.instantiate()
	add_child(nuevo_enemigo)
	nuevo_enemigo.global_position = self.global_position
	
	# Le forzamos la orden de buscar la meta apenas nace
	var nodo_meta = get_tree().get_first_node_in_group("Meta")
	
