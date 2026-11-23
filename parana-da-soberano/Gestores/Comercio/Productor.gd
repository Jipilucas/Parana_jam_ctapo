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

@export_group("UserInterface")
@export var anim_player:AnimationPlayer
@export var label_regalias :Label
@export var label_soberania:Label

var faccion_actual: ConfigLogistica.Faccion = ConfigLogistica.Faccion.NEUTRAL
var stock_entrada: int = 0
var stock_salida: int = 0
var bonus_produccion: int = 0
var _insumo_consumido_en_ciclo: bool = false

## Colas FIFO exclusivas para Puertos. Cada elemento es {"tipo": ConfigLogistica.TipoBien, "cantidad": int}
var cola_entrada: Array[Dictionary] = []
var cola_salida: Array[Dictionary] = []
var _lote_en_proceso: Array[Dictionary] = []


func _ready() -> void:
	add_to_group("productores")
	if config == null:
		config = ConfigLogistica.new()
	faccion_actual = config.faccion_inicial
	if slot_ocupado:
		_inicializar_stocks()
	if controlador == null and has_node("ControladorComandos"):
		controlador = $ControladorComandos as ControladorComandos
	if anim_player == null:
		anim_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if label_regalias == null:
		label_regalias = get_node_or_null("LabelRegalias") as Label
	if label_soberania == null:
		label_soberania = get_node_or_null("LabelSoberania") as Label
	if label_regalias:
		label_regalias.visible = false
	if label_soberania:
		label_soberania.visible = false
	if anim_player:
		anim_player.stop()
		if not anim_player.animation_finished.is_connected(_on_anim_intercambio_finished):
			anim_player.animation_finished.connect(_on_anim_intercambio_finished)
	_sincronizar_estado_controlador()
	queue_redraw()


func _inicializar_stocks() -> void:
	cola_entrada.clear()
	cola_salida.clear()
	_lote_en_proceso.clear()
	if es_puerto():
		if config.stock_inicial_entrada > 0:
			var bien_in: ConfigLogistica.TipoBien = config.bien_entrada
			if bien_in == ConfigLogistica.TipoBien.CUALQUIERA:
				bien_in = ConfigLogistica.TipoBien.MATERIA_PRIMA
			_encolar_fifo(cola_entrada, bien_in, config.stock_inicial_entrada)
		if config.stock_inicial_salida > 0:
			var bien_out: ConfigLogistica.TipoBien = config.bien_salida
			if bien_out == ConfigLogistica.TipoBien.CUALQUIERA:
				bien_out = ConfigLogistica.TipoBien.MATERIA_PRIMA
			_encolar_fifo(cola_salida, bien_out, config.stock_inicial_salida)
		stock_entrada = _contar_cola(cola_entrada)
		stock_salida = _contar_cola(cola_salida)
	else:
		stock_entrada = config.stock_inicial_entrada
		stock_salida = config.stock_inicial_salida


func es_puerto() -> bool:
	return config != null and config.tipo_entidad == ConfigLogistica.TipoEntidad.PUERTO


func _encolar_fifo(cola: Array[Dictionary], tipo_bien: ConfigLogistica.TipoBien, cant: int) -> void:
	if cant <= 0:
		return
	if not cola.is_empty() and cola[cola.size() - 1]["tipo"] == tipo_bien:
		cola[cola.size() - 1]["cantidad"] = int(cola[cola.size() - 1]["cantidad"]) + cant
	else:
		cola.append({"tipo": tipo_bien, "cantidad": cant})


func _desencolar_fifo(cola: Array[Dictionary], cant: int) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	var restante: int = cant
	while restante > 0 and not cola.is_empty():
		var frente: Dictionary = cola[0]
		var disponible: int = int(frente["cantidad"])
		var tomar: int = mini(restante, disponible)
		if tomar > 0:
			_encolar_fifo(resultado, frente["tipo"] as ConfigLogistica.TipoBien, tomar)
			restante -= tomar
		if tomar >= disponible:
			cola.remove_at(0)
		else:
			frente["cantidad"] = disponible - tomar
	return resultado


func _contar_cola(cola: Array[Dictionary]) -> int:
	var total: int = 0
	for lote in cola:
		total += int(lote["cantidad"])
	return total


func contar_por_tipo(cola: Array[Dictionary], tipo_bien: ConfigLogistica.TipoBien) -> int:
	var total: int = 0
	for lote in cola:
		if lote["tipo"] == tipo_bien:
			total += int(lote["cantidad"])
	return total


func obtener_siguiente_bien_salida() -> ConfigLogistica.TipoBien:
	if es_puerto():
		if not cola_salida.is_empty():
			return cola_salida[0]["tipo"] as ConfigLogistica.TipoBien
		return config.bien_salida
	if config != null:
		return config.bien_salida
	return ConfigLogistica.TipoBien.CUALQUIERA


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
			if config.cantidad_consumo > 0 and stock_entrada >= config.cantidad_consumo:
				_lote_en_proceso = _desencolar_fifo(cola_entrada, config.cantidad_consumo)
				stock_entrada = _contar_cola(cola_entrada)
				_insumo_consumido_en_ciclo = not _lote_en_proceso.is_empty()
				stock_actualizado.emit()

func _on_anim_intercambio_finished(anim_name: StringName) -> void:
	if anim_name == &"mostrar":
		if label_regalias:
			label_regalias.visible = false
		if label_soberania:
			label_soberania.visible = false


func _formatear_valor(valor: float) -> String:
	var signo: String = "+" if valor > 0.0 else "-"
	var abs_val: float = absf(valor)
	if is_equal_approx(abs_val, roundf(abs_val)):
		return "%s%d" % [signo, int(roundf(abs_val))]
	return "%s%.1f" % [signo, abs_val]


func mostrar_intercambio(cant_reg: float = 0.0, cant_sob: float = 0.0) -> void:
	if label_regalias == null or label_soberania == null or anim_player == null:
		return
	if is_zero_approx(cant_reg) and is_zero_approx(cant_sob):
		return

	var mostrar_reg: bool = not is_zero_approx(cant_reg)
	var mostrar_sob: bool = not is_zero_approx(cant_sob)

	label_regalias.modulate = Color.WHITE
	label_soberania.modulate = Color.WHITE
	label_regalias.visible = mostrar_reg
	label_soberania.visible = mostrar_sob

	if mostrar_reg:
		var signo_reg: String = "+" if cant_reg > 0.0 else "-"
		label_regalias.text = "%s$%s" % [signo_reg, str(int(roundf(absf(cant_reg)))) if is_equal_approx(absf(cant_reg), roundf(absf(cant_reg))) else ("%.1f" % absf(cant_reg))]
	if mostrar_sob:
		label_soberania.text = "%s%%" % _formatear_valor(cant_sob)

	anim_player.stop()
	anim_player.play("mostrar")
	
func Producir() -> void:
	if not slot_ocupado or config == null:
		return

	if config.tipo_entidad == ConfigLogistica.TipoEntidad.CIUDAD:
		if _insumo_consumido_en_ciclo:
			var ganancia_ciudad: int = int(round(float(config.ganancia_propio) * Partida.multiplicador_ganancia))
			Partida.modificar_dinero(ganancia_ciudad, "Consumo en %s" % obtener_nombre())
			Partida.modificar_soberania(config.impacto_soberania_propio, "Abastecimiento a %s" % obtener_nombre())
			mostrar_intercambio(ganancia_ciudad, config.impacto_soberania_propio)
		else:
			var multa_dinero: int = -absi(config.multa_desabastecimiento_dinero)
			var multa_sob: float = -absf(config.multa_desabastecimiento_soberania)
			Partida.modificar_dinero(multa_dinero, "Multa por desabastecimiento en %s" % obtener_nombre())
			Partida.modificar_soberania(multa_sob, "Multa por desabastecimiento en %s" % obtener_nombre())
			mostrar_intercambio(multa_dinero, multa_sob)
		_insumo_consumido_en_ciclo = false
		stock_actualizado.emit()
		return

	if not _insumo_consumido_en_ciclo:
		return

	var cant_producida: int = maxi(1, config.cantidad_produccion + bonus_produccion)

	match config.tipo_entidad:
		ConfigLogistica.TipoEntidad.MATERIA_PRIMA:
			stock_salida += cant_producida

		ConfigLogistica.TipoEntidad.MANUFACTURA:
			stock_salida += cant_producida
			if faccion_actual == ConfigLogistica.Faccion.PROPIO:
				Partida.modificar_soberania(config.impacto_soberania_propio, "Industria Nacional (%s)" % obtener_nombre())
				Partida.modificar_dinero(config.ganancia_propio,"Industria Nacional (%s)" % obtener_nombre())
				mostrar_intercambio(config.ganancia_propio,config.impacto_soberania_propio)
			elif faccion_actual == ConfigLogistica.Faccion.ENEMIGO:
				Partida.modificar_soberania(config.impacto_soberania_enemigo, "Industria Extranjera (%s)" % obtener_nombre())
				Partida.modificar_dinero(config.ganancia_enemigo, "Industria Extranjera (%s)" % obtener_nombre())
				mostrar_intercambio(config.ganancia_enemigo,config.impacto_soberania_enemigo)

		ConfigLogistica.TipoEntidad.PUERTO:
			# En puertos, Producir únicamente mueve los bienes de entrada a la lista FIFO de salida
			for lote in _lote_en_proceso:
				_encolar_fifo(cola_salida, lote["tipo"] as ConfigLogistica.TipoBien, int(lote["cantidad"]))
			_lote_en_proceso.clear()
			stock_salida = _contar_cola(cola_salida)

	_insumo_consumido_en_ciclo = false
	stock_actualizado.emit()


func Recibir(
	cant: int,
	tipo_bien: ConfigLogistica.TipoBien = ConfigLogistica.TipoBien.CUALQUIERA,
	_definir_por_flete_tierra: bool = false
) -> int:
	if not slot_ocupado or cant <= 0:
		return 0
	if es_puerto():
		var bien_a_ingresar: ConfigLogistica.TipoBien = ConfigLogistica.TipoBien.CUALQUIERA
		if tipo_bien != ConfigLogistica.TipoBien.CUALQUIERA:
			bien_a_ingresar = tipo_bien
		elif config.bien_entrada != ConfigLogistica.TipoBien.CUALQUIERA:
			bien_a_ingresar = config.bien_entrada
		else:
			bien_a_ingresar = ConfigLogistica.TipoBien.MATERIA_PRIMA
		_encolar_fifo(cola_entrada, bien_a_ingresar, cant)
		stock_entrada = _contar_cola(cola_entrada)
	else:
		stock_entrada += cant
	stock_actualizado.emit()
	return cant


func Despachar(cant: int, es_exportacion: bool = true) -> int:
	if not slot_ocupado or cant <= 0 or stock_salida <= 0:
		return 0
	if es_puerto():
		var lotes_despachados: Array[Dictionary] = _desencolar_fifo(cola_salida, cant)
		stock_salida = _contar_cola(cola_salida)
		var cant_mp: int = 0
		var cant_manuf: int = 0
		for lote in lotes_despachados:
			if lote["tipo"] == ConfigLogistica.TipoBien.MANUFACTURA:
				cant_manuf += int(lote["cantidad"])
			else:
				cant_mp += int(lote["cantidad"])
		var extraido_puerto: int = cant_mp + cant_manuf
		if extraido_puerto > 0 and es_exportacion and config != null and config.cantidad_consumo > 0:
			_aplicar_economia_exportacion_puerto(cant_mp, cant_manuf)
		stock_actualizado.emit()
		return extraido_puerto

	var extraido: int = mini(cant, stock_salida)
	stock_salida -= extraido
	stock_actualizado.emit()
	return extraido


func _aplicar_economia_exportacion_puerto(cant_mp: int, cant_manuf: int) -> void:
	var ref_lote: float = float(maxi(1, config.cantidad_consumo))
	var fraccion_mp: float = float(cant_mp) / ref_lote
	var fraccion_manuf: float = float(cant_manuf) / ref_lote
	var detalle_bienes: String = _formatear_detalle_exportacion(cant_mp, cant_manuf)

	if faccion_actual == ConfigLogistica.Faccion.PROPIO:
		var ingreso_base: float = float(config.ganancia_propio) * (
			fraccion_mp + fraccion_manuf * config.multiplicador_ganancia_manufactura
		)
		var ingreso: int = int(round(ingreso_base * Partida.multiplicador_ganancia))
		if ingreso == 0 and config.ganancia_propio > 0 and (cant_mp + cant_manuf) > 0:
			ingreso = 1
		var sob: float = config.impacto_soberania_propio * (
			fraccion_mp + fraccion_manuf * config.multiplicador_soberania_manufactura
		)
		Partida.modificar_dinero(ingreso, "Exportación (%s) en %s" % [detalle_bienes, obtener_nombre()])
		Partida.modificar_soberania(sob, "Exportación Soberana (%s) en %s" % [detalle_bienes, obtener_nombre()])
		mostrar_intercambio(ingreso, snappedf(sob, 0.1))
	else:
		var fraccion_total: float = fraccion_mp + fraccion_manuf
		var regalia: int = int(round(float(config.ganancia_enemigo) * fraccion_total))
		var sob_enem: float = config.impacto_soberania_enemigo * fraccion_total
		Partida.modificar_dinero(regalia, "Regalía mínima (%s) en %s" % [detalle_bienes, obtener_nombre()])
		Partida.modificar_soberania(sob_enem, "Fuga (%s) por %s" % [detalle_bienes, obtener_nombre()])
		mostrar_intercambio(regalia, snappedf(sob_enem, 0.1))


func _formatear_detalle_exportacion(cant_mp: int, cant_manuf: int) -> String:
	var partes: Array[String] = []
	if cant_mp > 0:
		partes.append("%d Mat. Prima" % cant_mp)
	if cant_manuf > 0:
		partes.append("%d Manufactura" % cant_manuf)
	return " + ".join(partes)


func construir_en_slot() -> bool:
	if slot_ocupado:
		return false
	if Partida.dinero < costo_construir_en_slot:
		Partida.mensaje_log.emit("Fondos insuficientes para construir en %s ($%d)" % [obtener_nombre(), costo_construir_en_slot])
		return false
	Partida.modificar_dinero(-costo_construir_en_slot, "Construcción de %s" % obtener_nombre())
	activar_slot_como_propio()
	Partida.modificar_soberania(4.0, "Nueva planta nacional (%s)" % obtener_nombre())
	mostrar_intercambio(-costo_construir_en_slot, 4.0)
	return true


func activar_slot_como_propio() -> void:
	slot_ocupado = true
	faccion_actual = ConfigLogistica.Faccion.PROPIO
	_inicializar_stocks()
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
	mostrar_intercambio(-config.costo_compra,6.0)
	return true
