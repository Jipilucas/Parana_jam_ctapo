extends Productor
class_name ProductorMateriaPrima

func _init() -> void:
	pass

func _ready() -> void:
	self.necesario = RecursoStock.new()
	self.resultante = MateriaPrima.new()
