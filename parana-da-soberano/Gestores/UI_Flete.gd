class_name UIFlete
extends Control

@export var entidad: Flete
@export var comandos: ControladorComandos

@export_group("Nodos UI (Opcionales, auto-asignados)")
@export var lbl_nombre: Label
@export var lbl_estado: Label
@export var lbl_carga: Label
@export var lbl_costos: Label
@export var btn_toggle_ruta: Button


func _ready() -> void:
	if entidad == null and get_parent() is Flete:
		entidad = get_parent() as Flete
	if comandos == null and entidad != null:
		comandos = entidad.controlador

	if lbl_nombre == null:
		lbl_nombre = get_node_or_null("PanelContainer/VBoxContainer/Nombre") as Label
	if lbl_estado == null:
		lbl_estado = get_node_or_null("PanelContainer/VBoxContainer/Estado") as Label
	if lbl_carga == null:
		lbl_carga = get_node_or_null("PanelContainer/VBoxContainer/Carga actual") as Label
	if lbl_costos == null:
		lbl_costos = get_node_or_null("PanelContainer/VBoxContainer/CostoViaje") as Label
	if btn_toggle_ruta == null:
		btn_toggle_ruta = get_node_or_null("PanelContainer/VBoxContainer/BtnToggleRuta") as Button


func _process(_delta: float) -> void:
	if entidad == null or lbl_nombre == null:
		return

	var etiqueta_tipo: String = "MAR" if entidad.tipo_flete == Flete.TipoFlete.MAR else "TIERRA"
	lbl_nombre.text = "[%s] %s" % [etiqueta_tipo, entidad.obtener_nombre_ruta()]
	lbl_estado.text = "Estado: %s" % (comandos.comando_actual if (comandos and entidad.ruta_habilitada) else "INACTIVA")
	lbl_carga.text = "Carga: %d / %d" % [entidad.Carga_Actual, entidad.Capacidad]

	if lbl_costos:
		lbl_costos.text = "Costo viaje: $%d" % entidad.costo_por_viaje

	if btn_toggle_ruta:
		if entidad.ruta_habilitada:
			btn_toggle_ruta.text = "Pausar Ruta"
		else:
			var req_astillero: String = " (1 Astillero)" if entidad.tipo_flete == Flete.TipoFlete.MAR else ""
			btn_toggle_ruta.text = "Habilitar ($%d)%s" % [entidad.costo_habilitar, req_astillero]


func _on_btn_toggle_pressed() -> void:
	if entidad == null:
		return
	if entidad.ruta_habilitada:
		entidad.desactivar_ruta()
	else:
		entidad.habilitar_ruta()
