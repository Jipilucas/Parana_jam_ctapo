class_name GestorRutas
extends Node2D

signal modo_conexion_cambiado(activo: bool, texto_estado: String)

@export var escena_ui_flete: PackedScene = preload("res://Gestores/UI/datos-felte.tscn")
@export var escena_flete_tierra: PackedScene = preload("res://Gestores/Comercio/Scenes/Fletes/FleteTierra.tscn")
@export var escena_flete_mar: PackedScene = preload("res://Gestores/Comercio/Scenes/Fletes/FleteMar.tscn")
@export var factor_costo_distancia: float = 0.12
@export var costo_minimo_habilitar: int = 35

var modo_conectar_activo: bool = false
var tipo_flete_a_crear: Flete.TipoFlete = Flete.TipoFlete.TIERRA
var nodo_origen_seleccionado: Productor = null


func iniciar_modo_conexion(tipo: Flete.TipoFlete) -> void:
	modo_conectar_activo = true
	tipo_flete_a_crear = tipo
	nodo_origen_seleccionado = null
	var etiqueta_tipo: String = "MAR (Requiere Astillero)" if tipo == Flete.TipoFlete.MAR else "TIERRA"
	modo_conexion_cambiado.emit(true, "Modo Conectar [%s]: Haz clic en el nodo ORIGEN" % etiqueta_tipo)


func cancelar_modo_conexion() -> void:
	modo_conectar_activo = false
	nodo_origen_seleccionado = null
	modo_conexion_cambiado.emit(false, "")


func registrar_clic_en_productor(nodo: Productor) -> void:
	
	
	if not modo_conectar_activo or nodo == null:
		return

	if nodo_origen_seleccionado == null:
		nodo_origen_seleccionado = nodo
		modo_conexion_cambiado.emit(true, "Origen: %s -> Ahora haz clic en el nodo DESTINO" % nodo.obtener_nombre())
		return

	if nodo == nodo_origen_seleccionado:
		Partida.mensaje_log.emit("El nodo destino debe ser distinto al origen.")
		return

	crear_ruta_en_ejecucion(nodo_origen_seleccionado, nodo, tipo_flete_a_crear)
	cancelar_modo_conexion()


func crear_ruta_en_ejecucion(origen: Productor, destino: Productor, tipo: Flete.TipoFlete) -> Flete:
	if tipo == Flete.TipoFlete.TIERRA:
		if origen.config.tipo_entidad == ConfigLogistica.TipoEntidad.PUERTO and origen.config.tipo_entidad == ConfigLogistica.TipoEntidad.PUERTO:
			Partida.mensaje_log.emit("Un mionca por el agua? Tal loco?")
			return
	
	
	
	if tipo == Flete.TipoFlete.MAR and not Partida.puede_activar_flete_mar():
		Partida.mensaje_log.emit("No hay Astilleros Nacionales disponibles para abrir nueva ruta marítima.")
		return null

	var escena: PackedScene = escena_flete_mar if tipo == Flete.TipoFlete.MAR else escena_flete_tierra
	var nuevo_flete: Flete = null
	if escena:
		nuevo_flete = escena.instantiate() as Flete
		var ctrl_escena := nuevo_flete.get_node_or_null("ControladorComandos") as ControladorComandos
		if ctrl_escena:
			ctrl_escena.auto_iniciar = false
	else:
		nuevo_flete = Flete.new()
		nuevo_flete.Capacidad = 15 if tipo == Flete.TipoFlete.MAR else 10
		nuevo_flete.costo_habilitar = costo_minimo_habilitar
		nuevo_flete.costo_por_viaje = 2 if tipo == Flete.TipoFlete.MAR else 10
		var linea := Line2D.new()
		linea.name = "LineaRuta"
		linea.width = 3.0
		linea.default_color = Color(0.2, 0.75, 1.0, 0.85) if tipo == Flete.TipoFlete.MAR else Color(0.95, 0.7, 0.2, 0.85)
		nuevo_flete.add_child(linea)
		nuevo_flete.linea_visual = linea

		var ctrl := ControladorComandos.new()
		ctrl.name = "ControladorComandos"
		ctrl.actor = nuevo_flete
		ctrl.auto_iniciar = false
		ctrl.intervalo_rutina = 1.5
		var cmd_recibir := ComandoRecibir.new()
		var cmd_esperar := ComandoEsperar.new(1.5)
		var cmd_despachar := ComandoDespachar.new()
		ctrl.rutina = [cmd_recibir, cmd_esperar, cmd_despachar]
		nuevo_flete.add_child(ctrl)
		nuevo_flete.controlador = ctrl

		if escena_ui_flete:
			var ui_instancia := escena_ui_flete.instantiate() as UIFlete
			ui_instancia.entidad = nuevo_flete
			ui_instancia.comandos = ctrl
			nuevo_flete.add_child(ui_instancia)

	if Partida.dinero < nuevo_flete.costo_habilitar:
		Partida.mensaje_log.emit("Fondos insuficientes para abrir ruta ($%d requeridos)." % nuevo_flete.costo_habilitar)
		nuevo_flete.free()
		return null

	nuevo_flete.name = "Flete_%s_%s" % [origen.name, destino.name]
	nuevo_flete.nombre_ruta = "%s -> %s" % [origen.obtener_nombre(), destino.obtener_nombre()]
	nuevo_flete.tipo_flete = tipo
	nuevo_flete.faccion_inicial = ConfigLogistica.Faccion.PROPIO
	nuevo_flete.Remitente = origen
	nuevo_flete.Destinatario = destino
	nuevo_flete.activa_al_inicio = false
	nuevo_flete.global_position = (origen.global_position + destino.global_position) * 0.5

	get_parent().add_child(nuevo_flete)
	nuevo_flete.habilitar_ruta()
	return nuevo_flete
