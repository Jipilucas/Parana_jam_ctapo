class_name UIProductor
extends Control

@export var entidad: Productor
@export var comandos: ControladorComandos

@export_group("Nodos UI (Opcionales, auto-asignados)")
@export var lbl_nombre: Label
@export var lbl_estado: Label
@export var lbl_input: Label
@export var lbl_output: Label
@export var btn_accion_slot: Button
@export var btn_conectar: Button


func _ready() -> void:
	if entidad == null and get_parent() is Productor:
		entidad = get_parent() as Productor
	if comandos == null and entidad != null:
		comandos = entidad.controlador

	if lbl_nombre == null:
		lbl_nombre = get_node_or_null("PanelContainer/VBoxContainer/Nombre") as Label
	if lbl_estado == null:
		lbl_estado = get_node_or_null("PanelContainer/VBoxContainer/Estado") as Label
	if lbl_input == null:
		lbl_input = get_node_or_null("PanelContainer/VBoxContainer/Stock_input") as Label
	if lbl_output == null:
		lbl_output = get_node_or_null("PanelContainer/VBoxContainer/Stock_output") as Label
	if btn_accion_slot == null:
		btn_accion_slot = get_node_or_null("PanelContainer/VBoxContainer/BtnAccionSlot") as Button
	if btn_conectar == null:
		btn_conectar = get_node_or_null("PanelContainer/VBoxContainer/BtnConectar") as Button


func _process(_delta: float) -> void:
	if entidad == null or entidad.config == null or lbl_nombre == null:
		return

	var cfg: ConfigLogistica = entidad.config
	var etiqueta_faccion: String = ConfigLogistica.nombre_faccion(entidad.faccion_actual)

	if not entidad.slot_ocupado:
		lbl_nombre.text = "[SLOT VACÍO] %s" % entidad.obtener_nombre()
		lbl_estado.text = "Sin construir"
		lbl_input.text = "Entrada (%s): -" % ConfigLogistica.nombre_bien(cfg.bien_entrada)
		lbl_output.text = "Salida (%s): -" % ConfigLogistica.nombre_bien(cfg.bien_salida)
		if btn_accion_slot:
			btn_accion_slot.visible = true
			btn_accion_slot.text = "Construir ($%d)" % entidad.costo_construir_en_slot
		return

	lbl_nombre.text = "%s [%s]" % [entidad.obtener_nombre(), etiqueta_faccion]
	lbl_estado.text = "Ciclo: %s" % (comandos.comando_actual if comandos else "activo")

	if entidad.es_puerto():
		var mp_in: int = entidad.contar_por_tipo(entidad.cola_entrada, ConfigLogistica.TipoBien.MATERIA_PRIMA)
		var man_in: int = entidad.contar_por_tipo(entidad.cola_entrada, ConfigLogistica.TipoBien.MANUFACTURA)
		var mp_out: int = entidad.contar_por_tipo(entidad.cola_salida, ConfigLogistica.TipoBien.MATERIA_PRIMA)
		var man_out: int = entidad.contar_por_tipo(entidad.cola_salida, ConfigLogistica.TipoBien.MANUFACTURA)
		if cfg.cantidad_consumo > 0:
			lbl_input.text = "In: %d (MP:%d | Man:%d) [cons:%d]" % [
				entidad.stock_entrada,
				mp_in,
				man_in,
				cfg.cantidad_consumo
			]
			if entidad.stock_salida > 0:
				var sig: String = ConfigLogistica.nombre_bien(entidad.obtener_siguiente_bien_salida())
				lbl_output.text = "Out: %d (MP:%d | Man:%d) [Sig:%s]" % [
					entidad.stock_salida,
					mp_out,
					man_out,
					sig
				]
			else:
				lbl_output.text = "Out: 0 (MP:0 | Man:0)"
		else:
			lbl_input.text = "Recibido: %d (MP:%d | Man:%d)" % [entidad.stock_entrada, mp_in, man_in]
			lbl_output.text = "Destino Exportación"
	else:
		if cfg.tipo_entidad != ConfigLogistica.TipoEntidad.MATERIA_PRIMA:
			lbl_input.text = "In (%s): %d (cons: %d)" % [
				ConfigLogistica.nombre_bien(cfg.bien_entrada),
				entidad.stock_entrada,
				cfg.cantidad_consumo
			]
		else:
			lbl_input.text = "In: No requiere"

		if cfg.tipo_entidad != ConfigLogistica.TipoEntidad.CIUDAD:
			lbl_output.text = "Out (%s): %d (+%d)" % [
				ConfigLogistica.nombre_bien(cfg.bien_salida),
				entidad.stock_salida,
				cfg.cantidad_produccion + entidad.bonus_produccion
			]
		else:
			lbl_output.text = "Meta: Consume -> +%.1f%% Sob / +$%d" % [
				cfg.impacto_soberania_propio,
				cfg.ganancia_propio
			]

	if btn_accion_slot:
		if entidad.faccion_actual == ConfigLogistica.Faccion.ENEMIGO:
			btn_accion_slot.visible = true
			btn_accion_slot.text = "Nacionalizar ($%d | Ciencia %d)" % [cfg.costo_compra, cfg.tier_ciencia_requerido]
		else:
			btn_accion_slot.visible = false


func _on_btn_accion_pressed() -> void:
	if entidad == null:
		return
	if not entidad.slot_ocupado:
		entidad.construir_en_slot()
	elif entidad.faccion_actual == ConfigLogistica.Faccion.ENEMIGO:
		entidad.nacionalizar()


func _on_btn_conectar_pressed() -> void:
	if entidad == null:
		return
	var gestor := get_tree().get_first_node_in_group("gestor_rutas") as GestorRutas
	if gestor:
		gestor.registrar_clic_en_productor(entidad)
