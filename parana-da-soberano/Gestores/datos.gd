class_name UIProductor
extends Control

@export var entidad: Productor
@export var comandos: ControladorComandos

@onready var _vbox: VBoxContainer = $VBoxContainer
@onready var _lbl_nombre: Label = $VBoxContainer/Nombre
@onready var _lbl_estado: Label = $VBoxContainer/Estado
@onready var _lbl_input: Label = $VBoxContainer/Stock_input
@onready var _lbl_output: Label = $VBoxContainer/Stock_output

var _btn_accion_slot: Button
var _btn_conectar: Button


func _ready() -> void:
	if entidad == null and get_parent() is Productor:
		entidad = get_parent() as Productor
	if comandos == null and entidad != null:
		comandos = entidad.controlador

	if _vbox:
		var panel_bg := StyleBoxFlat.new()
		panel_bg.bg_color = Color(0.08, 0.1, 0.14, 0.85)
		panel_bg.corner_radius_top_left = 6
		panel_bg.corner_radius_top_right = 6
		panel_bg.corner_radius_bottom_left = 6
		panel_bg.corner_radius_bottom_right = 6
		panel_bg.content_margin_left = 8
		panel_bg.content_margin_right = 8
		panel_bg.content_margin_top = 6
		panel_bg.content_margin_bottom = 6

		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", panel_bg)
		remove_child(_vbox)
		panel.add_child(_vbox)
		add_child(panel)

		_btn_accion_slot = Button.new()
		_btn_accion_slot.pressed.connect(_on_btn_accion_pressed)
		_vbox.add_child(_btn_accion_slot)

		_btn_conectar = Button.new()
		_btn_conectar.text = "Seleccionar p/ Ruta"
		_btn_conectar.pressed.connect(_on_btn_conectar_pressed)
		_vbox.add_child(_btn_conectar)


func _process(_delta: float) -> void:
	if entidad == null or entidad.config == null or _lbl_nombre == null:
		return

	var cfg: ConfigLogistica = entidad.config
	var etiqueta_faccion: String = ConfigLogistica.nombre_faccion(entidad.faccion_actual)

	if not entidad.slot_ocupado:
		_lbl_nombre.text = "[SLOT VACÍO] %s" % entidad.obtener_nombre()
		_lbl_estado.text = "Sin construir"
		_lbl_input.text = "Entrada (%s): -" % ConfigLogistica.nombre_bien(cfg.bien_entrada)
		_lbl_output.text = "Salida (%s): -" % ConfigLogistica.nombre_bien(cfg.bien_salida)
		if _btn_accion_slot:
			_btn_accion_slot.visible = true
			_btn_accion_slot.text = "Construir ($%d)" % entidad.costo_construir_en_slot
		return

	_lbl_nombre.text = "%s [%s]" % [entidad.obtener_nombre(), etiqueta_faccion]
	_lbl_estado.text = "Ciclo: %s" % (comandos.comando_actual if comandos else "activo")

	if cfg.bien_entrada != ConfigLogistica.TipoBien.NINGUNO:
		_lbl_input.text = "In (%s): %d (cons: %d)" % [
			ConfigLogistica.nombre_bien(cfg.bien_entrada),
			entidad.stock_entrada,
			cfg.cantidad_consumo
		]
	else:
		_lbl_input.text = "In: No requiere"

	if cfg.bien_salida != ConfigLogistica.TipoBien.NINGUNO:
		_lbl_output.text = "Out (%s): %d (+%d)" % [
			ConfigLogistica.nombre_bien(cfg.bien_salida),
			entidad.stock_salida,
			cfg.cantidad_produccion + entidad.bonus_produccion
		]
	else:
		_lbl_output.text = "Meta: Consume -> +%.1f%% Sob / +$%d" % [
			cfg.impacto_soberania_propio,
			cfg.ganancia_propio
		]

	if _btn_accion_slot:
		if entidad.faccion_actual == ConfigLogistica.Faccion.ENEMIGO:
			_btn_accion_slot.visible = true
			_btn_accion_slot.text = "Nacionalizar ($%d | Ciencia %d)" % [cfg.costo_compra, cfg.tier_ciencia_requerido]
		else:
			_btn_accion_slot.visible = false


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
