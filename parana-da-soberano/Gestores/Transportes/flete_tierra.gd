class_name Flete
extends Node2D

signal flete_actualizado

enum TipoFlete {
	TIERRA,
	MAR
}

@export_group("Ruta y Conexión")
@export var nombre_ruta: String = "Ruta Flete"
@export var tipo_flete: TipoFlete = TipoFlete.TIERRA
@export var activa_al_inicio: bool = true
@export var Remitente: Productor
@export var Destinatario: Productor

@export_group("Capacidad y Costos de Ruta")
@export var Capacidad: int = 10
## Costo único para habilitar/abrir esta ruta (según distancia imaginaria o criterio de diseño)
@export var costo_habilitar: int = 40
## Costo operativo cobrado por cada viaje con carga
@export var costo_por_viaje: int = 3

@export_group("Referencias Opcionales")
@export var controlador: ControladorComandos

var Carga_Actual: int = 0
var ruta_habilitada: bool = false
var _registrado_en_astillero: bool = false


func _ready() -> void:
	add_to_group("fletes")
	if controlador == null and has_node("ControladorComandos"):
		controlador = $ControladorComandos as ControladorComandos

	if activa_al_inicio:
		if tipo_flete == TipoFlete.MAR:
			if Partida.puede_activar_flete_mar():
				Partida.registrar_flete_mar(true)
				_registrado_en_astillero = true
				ruta_habilitada = true
			else:
				ruta_habilitada = false
		else:
			ruta_habilitada = true
	else:
		ruta_habilitada = false

	_sincronizar_controlador()
	queue_redraw()


func _exit_tree() -> void:
	if _registrado_en_astillero and is_instance_valid(Partida):
		Partida.registrar_flete_mar(false)
		_registrado_en_astillero = false


func _process(_delta: float) -> void:
	queue_redraw()


func _sincronizar_controlador() -> void:
	if controlador == null:
		return
	if ruta_habilitada:
		if not controlador._activo:
			controlador.iniciar_ciclo.call_deferred()
	else:
		controlador.detener_ciclo()


func habilitar_ruta() -> bool:
	if ruta_habilitada:
		return true

	if tipo_flete == TipoFlete.MAR and not Partida.puede_activar_flete_mar():
		Partida.mensaje_log.emit("Sin cupo en Astilleros Nacionales para ruta marítima (%s)" % obtener_nombre_ruta())
		return false

	if Partida.dinero < costo_habilitar:
		Partida.mensaje_log.emit("Fondos insuficientes para habilitar %s (Requiere $%d)" % [obtener_nombre_ruta(), costo_habilitar])
		return false

	Partida.modificar_dinero(-costo_habilitar, "Apertura de %s" % obtener_nombre_ruta())
	if tipo_flete == TipoFlete.MAR:
		Partida.registrar_flete_mar(true)
		_registrado_en_astillero = true

	ruta_habilitada = true
	_sincronizar_controlador()
	flete_actualizado.emit()
	queue_redraw()
	return true


func desactivar_ruta() -> void:
	if not ruta_habilitada:
		return
	ruta_habilitada = false
	if _registrado_en_astillero:
		Partida.registrar_flete_mar(false)
		_registrado_en_astillero = false
	_sincronizar_controlador()
	flete_actualizado.emit()
	queue_redraw()


func obtener_nombre_ruta() -> String:
	if nombre_ruta != "":
		return nombre_ruta
	return name


func Recibir(cant: int = Capacidad) -> void:
	if not ruta_habilitada or Remitente == null or not Remitente.slot_ocupado:
		return
	var espacio_libre: int = maxi(0, Capacidad - Carga_Actual)
	var a_pedir: int = mini(cant, espacio_libre)
	if a_pedir <= 0:
		return

	var extraido: int = Remitente.Despachar(a_pedir)
	if extraido > 0:
		Carga_Actual += extraido
		if costo_por_viaje > 0:
			Partida.modificar_dinero(-costo_por_viaje, "Flete %s" % obtener_nombre_ruta())
		flete_actualizado.emit()


func Despachar(cant: int = Capacidad) -> void:
	if not ruta_habilitada or Destinatario == null or not Destinatario.slot_ocupado:
		return
	if Carga_Actual <= 0:
		return

	var a_entregar: int = mini(cant, Carga_Actual)
	var entregado: int = Destinatario.Recibir(a_entregar)
	if entregado > 0:
		Carga_Actual -= entregado
		flete_actualizado.emit()


func _draw() -> void:
	if Remitente == null or Destinatario == null:
		return
	var p_origen: Vector2 = to_local(Remitente.global_position)
	var p_destino: Vector2 = to_local(Destinatario.global_position)

	var color_linea: Color
	if not ruta_habilitada:
		color_linea = Color(0.55, 0.55, 0.55, 0.45)
	elif tipo_flete == TipoFlete.MAR:
		color_linea = Color(0.2, 0.75, 1.0, 0.85)
	else:
		color_linea = Color(0.95, 0.7, 0.2, 0.85)

	draw_line(p_origen, p_destino, color_linea, 3.0 if ruta_habilitada else 2.0)

	# Dibujar flecha de dirección hacia el destinatario
	var dir: Vector2 = (p_destino - p_origen).normalized()
	var punto_flecha: Vector2 = p_origen.lerp(p_destino, 0.65)
	var ala_izq: Vector2 = punto_flecha - dir.rotated(0.45) * 12.0
	var ala_der: Vector2 = punto_flecha - dir.rotated(-0.45) * 12.0
	draw_line(punto_flecha, ala_izq, color_linea, 3.0)
	draw_line(punto_flecha, ala_der, color_linea, 3.0)
