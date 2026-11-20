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
@export var btn_eliminar_enemigo: Button


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
	if btn_eliminar_enemigo == null:
		btn_eliminar_enemigo = get_node_or_null("PanelContainer/VBoxContainer/BtnEliminarEnemigo") as Button


func _process(_delta: float) -> void:
	if entidad == null or lbl_nombre == null:
		return

	if entidad.es_marina_mercante():
		var etiqueta_faccion: String = "ENEMIGA" if entidad.es_enemigo() else "PROPIA"
		lbl_nombre.text = "[MAR - %s] %s" % [etiqueta_faccion, entidad.obtener_nombre_ruta()]
	else:
		lbl_nombre.text = "[TIERRA] %s" % entidad.obtener_nombre_ruta()

	lbl_estado.text = "Estado: %s" % (comandos.comando_actual if (comandos and entidad.ruta_habilitada) else "INACTIVA")

	if entidad.bien_transportado != ConfigLogistica.TipoBien.CUALQUIERA:
		lbl_carga.text = "Carga (%s): %d / %d" % [
			ConfigLogistica.nombre_bien(entidad.bien_transportado),
			entidad.Carga_Actual,
			entidad.Capacidad
		]
	else:
		lbl_carga.text = "Carga: %d / %d" % [entidad.Carga_Actual, entidad.Capacidad]

	if lbl_costos:
		var costo_actual: int = entidad.obtener_costo_viaje_actual()
		if entidad.es_marina_mercante():
			lbl_costos.text = "Viaje: $%d | Sob: %+.1f%%" % [
				costo_actual,
				entidad.obtener_impacto_soberania_actual()
			]
		else:
			lbl_costos.text = "Costo viaje: $%d" % costo_actual

	var es_enemiga: bool = entidad.es_enemigo()
	if btn_toggle_ruta:
		btn_toggle_ruta.visible = not es_enemiga
		if not es_enemiga:
			if entidad.ruta_habilitada:
				btn_toggle_ruta.text = "Pausar Ruta"
			else:
				var req_astillero: String = " (1 Astillero)" if entidad.tipo_flete == Flete.TipoFlete.MAR else ""
				btn_toggle_ruta.text = "Habilitar ($%d)%s" % [entidad.costo_habilitar, req_astillero]

	if btn_eliminar_enemigo:
		btn_eliminar_enemigo.visible = es_enemiga
		if es_enemiga:
			btn_eliminar_enemigo.text = "Eliminar ($%d)" % entidad.costo_eliminar


func _on_btn_toggle_pressed() -> void:
	if entidad == null:
		return
	if entidad.ruta_habilitada:
		entidad.desactivar_ruta()
	else:
		entidad.habilitar_ruta()


func _on_btn_eliminar_pressed() -> void:
	if entidad == null:
		return
	entidad.eliminar_flete_enemigo()
