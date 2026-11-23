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

@export_group("Pausa")
@export var btn_pausa: Button
@export var panel_pausa: Control
@export var lbl_pausa_info: Label

@export_group("Panel de Fin de Partida")
@export var panel_fin_partida: Control
@export var lbl_titulo_fin: Label
@export var lbl_desc_fin: Label
@export var btn_continuar_sandbox: Button
@export var btn_volver_menu: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Partida.estado_cambiado.connect(_actualizar_hud)
	Partida.mensaje_log.connect(_on_mensaje_log)
	Partida.victoria_alcanzada.connect(_on_victoria)
	Partida.derrota_alcanzada.connect(_on_derrota)
	Partida.pausa_cambiada.connect(_on_pausa_cambiada)

	if gestor_rutas:
		gestor_rutas.add_to_group("gestor_rutas")
		gestor_rutas.modo_conexion_cambiado.connect(_on_modo_conexion_cambiado)

	if gestor_eventos:
		gestor_eventos.evento_disparado.connect(_mostrar_evento)
		gestor_eventos.evento_resuelto.connect(_ocultar_evento)

	if lbl_log and Partida.modo_sandbox:
		lbl_log.text = "Modo Sandbox: Objetivo alcanzar %.0f%% de Soberanía Nacional." % Partida.objetivo_soberania

	if panel_fin_partida:
		panel_fin_partida.visible = false

	_actualizar_hud()
	_on_pausa_cambiada(Partida.esta_pausado())


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE:
			Partida.alternar_pausa_manual()
			get_viewport().set_input_as_handled()


func _actualizar_hud() -> void:
	if lbl_soberania:
		if Partida.modo_sandbox:
			lbl_soberania.text = "Soberanía: %.1f%% / %.0f%% [SANDBOX]" % [Partida.soberania, Partida.objetivo_soberania]
		else:
			lbl_soberania.text = "Soberanía: %.1f%%" % Partida.soberania
	if bar_soberania:
		bar_soberania.max_value = Partida.objetivo_soberania
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
		else:
			btn_inv_magdalena.text = "Dragar Magdalena +20%% ($%d -> +14%% Sob)" % Partida.costo_tramo_magdalena
	if btn_inv_astillero:
		btn_inv_astillero.text = "Construir Astillero ($%d)" % Partida.obtener_costo_astillero()

	_actualizar_estado_botones_accion()


func _actualizar_estado_botones_accion() -> void:
	var bloqueado: bool = Partida.esta_pausado() or Partida.juego_terminado
	if btn_inv_ciencia:
		btn_inv_ciencia.disabled = bloqueado
	if btn_inv_magdalena:
		var magdalena_completa: bool = Partida.tramos_magdalena_completados >= Partida.tramos_totales_magdalena
		btn_inv_magdalena.disabled = bloqueado or magdalena_completa
	if btn_inv_astillero:
		btn_inv_astillero.disabled = bloqueado
	if btn_ruta_tierra:
		btn_ruta_tierra.disabled = bloqueado
	if btn_ruta_mar:
		btn_ruta_mar.disabled = bloqueado
	if btn_cancelar_ruta:
		btn_cancelar_ruta.disabled = bloqueado
	if btn_evento_test:
		btn_evento_test.disabled = bloqueado


func _on_pausa_cambiada(pausado: bool) -> void:
	if pausado and gestor_rutas and gestor_rutas.modo_conectar_activo:
		gestor_rutas.cancelar_modo_conexion()

	if btn_pausa:
		if Partida.pausado_por_evento:
			btn_pausa.text = "PAUSADO (Evento)"
			btn_pausa.disabled = true
			btn_pausa.modulate = Color(1.0, 0.75, 0.3, 1.0)
		elif Partida.pausado_por_fin_partida or Partida.juego_terminado:
			btn_pausa.text = "FIN DE PARTIDA"
			btn_pausa.disabled = true
			btn_pausa.modulate = Color(0.8, 0.8, 0.8, 1.0)
		elif Partida.pausado_manual:
			btn_pausa.text = "REANUDAR [Espacio]"
			btn_pausa.disabled = false
			btn_pausa.modulate = Color(1.0, 0.85, 0.25, 1.0)
		else:
			btn_pausa.text = "PAUSAR [Espacio]"
			btn_pausa.disabled = false
			btn_pausa.modulate = Color(1.0, 1.0, 1.0, 1.0)

	if panel_pausa:
		panel_pausa.visible = (
			Partida.pausado_manual
			and not Partida.pausado_por_evento
			and not Partida.pausado_por_fin_partida
		)

	_actualizar_estado_botones_accion()


func _on_btn_pausa_pressed() -> void:
	Partida.alternar_pausa_manual()


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
	$PanelFinPartida/VBoxFin/Argentina.visible = true
	if lbl_modo_ruta:
		lbl_modo_ruta.modulate = Color(0.2, 1.0, 0.3)
		if Partida.modo_sandbox:
			lbl_modo_ruta.text = "¡¡VICTORIA SANDBOX ALCANZADA (1000%)!!"
		else:
			lbl_modo_ruta.text = "¡¡VICTORIA SOBERANA ALCANZADA (100%)!!"

	if panel_fin_partida:
		if lbl_titulo_fin:
			lbl_titulo_fin.modulate = Color(0.2, 1.0, 0.3)
			lbl_titulo_fin.text = (
				"¡VICTORIA SANDBOX (1000%)!"
				if Partida.modo_sandbox
				else "¡VICTORIA SOBERANA (100%)!"
			)
		if lbl_desc_fin:
			lbl_desc_fin.text = (
				"Alcanzaste el 1000% de Soberanía Nacional en el Modo Sandbox."
				if Partida.modo_sandbox
				else "Alcanzaste el 100% de Soberanía Nacional en el Paraná.\nPodés continuar esta partida en Modo Sandbox con meta en 1000%."
			)
		if btn_continuar_sandbox:
			btn_continuar_sandbox.visible = not Partida.modo_sandbox
		panel_fin_partida.visible = true


func _on_derrota() -> void:
	if lbl_modo_ruta:
		lbl_modo_ruta.modulate = Color(1.0, 0.25, 0.25)
		lbl_modo_ruta.text = "DERROTA: SOBERANÍA EN 0%"

	if panel_fin_partida:
		if lbl_titulo_fin:
			lbl_titulo_fin.modulate = Color(1.0, 0.25, 0.25)
			lbl_titulo_fin.text = "DERROTA"
		if lbl_desc_fin:
			lbl_desc_fin.text = "La Soberanía Nacional cayó al 0%."
		if btn_continuar_sandbox:
			btn_continuar_sandbox.visible = false
		panel_fin_partida.visible = true


func _on_btn_continuar_sandbox_pressed() -> void:
	$PanelFinPartida/VBoxFin/Argentina.visible = false
	if panel_fin_partida:
		panel_fin_partida.visible = false
	if lbl_modo_ruta:
		lbl_modo_ruta.text = ""
		lbl_modo_ruta.modulate = Color(1, 0.85, 0.2, 1)
	Partida.activar_modo_sandbox()


func _on_btn_volver_menu_pressed() -> void:
	$PanelFinPartida/VBoxFin/Argentina.visible = false
	Partida.reiniciar_partida(false)
	get_tree().change_scene_to_file("res://prefabs/pantallas/Pantalla_inicio.tscn")
