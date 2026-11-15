extends Sprite2D

@export var padre : Node2D
var _faccion = ConfigLogistica.Faccion.NEUTRAL

func _process(delta: float) -> void:
	if padre is Productor :
		_faccion = padre.faccion_actual
	cambiar_bandera()
		

func cambiar_bandera():
	if _faccion == ConfigLogistica.Faccion.PROPIO:
		modulate = Color.GREEN
	if _faccion == ConfigLogistica.Faccion.NEUTRAL:
		modulate = Color.CADET_BLUE
	if _faccion == ConfigLogistica.Faccion.ENEMIGO:
		modulate = Color.RED
