class_name OpcionEvento
extends Resource

@export var texto_boton: String = "Aceptar"
@export var descripcion_efecto: String = ""

@export_group("Modificadores Globales")
@export var delta_dinero: int = 0
@export var delta_soberania: float = 0.0
@export var delta_tier_ciencia: int = 0
@export var delta_astilleros: int = 0
@export var avanzar_tramo_magdalena: bool = false

@export_group("Efectos sobre el Tablero")
## Si es true, activa el primer Slot vacío de Industria disponible sin costo adicional
@export var activar_slot_industria_vacio: bool = false
## Modifica la cantidad de producción de todos los Productores propios/neutrales
@export var delta_produccion_productores: int = 0
## Modifica la capacidad de todos los Fletes activos
@export var delta_capacidad_fletes: int = 0
## Modifica el costo por viaje de todos los Fletes
@export var delta_costo_viaje_fletes: int = 0
