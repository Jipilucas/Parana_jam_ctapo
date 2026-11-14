extends RecursoStock
class_name Manufactura

func _init() -> void:
	self.Nombre = "Manufactura"
	self.Cantidad = 100
	pass
	

func _ready() -> void:
	print(self.Nombre, ' ready.', ' cant=',self.Cantidad)
