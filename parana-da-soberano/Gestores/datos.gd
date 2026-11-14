extends Control
class_name UIProductor
@export var entidad : Productor
@export var comandos : ControladorComandos

#Seniales del Comandos
#signal rutina_iniciada
#signal rutina_finalizada
#signal comando_iniciado(comando: Command)
#signal comando_completado(comando: Command)

func _init() -> void:
	pass

func _process(delta: float) -> void:
	$VBoxContainer/Nombre.text = entidad.name
	$VBoxContainer/Estado.text = comandos.comando_actual
	$VBoxContainer/Stock_input.text = 'necesario: ' + str(entidad.necesario.Cantidad)
	$VBoxContainer/Stock_output.text = 'producido: ' + str(entidad.resultante.Cantidad)
	
