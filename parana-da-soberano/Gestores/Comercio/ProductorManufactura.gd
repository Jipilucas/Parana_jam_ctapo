extends Productor
class_name ProductorManufactura


func _init() -> void:
	pass

func _ready() -> void:
	self.necesario = MateriaPrima.new()
	self.resultante = Manufactura.new()
