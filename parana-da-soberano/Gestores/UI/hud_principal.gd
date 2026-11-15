class_name HUDPrincipal
extends CanvasLayer

@export var gestor_rutas: GestorRutas
@export var gestor_eventos: GestorEventos

var _lbl_soberania: Label
var _bar_soberania: ProgressBar
var _lbl_dinero: Label
var _lbl_ciencia: Label
var _lbl_astilleros: Label
var _lbl_magdalena: Label
var _lbl_modo_ruta: Label
var _lbl_log: Label

var _btn_inv_ciencia: Button
var _btn_inv_magdalena: Button
var _btn_inv_astillero: Button
var _btn_ruta_tierra: Button
var _btn_ruta_mar: Button
var _btn_cancelar_ruta: Button
var _btn_evento_test: Button

var _panel_evento: PanelContainer
var _lbl_titulo_evento: Label
var _lbl_desc_evento: Label
var _contenedor_opciones_evento: VBoxContainer


func _ready() -> void:
	_construir_interfaz()
	Partida.estado_cambiado.connect(_actualizar_hud)
	Partida.mensaje_log.connect(_on_mensaje_log)
	Partida.victoria_alcanzada.connect(_on_victoria)
	Partida.derrota_alcanzada.connect(_on_derrota)

	if gestor_rutas:
		gestor_rutas.add_to_group("gestor_rutas")
		gestor_rutas.modo_conexion_cambiado.connect(_on_modo_conexion_cambiado)

	if gestor_eventos:
		gestor_eventos.evento_disparado.connect(_mostrar_evento)
		gestor_eventos.evento_resuelto.connect(_ocultar_evento)

	_actualizar_hud()


func _construir_interfaz() -> void:
	var barra_top := PanelContainer.new()
	barra_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	barra_top.offset_bottom = 94.0
	add_child(barra_top)

	var vbox_top := VBoxContainer.new()
	barra_top.add_child(vbox_top)

	# Fila 1: Indicadores Globales
	var hbox_stats := HBoxContainer.new()
	hbox_stats.add_theme_constant_override("separation", 18)
	vbox_top.add_child(hbox_stats)

	_lbl_soberania = Label.new()
	hbox_stats.add_child(_lbl_soberania)

	_bar_soberania = ProgressBar.new()
	_bar_soberania.custom_minimum_size = Vector2(140, 22)
	_bar_soberania.max_value = 100.0
	hbox_stats.add_child(_bar_soberania)

	_lbl_dinero = Label.new()
	hbox_stats.add_child(_lbl_dinero)

	_lbl_ciencia = Label.new()
	hbox_stats.add_child(_lbl_ciencia)

	_lbl_astilleros = Label.new()
	hbox_stats.add_child(_lbl_astilleros)

	_lbl_magdalena = Label.new()
	hbox_stats.add_child(_lbl_magdalena)

	# Fila 2: Botones de Inversión y Creación de Rutas
	var hbox_acciones := HBoxContainer.new()
	hbox_acciones.add_theme_constant_override("separation", 10)
	vbox_top.add_child(hbox_acciones)

	_btn_inv_ciencia = Button.new()
	_btn_inv_ciencia.pressed.connect(func() -> void: Partida.invertir_ciencia())
	hbox_acciones.add_child(_btn_inv_ciencia)

	_btn_inv_magdalena = Button.new()
	_btn_inv_magdalena.pressed.connect(func() -> void: Partida.invertir_magdalena())
	hbox_acciones.add_child(_btn_inv_magdalena)

	_btn_inv_astillero = Button.new()
	_btn_inv_astillero.pressed.connect(func() -> void: Partida.invertir_astillero())
	hbox_acciones.add_child(_btn_inv_astillero)

	_btn_ruta_tierra = Button.new()
	_btn_ruta_tierra.text = "+ Nueva Ruta Tierra"
	_btn_ruta_tierra.pressed.connect(func() -> void:
		if gestor_rutas:
			gestor_rutas.iniciar_modo_conexion(Flete.TipoFlete.TIERRA)
	)
	hbox_acciones.add_child(_btn_ruta_tierra)

	_btn_ruta_mar = Button.new()
	_btn_ruta_mar.text = "+ Nueva Ruta Mar"
	_btn_ruta_mar.pressed.connect(func() -> void:
		if gestor_rutas:
			gestor_rutas.iniciar_modo_conexion(Flete.TipoFlete.MAR)
	)
	hbox_acciones.add_child(_btn_ruta_mar)

	_btn_cancelar_ruta = Button.new()
	_btn_cancelar_ruta.text = "Cancelar Conexión"
	_btn_cancelar_ruta.visible = false
	_btn_cancelar_ruta.pressed.connect(func() -> void:
		if gestor_rutas:
			gestor_rutas.cancelar_modo_conexion()
	)
	hbox_acciones.add_child(_btn_cancelar_ruta)

	_btn_evento_test = Button.new()
	_btn_evento_test.text = "Disparar Evento Ahora"
	_btn_evento_test.pressed.connect(func() -> void:
		if gestor_eventos:
			gestor_eventos.disparar_evento_aleatorio()
	)
	hbox_acciones.add_child(_btn_evento_test)

	# Fila 3: Estado de conexión y Log
	var hbox_info := HBoxContainer.new()
	hbox_info.add_theme_constant_override("separation", 20)
	vbox_top.add_child(hbox_info)

	_lbl_modo_ruta = Label.new()
	_lbl_modo_ruta.modulate = Color(1.0, 0.85, 0.2)
	hbox_info.add_child(_lbl_modo_ruta)

	_lbl_log = Label.new()
	_lbl_log.text = "Objetivo: Alcanzar 100% de Soberanía Nacional (Dragar Canal Magdalena otorga +70% fijo)."
	hbox_info.add_child(_lbl_log)

	# Panel flotante para Eventos (No pausa el juego)
	_panel_evento = PanelContainer.new()
	_panel_evento.visible = false
	_panel_evento.custom_minimum_size = Vector2(420, 190)
	_panel_evento.position = Vector2(360, 110)
	add_child(_panel_evento)

	var vbox_ev := VBoxContainer.new()
	vbox_ev.add_theme_constant_override("separation", 8)
	_panel_evento.add_child(vbox_ev)

	_lbl_titulo_evento = Label.new()
	_lbl_titulo_evento.modulate = Color(1.0, 0.9, 0.3)
	vbox_ev.add_child(_lbl_titulo_evento)

	_lbl_desc_evento = Label.new()
	_lbl_desc_evento.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_desc_evento.custom_minimum_size = Vector2(390, 45)
	vbox_ev.add_child(_lbl_desc_evento)

	_contenedor_opciones_evento = VBoxContainer.new()
	vbox_ev.add_child(_contenedor_opciones_evento)


func _actualizar_hud() -> void:
	_lbl_soberania.text = "Soberanía: %.1f%%" % Partida.soberania
	_bar_soberania.value = Partida.soberania
	_lbl_dinero.text = "Dinero: $%d" % Partida.dinero
	_lbl_ciencia.text = "Ciencia: Tier %d (x%.2f)" % [Partida.tier_ciencia, Partida.multiplicador_ganancia]
	_lbl_astilleros.text = "Fletes Mar: %d / %d Astilleros" % [Partida.fletes_mar_activos, Partida.astilleros_nacionales]
	_lbl_magdalena.text = "Canal Magdalena: %.0f%% (+%.0f%% Sob)" % [
		Partida.progreso_magdalena,
		(Partida.progreso_magdalena / 100.0) * Partida.soberania_total_magdalena
	]

	_btn_inv_ciencia.text = "Invertir Ciencia ($%d)" % Partida.obtener_costo_ciencia()
	if Partida.tramos_magdalena_completados >= Partida.tramos_totales_magdalena:
		_btn_inv_magdalena.text = "Canal Magdalena (100% Completo)"
		_btn_inv_magdalena.disabled = true
	else:
		_btn_inv_magdalena.text = "Dragar Magdalena +20%% ($%d -> +14%% Sob)" % Partida.costo_tramo_magdalena
		_btn_inv_magdalena.disabled = false

	_btn_inv_astillero.text = "Construir Astillero ($%d)" % Partida.obtener_costo_astillero()


func _on_modo_conexion_cambiado(activo: bool, texto: String) -> void:
	_lbl_modo_ruta.text = texto
	_btn_cancelar_ruta.visible = activo


func _on_mensaje_log(texto: String) -> void:
	_lbl_log.text = "Último aviso: " + texto


func _mostrar_evento(evento: EventoRecurso) -> void:
	if evento == null:
		return
	_lbl_titulo_evento.text = "EVENTO: " + evento.titulo
	_lbl_desc_evento.text = evento.descripcion

	for hijo in _contenedor_opciones_evento.get_children():
		hijo.queue_free()

	for i in range(evento.opciones.size()):
		var op: OpcionEvento = evento.opciones[i]
		var btn := Button.new()
		btn.text = op.texto_boton
		var idx: int = i
		btn.pressed.connect(func() -> void:
			if gestor_eventos:
				gestor_eventos.elegir_opcion(idx)
		)
		_contenedor_opciones_evento.add_child(btn)

	_panel_evento.visible = true


func _ocultar_evento() -> void:
	_panel_evento.visible = false


func _on_victoria() -> void:
	_lbl_modo_ruta.modulate = Color(0.2, 1.0, 0.3)
	_lbl_modo_ruta.text = "¡¡VICTORIA SOBERANA ALCANZADA (100%)!!"


func _on_derrota() -> void:
	_lbl_modo_ruta.modulate = Color(1.0, 0.25, 0.25)
	_lbl_modo_ruta.text = "DERROTA: SOBERANÍA EN 0%"
