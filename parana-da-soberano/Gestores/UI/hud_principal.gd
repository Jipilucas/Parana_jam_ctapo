class_name HUDPrincipal
extends CanvasLayer

@export_group("Gestores")
@export var gestor_rutas: GestorRutas
@export var gestor_eventos: GestorEventos

@export_group("Indicadores Superiores")
@export var lbl_soberania: Label
@export var bar_soberania: ProgressBar
@export var lbl_dinero: Label
@export var lbl_ciencia: Label
@export var lbl_astilleros: Label
@export var lbl_magdalena: Label
@export var lbl_modo_ruta: Label
@export var lbl_log: Label

@export_group("Botones de Inversión y Rutas")
@export var btn_inv_ciencia: Button
@export var btn_inv_magdalena: Button
@export var btn_inv_astillero: Button
@export var btn_ruta_tierra: Button
@export var btn_ruta_mar: Button
@export var btn_cancelar_ruta: Button
@export var btn_evento_test: Button

@export_group("Panel de Eventos")
@export var panel_evento: Control
@export var lbl_titulo_evento: Label
@export var lbl_desc_evento: Label
@export var btn_opcion_1: Button
@export var btn_opcion_2: Button
@export var btn_opcion_3: Button


func _ready() -> void:
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


func _actualizar_hud() -> void:
	if lbl_soberania:
		lbl_soberania.text = "Soberanía: %.1f%%" % Partida.soberania
	if bar_soberania:
		bar_soberania.value = Partida.soberania
	if lbl_dinero:
		lbl_dinero.text = "Dinero: $%d" % Partida.dinero
	if lbl_ciencia:
		lbl_ciencia.text = "Ciencia: Tier %d (x%.2f)" % [Partida.tier_ciencia, Partida.multiplicador_ganancia]
	if lbl_astilleros:
		lbl_astilleros.text = "Fletes Mar: %d / %d Astilleros" % [Partida.fletes_mar_activos, Partida.astilleros_nacionales]
	if lbl_magdalena:
		lbl_magdalena.text = "Canal Magdalena: %.0f%% (+%.0f%% Sob)" % [
			Partida.progreso_magdalena,
			(Partida.progreso_magdalena / 100.0) * Partida.soberania_total_magdalena
		]

	if btn_inv_ciencia:
		btn_inv_ciencia.text = "Invertir Ciencia ($%d)" % Partida.obtener_costo_ciencia()
	if btn_inv_magdalena:
		if Partida.tramos_magdalena_completados >= Partida.tramos_totales_magdalena:
			btn_inv_magdalena.text = "Canal Magdalena (100% Completo)"
			btn_inv_magdalena.disabled = true
		else:
			btn_inv_magdalena.text = "Dragar Magdalena +20%% ($%d -> +14%% Sob)" % Partida.costo_tramo_magdalena
			btn_inv_magdalena.disabled = false
	if btn_inv_astillero:
		btn_inv_astillero.text = "Construir Astillero ($%d)" % Partida.obtener_costo_astillero()


func _on_btn_inv_ciencia_pressed() -> void:
	Partida.invertir_ciencia()


func _on_btn_inv_magdalena_pressed() -> void:
	Partida.invertir_magdalena()


func _on_btn_inv_astillero_pressed() -> void:
	Partida.invertir_astillero()


func _on_btn_ruta_tierra_pressed() -> void:
	if gestor_rutas:
		gestor_rutas.iniciar_modo_conexion(Flete.TipoFlete.TIERRA)


func _on_btn_ruta_mar_pressed() -> void:
	if gestor_rutas:
		gestor_rutas.iniciar_modo_conexion(Flete.TipoFlete.MAR)


func _on_btn_cancelar_ruta_pressed() -> void:
	if gestor_rutas:
		gestor_rutas.cancelar_modo_conexion()


func _on_btn_evento_test_pressed() -> void:
	if gestor_eventos:
		gestor_eventos.disparar_evento_aleatorio()


func _on_btn_opcion_1_pressed() -> void:
	if gestor_eventos:
		gestor_eventos.elegir_opcion(0)


func _on_btn_opcion_2_pressed() -> void:
	if gestor_eventos:
		gestor_eventos.elegir_opcion(1)


func _on_btn_opcion_3_pressed() -> void:
	if gestor_eventos:
		gestor_eventos.elegir_opcion(2)


func _on_modo_conexion_cambiado(activo: bool, texto: String) -> void:
	if lbl_modo_ruta:
		lbl_modo_ruta.text = texto
	if btn_cancelar_ruta:
		btn_cancelar_ruta.visible = activo


func _on_mensaje_log(texto: String) -> void:
	if lbl_log:
		lbl_log.text = "Último aviso: " + texto


func _mostrar_evento(evento: EventoRecurso) -> void:
	if evento == null or panel_evento == null:
		return
	if lbl_titulo_evento:
		lbl_titulo_evento.text = "EVENTO: " + evento.titulo
	if lbl_desc_evento:
		lbl_desc_evento.text = evento.descripcion

	var botones: Array[Button] = [btn_opcion_1, btn_opcion_2, btn_opcion_3]
	for i in range(botones.size()):
		var btn: Button = botones[i]
		if btn == null:
			continue
		if i < evento.opciones.size():
			btn.visible = true
			btn.text = evento.opciones[i].texto_boton
		else:
			btn.visible = false

	panel_evento.visible = true


func _ocultar_evento() -> void:
	if panel_evento:
		panel_evento.visible = false


func _on_victoria() -> void:
	if lbl_modo_ruta:
		lbl_modo_ruta.modulate = Color(0.2, 1.0, 0.3)
		lbl_modo_ruta.text = "¡¡VICTORIA SOBERANA ALCANZADA (100%)!!"


func _on_derrota() -> void:
	if lbl_modo_ruta:
		lbl_modo_ruta.modulate = Color(1.0, 0.25, 0.25)
		lbl_modo_ruta.text = "DERROTA: SOBERANÍA EN 0%"
