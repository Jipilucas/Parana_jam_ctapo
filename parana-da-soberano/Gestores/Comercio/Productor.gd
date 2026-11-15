class_name Productor
extends Node2D

signal stock_actualizado
signal estado_slot_cambiado

@export_group("Slot y Configuración")
## Si es false, este nodo actúa como un Slot vacío donde el jugador o un evento puede instalar la entidad
@export var slot_ocupado: bool = true
@export var costo_construir_en_slot: int = 90
@export var config: ConfigLogistica

@export_group("Referencias Opcionales")
@export var controlador: ControladorComandos

var faccion_actual: ConfigLogistica.Faccion = ConfigLogistica.Faccion.NEUTRAL
var stock_entrada: int = 0
var stock_salida: int = 0
var bonus_produccion: int = 0
var _insumo_consumido_en_ciclo: bool = false
var _cantidad_a_exportar: int = 0


func _ready() -> void:
	add_to_group("productores")
	if config == null:
		config = ConfigLogistica.new()
	faccion_actual = config.faccion_inicial
	if slot_ocupado:
		stock_entrada = config.stock_inicial_entrada
		stock_salida = config.stock_inicial_salida
	if controlador == null and has_node("ControladorComandos"):
		controlador = $ControladorComandos as ControladorComandos
	_sincronizar_estado_controlador()
	queue_redraw()


func _sincronizar_estado_controlador() -> void:
	if controlador == null:
		return
	if slot_ocupado:
		if not controlador._activo:
			controlador.iniciar_ciclo.call_deferred()
	else:
		controlador.detener_ciclo()


func obtener_nombre() -> String:
	if config and config.nombre_mostrar != "":
		return config.nombre_mostrar
	return name


func Consumir() -> void:
	_insumo_consumido_en_ciclo = false
	_cantidad_a_exportar = 0

	if not slot_ocupado or config == null:
		return

	match config.tipo_entidad:
		ConfigLogistica.TipoEntidad.MATERIA_PRIMA:
			# El productor primario neutral genera materia prima sin insumo previo
			_insumo_consumido_en_ciclo = true

		ConfigLogistica.TipoEntidad.MANUFACTURA:
			if stock_entrada >= config.cantidad_consumo:
				stock_entrada -= config.cantidad_consumo
				_insumo_consumido_en_ciclo = true
				stock_actualizado.emit()

		ConfigLogistica.TipoEntidad.CIUDAD:
			if stock_entrada >= config.cantidad_consumo:
				stock_entrada -= config.cantidad_consumo
				_insumo_consumido_en_ciclo = true
				stock_actualizado.emit()

		ConfigLogistica.TipoEntidad.PUERTO:
			# 1) Si tiene bienes de entrada (Materia Prima o Manufactura), consume un lote para exportar
			if stock_entrada >= config.cantidad_consumo:
				_cantidad_a_exportar = config.cantidad_consumo
				stock_entrada -= _cantidad_a_exportar
				_insumo_consumido_en_ciclo = true
				stock_actualizado.emit()
			# 2) Si el puerto también abastece Manufactura importada a la Ciudad y tiene poco stock de salida
			elif config.modo_puerto != ConfigLogistica.ModoPuerto.EXPORTADOR and stock_salida < config.cantidad_produccion * 2:
				_insumo_consumido_en_ciclo = true


func Producir() -> void:
	if not slot_ocupado or config == null or not _insumo_consumido_en_ciclo:
		return

	var cant_producida: int = maxi(1, config.cantidad_produccion + bonus_produccion)

	match config.tipo_entidad:
		ConfigLogistica.TipoEntidad.MATERIA_PRIMA:
			stock_salida += cant_producida

		ConfigLogistica.TipoEntidad.MANUFACTURA:
			stock_salida += cant_producida
			if faccion_actual == ConfigLogistica.Faccion.PROPIO:
				Partida.modificar_soberania(config.impacto_soberania_propio, "Industria Nacional (%s)" % obtener_nombre())
			elif faccion_actual == ConfigLogistica.Faccion.ENEMIGO:
				Partida.modificar_soberania(config.impacto_soberania_enemigo, "Industria Extranjera (%s)" % obtener_nombre())

		ConfigLogistica.TipoEntidad.CIUDAD:
			var ganancia_ciudad: int = int(round(float(config.ganancia_propio) * Partida.multiplicador_ganancia))
			Partida.modificar_dinero(ganancia_ciudad, "Consumo en %s" % obtener_nombre())
			Partida.modificar_soberania(config.impacto_soberania_propio, "Abastecimiento a %s" % obtener_nombre())

		ConfigLogistica.TipoEntidad.PUERTO:
			if _cantidad_a_exportar > 0:
				if faccion_actual == ConfigLogistica.Faccion.PROPIO:
					var ingreso: int = int(round(float(config.ganancia_propio) * Partida.multiplicador_ganancia))
					Partida.modificar_dinero(ingreso, "Exportación en %s" % obtener_nombre())
					Partida.modificar_soberania(config.impacto_soberania_propio, "Exportación Soberana (%s)" % obtener_nombre())
				else:
					Partida.modificar_dinero(config.ganancia_enemigo, "Regalía mínima en %s" % obtener_nombre())
					Partida.modificar_soberania(config.impacto_soberania_enemigo, "Fuga por %s" % obtener_nombre())
			elif config.modo_puerto != ConfigLogistica.ModoPuerto.EXPORTADOR:
				# Importa manufactura para que un flete pueda llevarla a la Ciudad
				stock_salida += cant_producida
				if config.costo_importacion_puerto > 0:
					Partida.modificar_dinero(-config.costo_importacion_puerto, "Importación de Manufactura (%s)" % obtener_nombre())
				if faccion_actual == ConfigLogistica.Faccion.ENEMIGO:
					Partida.modificar_soberania(config.impacto_soberania_enemigo * 0.5, "Dependencia importadora (%s)" % obtener_nombre())

	_insumo_consumido_en_ciclo = false
	_cantidad_a_exportar = 0
	stock_actualizado.emit()


func Recibir(cant: int) -> int:
	if not slot_ocupado or cant <= 0:
		return 0
	stock_entrada += cant
	stock_actualizado.emit()
	return cant


func Despachar(cant: int) -> int:
	if not slot_ocupado or cant <= 0 or stock_salida <= 0:
		return 0
	var extraido: int = mini(cant, stock_salida)
	stock_salida -= extraido
	stock_actualizado.emit()
	return extraido


func construir_en_slot() -> bool:
	if slot_ocupado:
		return false
	if Partida.dinero < costo_construir_en_slot:
		Partida.mensaje_log.emit("Fondos insuficientes para construir en %s ($%d)" % [obtener_nombre(), costo_construir_en_slot])
		return false
	Partida.modificar_dinero(-costo_construir_en_slot, "Construcción de %s" % obtener_nombre())
	activar_slot_como_propio()
	Partida.modificar_soberania(4.0, "Nueva planta nacional (%s)" % obtener_nombre())
	return true


func activar_slot_como_propio() -> void:
	slot_ocupado = true
	faccion_actual = ConfigLogistica.Faccion.PROPIO
	stock_entrada = config.stock_inicial_entrada
	stock_salida = config.stock_inicial_salida
	_sincronizar_estado_controlador()
	estado_slot_cambiado.emit()
	stock_actualizado.emit()
	queue_redraw()


func nacionalizar() -> bool:
	if not slot_ocupado or faccion_actual != ConfigLogistica.Faccion.ENEMIGO:
		return false
	if Partida.tier_ciencia < config.tier_ciencia_requerido:
		Partida.mensaje_log.emit("Requiere Ciencia Nivel %d para nacionalizar %s" % [config.tier_ciencia_requerido, obtener_nombre()])
		return false
	if Partida.dinero < config.costo_compra:
		Partida.mensaje_log.emit("Fondos insuficientes para nacionalizar %s ($%d)" % [obtener_nombre(), config.costo_compra])
		return false

	Partida.modificar_dinero(-config.costo_compra, "Nacionalización de %s" % obtener_nombre())
	faccion_actual = ConfigLogistica.Faccion.PROPIO
	Partida.modificar_soberania(6.0, "Recuperación soberana de %s" % obtener_nombre())
	estado_slot_cambiado.emit()
	return true
