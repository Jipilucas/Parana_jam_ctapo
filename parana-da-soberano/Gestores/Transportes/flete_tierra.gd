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

@export_group("Marina Mercante / Facción")
@export var faccion_inicial: ConfigLogistica.Faccion = ConfigLogistica.Faccion.PROPIO
## Costo en dinero para eliminar una marina mercante enemiga
@export var costo_eliminar: int = 100
## Costo operativo por viaje con carga cuando la marina mercante es ENEMIGA
@export var costo_por_viaje_enemigo: int = 8
## Impacto en soberanía por cada viaje con carga cuando la marina mercante es ENEMIGA (negativo)
@export var impacto_soberania_viaje_enemigo: float = -1.0
## Impacto en soberanía por cada viaje con carga cuando la marina mercante es PROPIA (positivo)
@export var impacto_soberania_viaje_propio: float = 0.5
## Bonus único de soberanía al eliminar una marina mercante enemiga
@export var bonus_soberania_eliminar: float = 3.0

@export_group("Referencias Opcionales")
@export var controlador: ControladorComandos
@export var linea_visual: Line2D
@export var sprite_flete: Sprite2D

@export_group("User Interface")
@export var textlabel : Label
@export var anim_player : AnimationPlayer

var Carga_Actual: int = 0
var ruta_habilitada: bool = false
var faccion_actual: ConfigLogistica.Faccion = ConfigLogistica.Faccion.PROPIO
var bien_transportado: ConfigLogistica.TipoBien = ConfigLogistica.TipoBien.CUALQUIERA
var _registrado_en_astillero: bool = false


func _ready() -> void:
	add_to_group("fletes")
	if controlador == null and has_node("ControladorComandos"):
		controlador = $ControladorComandos as ControladorComandos

	if tipo_flete == TipoFlete.MAR:
		faccion_actual = (
			ConfigLogistica.Faccion.ENEMIGO
			if faccion_inicial == ConfigLogistica.Faccion.ENEMIGO
			else ConfigLogistica.Faccion.PROPIO
		)
	else:
		faccion_actual = ConfigLogistica.Faccion.PROPIO

	if activa_al_inicio:
		if es_enemigo():
			# La marina mercante enemiga opera sin ocupar Astilleros Nacionales
			ruta_habilitada = true
			_registrado_en_astillero = false
		elif tipo_flete == TipoFlete.MAR:
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

	if linea_visual == null and has_node("LineaRuta"):
		linea_visual = $LineaRuta as Line2D
	if sprite_flete == null and has_node("Sprite2D"):
		sprite_flete = $Sprite2D as Sprite2D

	bien_transportado = obtener_bien_origen()
	_sincronizar_controlador()
	_actualizar_visual_faccion()
	_actualizar_linea_visual()


func _exit_tree() -> void:
	if _registrado_en_astillero and is_instance_valid(Partida):
		Partida.registrar_flete_mar(false)
		_registrado_en_astillero = false


func _process(_delta: float) -> void:
	_actualizar_linea_visual()


func es_marina_mercante() -> bool:
	return tipo_flete == TipoFlete.MAR


func es_enemigo() -> bool:
	return es_marina_mercante() and faccion_actual == ConfigLogistica.Faccion.ENEMIGO


func obtener_costo_viaje_actual() -> int:
	return costo_por_viaje_enemigo if es_enemigo() else costo_por_viaje


func obtener_impacto_soberania_actual() -> float:
	if not es_marina_mercante():
		return 0.0
	return impacto_soberania_viaje_enemigo if es_enemigo() else impacto_soberania_viaje_propio


func obtener_bien_origen() -> ConfigLogistica.TipoBien:
	if Remitente == null:
		return ConfigLogistica.TipoBien.CUALQUIERA
	return Remitente.obtener_siguiente_bien_salida()


func _actualizar_visual_faccion() -> void:
	if not es_marina_mercante():
		return
	if es_enemigo():
		if linea_visual:
			linea_visual.default_color = Color(0.95, 0.2, 0.2, 0.9)
		if sprite_flete:
			sprite_flete.modulate = Color(1.0, 0.35, 0.35, 1.0)
	else:
		if linea_visual:
			linea_visual.default_color = Color(0.2, 0.75, 1.0, 0.9)
		if sprite_flete:
			sprite_flete.modulate = Color(0.45, 1.0, 0.6, 1.0)


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

	if es_enemigo():
		ruta_habilitada = true
		_sincronizar_controlador()
		flete_actualizado.emit()
		queue_redraw()
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
	_actualizar_visual_faccion()
	flete_actualizado.emit()
	queue_redraw()
	return true


func desactivar_ruta() -> void:
	if not ruta_habilitada:
		return
	if es_enemigo():
		Partida.mensaje_log.emit("No puedes pausar una Marina Mercante enemiga (%s). Debes eliminarla primero." % obtener_nombre_ruta())
		return
	ruta_habilitada = false
	if _registrado_en_astillero:
		Partida.registrar_flete_mar(false)
		_registrado_en_astillero = false
	_sincronizar_controlador()
	flete_actualizado.emit()
	queue_redraw()


func eliminar_flete_enemigo() -> bool:
	if not es_enemigo():
		return false
	if Partida.dinero < costo_eliminar:
		Partida.mensaje_log.emit("Fondos insuficientes para eliminar %s (Requiere $%d)" % [obtener_nombre_ruta(), costo_eliminar])
		return false

	Partida.modificar_dinero(-costo_eliminar, "Eliminación de Marina Mercante Enemiga (%s)" % obtener_nombre_ruta())
	if bonus_soberania_eliminar != 0.0:
		Partida.modificar_soberania(bonus_soberania_eliminar, "Expulsión de naviera extranjera (%s)" % obtener_nombre_ruta())
	ruta_habilitada = false
	if controlador:
		controlador.detener_ciclo()
	flete_actualizado.emit()
	queue_free()
	return true


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

	var bien_previo: ConfigLogistica.TipoBien = obtener_bien_origen()
	var extraido: int = Remitente.Despachar(a_pedir, es_marina_mercante())
	if extraido > 0:
		if bien_previo != ConfigLogistica.TipoBien.CUALQUIERA:
			bien_transportado = bien_previo
		Carga_Actual += extraido
		var costo_actual: int = obtener_costo_viaje_actual()
		if costo_actual > 0:
			Partida.modificar_dinero(-costo_actual, "Flete %s" % obtener_nombre_ruta())
			mostrar_dinero(costo_actual)
		if es_marina_mercante():
			var impacto_sob: float = obtener_impacto_soberania_actual()
			if impacto_sob != 0.0:
				var motivo: String = (
					"Marina Mercante Extranjera (%s)" % obtener_nombre_ruta()
					if es_enemigo()
					else "Marina Mercante Nacional (%s)" % obtener_nombre_ruta()
				)
				Partida.modificar_soberania(impacto_sob, motivo)
		flete_actualizado.emit()

func mostrar_dinero(cant):
	if textlabel == null or anim_player == null: return
	textlabel.visible = true
	textlabel.text = '-$' + str(cant)
	anim_player.play("mostrar")

func Despachar(cant: int = Capacidad) -> void:
	if not ruta_habilitada or Destinatario == null or not Destinatario.slot_ocupado:
		return
	if Carga_Actual <= 0:
		return

	var a_entregar: int = mini(cant, Carga_Actual)
	var entregado: int = Destinatario.Recibir(a_entregar, bien_transportado, tipo_flete == TipoFlete.TIERRA)
	if entregado > 0:
		Carga_Actual -= entregado
		flete_actualizado.emit()


	

func _actualizar_linea_visual() -> void:
	if linea_visual == null or Remitente == null or Destinatario == null:
		return
	var p_origen: Vector2 = linea_visual.to_local(Remitente.global_position)
	var p_destino: Vector2 = linea_visual.to_local(Destinatario.global_position)
	linea_visual.points = PackedVector2Array([p_origen, p_destino])
	if not ruta_habilitada:
		linea_visual.modulate.a = 0.35
	else:
		linea_visual.modulate.a = 1.0
