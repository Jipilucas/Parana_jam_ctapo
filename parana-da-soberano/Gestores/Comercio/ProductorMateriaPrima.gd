extends Node
class_name ProductorMateriaPrima

var necesario = MateriaPrima.new()
var resultante = MateriaPrima.new()

func _init() -> void:
	pass

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	pass
	
func Consumir():
	print('consume')
	
func Producir():
	resultante.Cantidad =+ 10
	print(self.name,' produce ',resultante.Nombre,'=',resultante.Cantidad)
