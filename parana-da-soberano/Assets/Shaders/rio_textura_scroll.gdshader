shader_type canvas_item;

// Shader 2D para textura con:
// - Scroll infinito hacia abajo
// - Desvanecimiento suave en bordes superior (top) e inferior (bottom)
// - Onda horizontal (derecha <-> izquierda) viajando hacia abajo
// - Repeticion automatica segun tamanio fijo en pixeles al estirar (Scale o Size)
// Compatible con GL Compatibility, Mobile y Forward+ (1 lectura de textura).

group_uniforms Repeticion;
// Tamanio en pixeles que ocupa cada repeticion de la textura al estirar el nodo.
// Si estiras el Sprite2D (Scale) o TextureRect (Size), la textura se repite en vez de deformarse.
uniform vec2 tile_size = vec2(256.0, 256.0);
// Activalo para repetir automaticamente sin configurar Repeat en el nodo.
// Desactivalo si usas mipmaps y ya tenes Texture -> Repeat = Enabled.
uniform bool wrap_uv = true;
group_uniforms;

group_uniforms Scroll_y_Bordes;
// Velocidad de bajada (en repeticiones por segundo)
uniform float scroll_speed : hint_range(-10.0, 10.0, 0.05) = 0.5;
// Porcentaje de desvanecimiento en el borde superior (0 = sin fade, 0.5 = mitad del alto)
uniform float fade_top : hint_range(0.0, 0.5, 0.01) = 0.15;
// Porcentaje de desvanecimiento en el borde inferior
uniform float fade_bottom : hint_range(0.0, 0.5, 0.01) = 0.15;
group_uniforms;

group_uniforms Onda_Horizontal;
// Cuanto se mueve la textura de derecha a izquierda (en fraccion del tile)
uniform float wave_amplitude : hint_range(0.0, 0.5, 0.005) = 0.08;
// Cantidad de ciclos de onda por cada repeticion vertical
uniform float wave_frequency : hint_range(0.0, 10.0, 0.1) = 1.0;
// Velocidad a la que baja la onda lateral
uniform float wave_speed : hint_range(-20.0, 20.0, 0.1) = 3.0;
group_uniforms;

varying vec2 v_scaled_pos;
varying vec4 v_modulate;

void vertex() {
	v_modulate = COLOR;
	// Escala real del nodo (funciona aunque este rotado o escalado no uniformemente)
	vec2 node_scale = vec2(length(MODEL_MATRIX[0].xy), length(MODEL_MATRIX[1].xy));
	v_scaled_pos = VERTEX * node_scale;
}

void fragment() {
	// 1. Convertir posicion en pixeles a UV repetibles segun tile_size
	vec2 uv_base = v_scaled_pos / max(tile_size, vec2(1.0));

	// 2. Onda que modula de derecha a izquierda mientras viaja hacia abajo
	float fase_onda = uv_base.y * wave_frequency * 6.2831853 - TIME * wave_speed;
	float onda_x = sin(fase_onda) * wave_amplitude;

	// 3. Aplicar onda lateral (X) y scroll infinito hacia abajo (-TIME * scroll_speed en Y)
	vec2 uv_final = vec2(
		uv_base.x + onda_x,
		uv_base.y - TIME * scroll_speed
	);

	if (wrap_uv) {
		uv_final = fract(uv_final);
	}

	// 4. Leer textura 2D
	vec4 tex = texture(TEXTURE, uv_final);

	// 5. Desvanecer en bordes top (UV.y = 0) y bottom (UV.y = 1)
	float alpha_top = fade_top > 0.0001 ? smoothstep(0.0, fade_top, UV.y) : 1.0;
	float alpha_bottom = fade_bottom > 0.0001 ? smoothstep(0.0, fade_bottom, 1.0 - UV.y) : 1.0;
	float fade = alpha_top * alpha_bottom;

	COLOR = vec4(tex.rgb, tex.a * fade) * v_modulate;
}
