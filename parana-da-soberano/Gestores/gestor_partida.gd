class_name GestorPartida
extends Node

signal estado_cambiado
signal mensaje_log(texto: String)
signal victoria_alcanzada
signal derrota_alcanzada
signal pausa_cambiada(pausado: bool)

const OBJETIVO_SOBERANIA_NORMAL: float = 100.0
const OBJETIVO_SOBERANIA_SANDBOX: float = 1000.0

@export_group("Estado Inicial")
var dinero: int = 3000
@export var soberania: float = 20.0
@export var tier_ciencia: int = 1
@export var astilleros_nacionales: int = 1

@export_group("Costos de Inversión")
@export var costo_base_ciencia: int = 100
@export var costo_tramo_magdalena: int = 150
@export var tramos_totales_magdalena: int = 5
@export var soberania_total_magdalena: float = 70.0
@export var costo_base_astillero: int = 120

var progreso_magdalena: float = 0.0
var tramos_magdalena_completados: int = 0
var fletes_mar_activos: int = 0
var multiplicador_ganancia: float = 1.0
var juego_terminado: bool = false

var modo_sandbox: bool = false
var objetivo_soberania: float = OBJETIVO_SOBERANIA_NORMAL

var pausado_manual: bool = false
var pausado_por_evento: bool = false
var pausado_por_fin_partida: bool = false

var _dinero_inicial: int = 3000
var _soberania_inicial: float = 20.0
var _tier_ciencia_inicial: int = 1
var _astilleros_inicial: int = 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dinero_inicial = dinero
	_soberania_inicial = soberania
	_tier_ciencia_inicial = tier_ciencia
	_astilleros_inicial = astilleros_nacionales
	_recalcular_multiplicadores()
	estado_cambiado.emit()


func reiniciar_partida(activar_sandbox: bool = false) -> void:
	dinero = _dinero_inicial
	soberania = _soberania_inicial
	tier_ciencia = _tier_ciencia_inicial
	astilleros_nacionales = _astilleros_inicial
	progreso_magdalena = 0.0
	tramos_magdalena_completados = 0
	fletes_mar_activos = 0
	juego_terminado = false

	modo_sandbox = activar_sandbox
	objetivo_soberania = OBJETIVO_SOBERANIA_SANDBOX if activar_sandbox else OBJETIVO_SOBERANIA_NORMAL

	pausado_manual = false
	pausado_por_evento = false
	pausado_por_fin_partida = false
	_aplicar_estado_pausa()

	_recalcular_multiplicadores()
	estado_cambiado.emit()


func activar_modo_sandbox() -> void:
	modo_sandbox = true
	objetivo_soberania = OBJETIVO_SOBERANIA_SANDBOX
	juego_terminado = false
	pausado_manual = false
	pausado_por_fin_partida = false
	_aplicar_estado_pausa()
	mensaje_log.emit("¡MODO SANDBOX ACTIVADO! Nuevo objetivo: %.0f%% de Soberanía Nacional." % objetivo_soberania)
	estado_cambiado.emit()


func esta_pausado() -> bool:
	return pausado_manual or pausado_por_evento or pausado_por_fin_partida


func alternar_pausa_manual() -> void:
	if pausado_por_evento or pausado_por_fin_partida or juego_terminado:
		return
	pausado_manual = not pausado_manual
	_aplicar_estado_pausa()


func set_pausa_manual(valor: bool) -> void:
	if pausado_manual == valor:
		return
	pausado_manual = valor
	_aplicar_estado_pausa()


func set_pausa_evento(valor: bool) -> void:
	if pausado_por_evento == valor:
		return
	pausado_por_evento = valor
	_aplicar_estado_pausa()


func _aplicar_estado_pausa() -> void:
	var nuevo_estado: bool = esta_pausado()
	if get_tree() != null:
		get_tree().paused = nuevo_estado
	pausa_cambiada.emit(nuevo_estado)


func _recalcular_multiplicadores() -> void:
	multiplicador_ganancia = 1.0 + float(tier_ciencia - 1) * 0.35


func modificar_dinero(delta: int, motivo: String = "") -> void:
	if juego_terminado:
		return
	dinero += delta
	if motivo != "":
		var signo: String = "+" if delta >= 0 else ""
		var msg: String = "%s: %s$%d (Total: $%d)" % [motivo, signo, delta, dinero]
		print("[Partida] ", msg)
		mensaje_log.emit(msg)
	estado_cambiado.emit()


func modificar_soberania(delta: float, motivo: String = "") -> void:
	if juego_terminado:
		return
	soberania = clampf(soberania + delta, 0.0, objetivo_soberania)
	if motivo != "":
		var signo: String = "+" if delta >= 0.0 else ""
		var msg: String = "%s: %s%.1f%% Soberanía (%.1f%%)" % [motivo, signo, delta, soberania]
		print("[Partida] ", msg)
		mensaje_log.emit(msg)
	estado_cambiado.emit()

	if soberania >= objetivo_soberania:
		juego_terminado = true
		pausado_por_fin_partida = true
		_aplicar_estado_pausa()
		mensaje_log.emit("¡VICTORIA! Alcanzaste el %.0f%% de Soberanía Nacional en el Paraná." % objetivo_soberania)
		victoria_alcanzada.emit()
	elif soberania <= 0.0:
		juego_terminado = true
		pausado_por_fin_partida = true
		_aplicar_estado_pausa()
		mensaje_log.emit("DERROTA: La Soberanía cayó al 0%.")
		derrota_alcanzada.emit()


func obtener_costo_ciencia() -> int:
	return costo_base_ciencia * tier_ciencia


func invertir_ciencia() -> bool:
	if juego_terminado or esta_pausado():
		return false
	var costo: int = obtener_costo_ciencia()
	if dinero < costo:
		mensaje_log.emit("Fondos insuficientes para Educación/Ciencia (Requiere $%d)" % costo)
		return false
	dinero -= costo
	tier_ciencia += 1
	_recalcular_multiplicadores()
	mensaje_log.emit("Inversión en Educación/Ciencia -> Nivel %d (Ganancias x%.2f)" % [tier_ciencia, multiplicador_ganancia])
	estado_cambiado.emit()
	return true


func invertir_magdalena() -> bool:
	if juego_terminado or esta_pausado():
		return false
	if tramos_magdalena_completados >= tramos_totales_magdalena:
		mensaje_log.emit("El Dragado del Canal Magdalena ya está al 100%.")
		return false
	if dinero < costo_tramo_magdalena:
		mensaje_log.emit("Fondos insuficientes para dragar el Canal Magdalena (Requiere $%d)" % costo_tramo_magdalena)
		return false

	dinero -= costo_tramo_magdalena
	tramos_magdalena_completados += 1
	progreso_magdalena = (float(tramos_magdalena_completados) / float(tramos_totales_magdalena)) * 100.0
	var ganancia_soberania_tramo: float = soberania_total_magdalena / float(tramos_totales_magdalena)
	modificar_soberania(ganancia_soberania_tramo, "Dragado Canal Magdalena (%.0f%%)" % progreso_magdalena)
	estado_cambiado.emit()
	return true


func obtener_costo_astillero() -> int:
	return costo_base_astillero * astilleros_nacionales


func invertir_astillero() -> bool:
	if juego_terminado or esta_pausado():
		return false
	var costo: int = obtener_costo_astillero()
	if dinero < costo:
		mensaje_log.emit("Fondos insuficientes para Astillero Nacional (Requiere $%d)" % costo)
		return false
	dinero -= costo
	astilleros_nacionales += 1
	mensaje_log.emit("Nuevo Astillero Nacional inaugurado (Cupo Fletes Mar: %d/%d)" % [fletes_mar_activos, astilleros_nacionales])
	estado_cambiado.emit()
	return true


func puede_activar_flete_mar() -> bool:
	return fletes_mar_activos < astilleros_nacionales


func registrar_flete_mar(activo: bool) -> void:
	if activo:
		fletes_mar_activos += 1
	else:
		fletes_mar_activos = maxi(0, fletes_mar_activos - 1)
	estado_cambiado.emit()
