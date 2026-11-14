extends Control
class_name UIFlete
@export var entidad : Flete
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
	$"VBoxContainer/Carga actual".text = 'carga Actual: ' + str(entidad.Carga_Actual)
	
