class_name GestorPartida
extends Node

signal estado_cambiado
signal mensaje_log(texto: String)
signal victoria_alcanzada
signal derrota_alcanzada

@export_group("Estado Inicial")
@export var dinero: int = 300
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


func _ready() -> void:
	_recalcular_multiplicadores()
	estado_cambiado.emit()


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
	soberania = clampf(soberania + delta, 0.0, 100.0)
	if motivo != "":
		var signo: String = "+" if delta >= 0.0 else ""
		var msg: String = "%s: %s%.1f%% Soberanía (%.1f%%)" % [motivo, signo, delta, soberania]
		print("[Partida] ", msg)
		mensaje_log.emit(msg)
	estado_cambiado.emit()

	if soberania >= 100.0:
		juego_terminado = true
		mensaje_log.emit("¡VICTORIA! Alcanzaste el 100% de Soberanía Nacional en el Paraná.")
		victoria_alcanzada.emit()
	elif soberania <= 0.0:
		juego_terminado = true
		mensaje_log.emit("DERROTA: La Soberanía cayó al 0%.")
		derrota_alcanzada.emit()


func obtener_costo_ciencia() -> int:
	return costo_base_ciencia * tier_ciencia


func invertir_ciencia() -> bool:
	if juego_terminado:
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
	if juego_terminado:
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
	if juego_terminado:
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
