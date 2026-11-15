class_name GestorEventos
extends Node

signal evento_disparado(evento: EventoRecurso)
signal evento_resuelto

@export var intervalo_eventos: float = 28.0
@export var auto_iniciar: bool = true
@export var catalogo_eventos: Array[EventoRecurso] = []

var evento_actual: EventoRecurso = null
var _timer: Timer


func _ready() -> void:
	if catalogo_eventos.is_empty():
		_cargar_eventos_por_defecto()

	_timer = Timer.new()
	_timer.wait_time = intervalo_eventos
	_timer.one_shot = false
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	if auto_iniciar:
		_timer.start()


func _on_timer_timeout() -> void:
	if evento_actual == null and not Partida.juego_terminado:
		disparar_evento_aleatorio()


func disparar_evento_aleatorio() -> void:
	if catalogo_eventos.is_empty() or Partida.juego_terminado:
		return
	evento_actual = catalogo_eventos.pick_random()
	evento_disparado.emit(evento_actual)


func elegir_opcion(indice: int) -> void:
	if evento_actual == null or indice < 0 or indice >= evento_actual.opciones.size():
		return
	var opcion: OpcionEvento = evento_actual.opciones[indice]
	aplicar_opcion(opcion)
	evento_actual = null
	evento_resuelto.emit()


func aplicar_opcion(opcion: OpcionEvento) -> void:
	if opcion == null:
		return

	if opcion.delta_dinero != 0:
		Partida.modificar_dinero(opcion.delta_dinero, "Evento")
	if opcion.delta_soberania != 0.0:
		Partida.modificar_soberania(opcion.delta_soberania, "Evento")
	if opcion.delta_tier_ciencia != 0:
		Partida.tier_ciencia = maxi(1, Partida.tier_ciencia + opcion.delta_tier_ciencia)
		Partida._recalcular_multiplicadores()
		Partida.estado_cambiado.emit()
	if opcion.delta_astilleros != 0:
		Partida.astilleros_nacionales = maxi(1, Partida.astilleros_nacionales + opcion.delta_astilleros)
		Partida.estado_cambiado.emit()
	if opcion.avanzar_tramo_magdalena and Partida.tramos_magdalena_completados < Partida.tramos_totales_magdalena:
		Partida.tramos_magdalena_completados += 1
		Partida.progreso_magdalena = (float(Partida.tramos_magdalena_completados) / float(Partida.tramos_totales_magdalena)) * 100.0
		Partida.modificar_soberania(Partida.soberania_total_magdalena / float(Partida.tramos_totales_magdalena), "Avance Canal Magdalena (Evento)")

	if opcion.activar_slot_industria_vacio:
		for nodo in get_tree().get_nodes_in_group("productores"):
			var prod := nodo as Productor
			if prod and not prod.slot_ocupado:
				prod.activar_slot_como_propio()
				Partida.mensaje_log.emit("Evento: Se inauguró nueva planta en %s" % prod.obtener_nombre())
				break

	if opcion.delta_produccion_productores != 0:
		for nodo in get_tree().get_nodes_in_group("productores"):
			var prod := nodo as Productor
			if prod and prod.faccion_actual != ConfigLogistica.Faccion.ENEMIGO:
				prod.bonus_produccion += opcion.delta_produccion_productores
		Partida.mensaje_log.emit("Evento: Producción modificada en %+d" % opcion.delta_produccion_productores)

	if opcion.delta_capacidad_fletes != 0 or opcion.delta_costo_viaje_fletes != 0:
		for nodo in get_tree().get_nodes_in_group("fletes"):
			var flt := nodo as Flete
			if flt:
				flt.Capacidad = maxi(2, flt.Capacidad + opcion.delta_capacidad_fletes)
				flt.costo_por_viaje = maxi(0, flt.costo_por_viaje + opcion.delta_costo_viaje_fletes)
				flt.flete_actualizado.emit()
		Partida.mensaje_log.emit("Evento: Estadísticas de Fletes actualizadas.")


func _cargar_eventos_por_defecto() -> void:
	# Evento 1: Cooperativa Industrial
	var ev1 := EventoRecurso.new()
	ev1.titulo = "Propuesta de Cooperativa Industrial"
	ev1.descripcion = "Un grupo de productores locales propone abrir una fábrica nacional en un predio vacío con apoyo estatal."
	var op1_a := OpcionEvento.new()
	op1_a.texto_boton = "Financiar Planta (-$60, Abre Slot Vacío, +4% Soberanía)"
	op1_a.delta_dinero = -60
	op1_a.delta_soberania = 4.0
	op1_a.activar_slot_industria_vacio = true
	var op1_b := OpcionEvento.new()
	op1_b.texto_boton = "Rechazar oferta (+$20 impuestos)"
	op1_b.delta_dinero = 20
	ev1.opciones = [op1_a, op1_b]

	# Evento 2: Modernización Logística
	var ev2 := EventoRecurso.new()
	ev2.titulo = "Renovación de Flota y Rutas"
	ev2.descripcion = "El instituto técnico ofrece optimizar los camiones y barcazas para transportar mayor tonelaje."
	var op2_a := OpcionEvento.new()
	op2_a.texto_boton = "Modernizar Fletes (-$50, +5 Capacidad en Fletes)"
	op2_a.delta_dinero = -50
	op2_a.delta_capacidad_fletes = 5
	var op2_b := OpcionEvento.new()
	op2_b.texto_boton = "Subsidiar Combustible (-$30, -1 Costo por viaje)"
	op2_b.delta_dinero = -30
	op2_b.delta_costo_viaje_fletes = -1
	var op2_c := OpcionEvento.new()
	op2_c.texto_boton = "Mantener estado actual"
	ev2.opciones = [op2_a, op2_b, op2_c]

	# Evento 3: Impulso al Canal Magdalena y Astilleros
	var ev3 := EventoRecurso.new()
	ev3.titulo = "Cumbre de Soberanía Fluvial"
	ev3.descripcion = "Las provincias del litoral ofrecen cofinanciar obras estratégicas en el Río Paraná y Río de la Plata."
	var op3_a := OpcionEvento.new()
	op3_a.texto_boton = "Acelerar Dragado Magdalena (-$90, +1 Tramo Magdalena)"
	op3_a.delta_dinero = -90
	op3_a.avanzar_tramo_magdalena = true
	var op3_b := OpcionEvento.new()
	op3_b.texto_boton = "Ampliar Astillero Nacional (-$75, +1 Cupo Marítimo)"
	op3_b.delta_dinero = -75
	op3_b.delta_astilleros = 1
	var op3_c := OpcionEvento.new()
	op3_c.texto_boton = "Incentivo Agrícola (+3 Producción en Productores)"
	op3_c.delta_produccion_productores = 3
	ev3.opciones = [op3_a, op3_b, op3_c]

	catalogo_eventos = [ev1, ev2, ev3]
