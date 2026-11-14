extends Node
class_name Flete

@export var Remitente : Productor
@export var Destinatario : Productor
@export var Capacidad : int

var Carga_Actual : int = 0


func Recibir(cant:int = Capacidad):
	print(self.name, ' recibe ', cant, ' de ', Remitente)
	Carga_Actual += cant
	Remitente.Despachar(cant)

func Despachar(cant:int = Capacidad):
	print(self.name, ' despacha ', cant, ' a ', Destinatario)
	Carga_Actual -= cant
	Destinatario.Recibir(cant)
