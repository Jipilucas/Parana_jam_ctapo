extends Node

@export_category("Entidades")
@export var poblacion:int
@export var industrias:int
@export var extranjeros:int
@export var puertos_propios:int
@export var puertos_extranjeros:int

func actualizar_entidad(entidad:String, cantidad:int):
	var valor_actual = get(entidad)
	set(entidad, valor_actual + cantidad)
