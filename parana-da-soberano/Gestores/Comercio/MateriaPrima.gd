extends RecursoStock
class_name MateriaPrima

func _init() -> void:
	self.Nombre = "Materia Prima"
	self.Cantidad = 100
	pass
	

func _ready() -> void:
	print(self.Nombre, ' ready.', ' cant=',self.Cantidad)
