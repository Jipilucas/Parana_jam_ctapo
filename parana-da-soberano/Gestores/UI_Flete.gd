class_name UIFlete
extends Control

@export var entidad: Flete
@export var comandos: ControladorComandos

@onready var _vbox: VBoxContainer = $VBoxContainer
@onready var _lbl_nombre: Label = $VBoxContainer/Nombre
@onready var _lbl_estado: Label = $VBoxContainer/Estado
@onready var _lbl_carga: Label = $"VBoxContainer/Carga actual"

var _lbl_costos: Label
var _btn_toggle_ruta: Button


func _ready() -> void:
	if entidad == null and get_parent() is Flete:
		entidad = get_parent() as Flete
	if comandos == null and entidad != null:
		comandos = entidad.controlador

	if _vbox:
		var panel_bg := StyleBoxFlat.new()
		panel_bg.bg_color = Color(0.12, 0.12, 0.16, 0.85)
		panel_bg.corner_radius_top_left = 5
		panel_bg.corner_radius_top_right = 5
		panel_bg.corner_radius_bottom_left = 5
		panel_bg.corner_radius_bottom_right = 5
		panel_bg.content_margin_left = 6
		panel_bg.content_margin_right = 6
		panel_bg.content_margin_top = 4
		panel_bg.content_margin_bottom = 4

		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", panel_bg)
		remove_child(_vbox)
		panel.add_child(_vbox)
		add_child(panel)

		_lbl_costos = Label.new()
		_vbox.add_child(_lbl_costos)

		_btn_toggle_ruta = Button.new()
		_btn_toggle_ruta.pressed.connect(_on_btn_toggle_pressed)
		_vbox.add_child(_btn_toggle_ruta)


func _process(_delta: float) -> void:
	if entidad == null or _lbl_nombre == null:
		return

	var etiqueta_tipo: String = "MAR" if entidad.tipo_flete == Flete.TipoFlete.MAR else "TIERRA"
	_lbl_nombre.text = "[%s] %s" % [etiqueta_tipo, entidad.obtener_nombre_ruta()]
	_lbl_estado.text = "Estado: %s" % (comandos.comando_actual if (comandos and entidad.ruta_habilitada) else "INACTIVA")
	_lbl_carga.text = "Carga: %d / %d" % [entidad.Carga_Actual, entidad.Capacidad]

	if _lbl_costos:
		_lbl_costos.text = "Costo viaje: $%d" % entidad.costo_por_viaje

	if _btn_toggle_ruta:
		if entidad.ruta_habilitada:
			_btn_toggle_ruta.text = "Pausar Ruta"
		else:
			var req_astillero: String = " (1 Astillero)" if entidad.tipo_flete == Flete.TipoFlete.MAR else ""
			_btn_toggle_ruta.text = "Habilitar ($%d)%s" % [entidad.costo_habilitar, req_astillero]


func _on_btn_toggle_pressed() -> void:
	if entidad == null:
		return
	if entidad.ruta_habilitada:
		entidad.desactivar_ruta()
	else:
		entidad.habilitar_ruta()
