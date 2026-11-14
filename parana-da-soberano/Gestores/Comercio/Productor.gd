extends Node
class_name Productor

var necesario = RecursoStock
@export var necesario_cantidad : int
var resultante = RecursoStock
@export var resultante_cantidad : int

	
func Consumir():
	necesario.Cantidad -= necesario_cantidad
	print(self.name,' consume ',necesario.Nombre,' (-', necesario_cantidad ,') stock=',necesario.Cantidad)
	
func Producir():
	resultante.Cantidad += resultante_cantidad
	print(self.name,' produce ',resultante.Nombre,' (+', resultante_cantidad ,') stock=',resultante.Cantidad)
	
func Recibir(cant:int):
	necesario.Cantidad += cant
	print(self.name, ' recibe (+', cant, ') de', necesario.Nombre, ' stock=', necesario.Cantidad)
	pass
	
func Despachar(cant:int):
	resultante.Cantidad -= cant
	print(self.name, ' despacha (+', cant, ') de', resultante.Nombre, ' stock=', resultante.Cantidad)
	pass
