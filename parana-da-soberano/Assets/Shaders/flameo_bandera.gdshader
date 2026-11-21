shader_type canvas_item;

// Shader 2D de flameo de textura tipo bandera (para Sprite2D o TextureRect).
// Compatible con GL Compatibility, Mobile y Forward+ (1 lectura de textura).

group_uniforms Flameo;
// Velocidad del viento / flameo
uniform float wave_speed : hint_range(0.0, 20.0, 0.1) = 5.0;
// Cantidad de pliegues a lo ancho de la textura
uniform float wave_frequency : hint_range(1.0, 40.0, 0.5) = 10.0;
// Altura del flameo (en proporcion de la textura)
uniform float wave_amplitude : hint_range(0.0, 0.25, 0.005) = 0.05;
// Inclinacion diagonal de los pliegues (0 = pliegues rectos verticales)
uniform float diagonal_tilt : hint_range(-10.0, 10.0, 0.2) = 1.5;
group_uniforms;

group_uniforms Mastil_y_Bordes;
// 1.0 = borde izquierdo fijo al mastil y flamea mas hacia la derecha.
// 0.0 = toda la textura flamea por igual de punta a punta.
uniform float pin_left : hint_range(0.0, 1.0, 0.05) = 1.0;
// Margen transparente interno para que la bandera no se recorte arriba/abajo al flamear.
// Pone 0.0 si la textura es un fondo repetible (Texture -> Repeat = Enabled).
uniform float edge_padding : hint_range(0.0, 0.3, 0.01) = 0.08;
group_uniforms;

group_uniforms Sombreado;
// Luz y sombra en los pliegues de la tela (0 = sin sombreado, color plano)
uniform float shadow_strength : hint_range(0.0, 0.6, 0.02) = 0.22;
group_uniforms;

varying vec4 v_modulate;

void vertex() {
	v_modulate = COLOR;
}

void fragment() {
	// 1. Aplicar margen interno para dar espacio al flameo sin cortar los bordes
	vec2 uv = (UV - 0.5) * (1.0 + edge_padding * 2.0) + 0.5;

	// 2. Anclaje al mastil izquierdo (0 en el borde izquierdo, 1 en el extremo derecho)
	float factor_mastil = mix(1.0, clamp(uv.x, 0.0, 1.0), pin_left);

	// 3. Onda de flameo viajando de izquierda a derecha (-TIME * wave_speed)
	float fase = uv.x * wave_frequency - TIME * wave_speed + uv.y * diagonal_tilt;
	float onda = sin(fase) * wave_amplitude * factor_mastil;

	// 4. Desplazar UV verticalmente con la onda
	vec2 uv_flameo = vec2(uv.x, uv.y + onda);

	// 5. Si edge_padding > 0, hacer transparente lo que queda fuera de [0, 1] para evitar bordes estirados
	if (edge_padding > 0.001 && (uv_flameo.x < 0.0 || uv_flameo.x > 1.0 || uv_flameo.y < 0.0 || uv_flameo.y > 1.0)) {
		COLOR = vec4(0.0);
	} else {
		vec4 tex = texture(TEXTURE, uv_flameo);
		// Sombreado sutil de los pliegues (luces en crestas, sombra en valles)
		float luz_pliegue = 1.0 + cos(fase) * shadow_strength * factor_mastil;
		COLOR = vec4(tex.rgb * luz_pliegue, tex.a) * v_modulate;
	}
}
