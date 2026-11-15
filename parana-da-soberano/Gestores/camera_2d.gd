extends Camera2D

@export_group("Movimiento")
## Velocidad de desplazamiento en píxeles por segundo
@export var move_speed: float = 500.0
## Activar o desactivar movimiento por bordes con el mouse
@export var edge_pan_enabled: bool = true
## Distancia en píxeles desde el borde de la ventana donde empieza a moverse
@export var edge_margin: float = 25.0

@export_group("Límites opcionales")
@export var use_custom_limits: bool = false
@export var min_pos: Vector2 = Vector2(-1000, -1000)
@export var max_pos: Vector2 = Vector2(1000, 1000)

var _window_focused: bool = true


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
		
		if use_custom_limits:
			position.x = clampf(position.x, min_pos.x, max_pos.x)
			position.y = clampf(position.y, min_pos.y, max_pos.y)


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
