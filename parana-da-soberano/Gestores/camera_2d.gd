extends Camera2D

@export_group("Movimiento")
## Velocidad de desplazamiento en píxeles por segundo
@export var move_speed: float = 500.0
## Activar o desactivar movimiento por bordes con el mouse
@export var edge_pan_enabled: bool = true
## Distancia en píxeles desde el borde de la ventana donde empieza a moverse
@export var edge_margin: float = 25.0

@export_group("Límites del Mapa")
## Nodo contenedor del mapa (ej. Mapa) o un Control/Sprite2D que define los bordes visibles
@export var bounds_node: Node
## Si está activo, ajusta automáticamente el zoom mínimo para que nunca se vea fuera del mapa
@export var auto_limit_min_zoom: bool = true
@export var use_custom_limits: bool = false
@export var min_pos: Vector2 = Vector2(-1000, -1000)
@export var max_pos: Vector2 = Vector2(1000, 1000)

var _window_focused: bool = true
var _zoom_tween: Tween
var _bounds_rect: Rect2 = Rect2()
var _has_bounds: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_zoom_level = clampf(absf(zoom.x) if zoom.x != 0.0 else 1.0, min_zoom, max_zoom)
	zoom = Vector2(_zoom_level, _zoom_level)
	if get_viewport() != null:
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	actualizar_limites_mapa()
	actualizar_limites_mapa.call_deferred()


func _notification(what: int) -> void:
	# Evita que la cámara se siga moviendo sola si hacés Alt+Tab o sacás el mouse de la ventana
	if what == NOTIFICATION_WM_MOUSE_EXIT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_window_focused = false
	elif what == NOTIFICATION_WM_MOUSE_ENTER or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_window_focused = true


func _process(delta: float) -> void:
	var direction := _get_keyboard_input()

	# Si no se está tocando el teclado y la ventana tiene el foco, chequeamos los bordes con el mouse
	if direction == Vector2.ZERO and edge_pan_enabled and _window_focused:
		direction = _get_edge_pan_input()

	if direction != Vector2.ZERO:
		# Dividimos por el zoom para que al alejar/acercar la cámara la velocidad se sienta consistente
		position += direction.normalized() * (move_speed / zoom.x) * delta

	# Se aplica siempre para que también re-encuadre suavemente mientras el tween del zoom cambia zoom.x/y
	_clamp_to_bounds()


func actualizar_limites_mapa() -> void:
	_has_bounds = false
	if bounds_node != null:
		var acc := {"valid": false, "rect": Rect2()}
		_collect_node_bounds(bounds_node, acc)
		if acc["valid"]:
			_bounds_rect = acc["rect"]
			_has_bounds = true
	elif use_custom_limits:
		var top_left := Vector2(minf(min_pos.x, max_pos.x), minf(min_pos.y, max_pos.y))
		var bottom_right := Vector2(maxf(min_pos.x, max_pos.x), maxf(min_pos.y, max_pos.y))
		_bounds_rect = Rect2(top_left, bottom_right - top_left)
		_has_bounds = _bounds_rect.size.x > 0.0 and _bounds_rect.size.y > 0.0

	if _has_bounds:
		limit_left = int(ceilf(_bounds_rect.position.x))
		limit_top = int(ceilf(_bounds_rect.position.y))
		limit_right = int(floorf(_bounds_rect.end.x))
		limit_bottom = int(floorf(_bounds_rect.end.y))
		_aplicar_zoom_minimo_efectivo()
		_clamp_to_bounds()


func _collect_node_bounds(node: Node, acc: Dictionary) -> void:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return

	if node is Control:
		var ctrl := node as Control
		if ctrl.size.x > 0.0 and ctrl.size.y > 0.0:
			var r := _get_transformed_rect(ctrl.get_global_transform(), Rect2(Vector2.ZERO, ctrl.size))
			_merge_rect(acc, r)
	elif node is Sprite2D:
		var spr := node as Sprite2D
		if spr.texture != null:
			var r := _get_transformed_rect(spr.global_transform, spr.get_rect())
			_merge_rect(acc, r)

	for child in node.get_children():
		_collect_node_bounds(child, acc)


func _get_transformed_rect(xform: Transform2D, local_rect: Rect2) -> Rect2:
	var p0: Vector2 = xform * local_rect.position
	var p1: Vector2 = xform * Vector2(local_rect.end.x, local_rect.position.y)
	var p2: Vector2 = xform * local_rect.end
	var p3: Vector2 = xform * Vector2(local_rect.position.x, local_rect.end.y)
	var rect := Rect2(p0, Vector2.ZERO)
	rect = rect.expand(p1)
	rect = rect.expand(p2)
	rect = rect.expand(p3)
	return rect


func _merge_rect(acc: Dictionary, rect: Rect2) -> void:
	if not acc["valid"]:
		acc["rect"] = rect
		acc["valid"] = true
	else:
		acc["rect"] = (acc["rect"] as Rect2).merge(rect)


func _get_effective_min_zoom() -> float:
	var effective_min: float = min_zoom
	if auto_limit_min_zoom and _has_bounds and _bounds_rect.size.x > 0.0 and _bounds_rect.size.y > 0.0:
		var vp_size: Vector2 = get_viewport_rect().size
		if vp_size.x > 0.0 and vp_size.y > 0.0:
			var min_zoom_x: float = vp_size.x / _bounds_rect.size.x
			var min_zoom_y: float = vp_size.y / _bounds_rect.size.y
			effective_min = maxf(effective_min, maxf(min_zoom_x, min_zoom_y))
	return minf(effective_min, max_zoom)


func _aplicar_zoom_minimo_efectivo() -> void:
	var effective_min: float = _get_effective_min_zoom()
	if _zoom_level < effective_min:
		_zoom_level = effective_min
	if zoom.x < effective_min or zoom.y < effective_min:
		if _zoom_tween != null and _zoom_tween.is_running():
			_zoom_tween.kill()
		zoom = Vector2(_zoom_level, _zoom_level)


func _on_viewport_size_changed() -> void:
	if not _has_bounds:
		return
	_aplicar_zoom_minimo_efectivo()
	_clamp_to_bounds()


func _clamp_to_bounds() -> void:
	if not _has_bounds or zoom.x <= 0.0 or zoom.y <= 0.0:
		return

	var vp_size: Vector2 = get_viewport_rect().size
	var view_size: Vector2 = Vector2(vp_size.x / zoom.x, vp_size.y / zoom.y)
	var pos: Vector2 = global_position

	if anchor_mode == ANCHOR_MODE_DRAG_CENTER:
		var half_view: Vector2 = view_size * 0.5
		var min_x: float = _bounds_rect.position.x + half_view.x
		var max_x: float = _bounds_rect.end.x - half_view.x
		var min_y: float = _bounds_rect.position.y + half_view.y
		var max_y: float = _bounds_rect.end.y - half_view.y

		if min_x <= max_x:
			pos.x = clampf(pos.x, min_x, max_x)
		else:
			pos.x = (_bounds_rect.position.x + _bounds_rect.end.x) * 0.5

		if min_y <= max_y:
			pos.y = clampf(pos.y, min_y, max_y)
		else:
			pos.y = (_bounds_rect.position.y + _bounds_rect.end.y) * 0.5
	else:
		var min_x: float = _bounds_rect.position.x
		var max_x: float = _bounds_rect.end.x - view_size.x
		var min_y: float = _bounds_rect.position.y
		var max_y: float = _bounds_rect.end.y - view_size.y

		pos.x = clampf(pos.x, min_x, maxf(min_x, max_x))
		pos.y = clampf(pos.y, min_y, maxf(min_y, max_y))

	global_position = pos



func _get_keyboard_input() -> Vector2:
	# Podés reemplazar ui_left/right/up/down por tus propios actions (ej: "move_left", "move_right", etc.)
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")


func _get_edge_pan_input() -> Vector2:
	var dir := Vector2.ZERO
	var viewport := get_viewport()
	var mouse_pos := viewport.get_mouse_position()
	var screen_size := viewport.get_visible_rect().size
	
	# Borde izquierdo y derecho
	if mouse_pos.x <= edge_margin:
		dir.x -= 1.0
	elif mouse_pos.x >= screen_size.x - edge_margin:
		dir.x += 1.0
		
	# Borde superior e inferior
	if mouse_pos.y <= edge_margin:
		dir.y -= 1.0
	elif mouse_pos.y >= screen_size.y - edge_margin:
		dir.y += 1.0
		
	return dir

@export_group("zoom")
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var zoom_factor: float = 0.1
@export var zoom_duration: float = 0.2
var _zoom_level: float = 1.0
func _set_zoom_level(value: float) -> void:
	_zoom_level = clampf(value, _get_effective_min_zoom(), max_zoom)
	if _zoom_tween != null and _zoom_tween.is_running():
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	_zoom_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_zoom_tween.tween_property(self, "zoom", Vector2(_zoom_level, _zoom_level), zoom_duration)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		_set_zoom_level(_zoom_level + zoom_factor)
	elif event.is_action_pressed("zoom_out"):
		_set_zoom_level(_zoom_level - zoom_factor)
