shader_type canvas_item;

// Shader 2D de rio fluyendo hacia abajo.
// Compatible con todos los renderers de Godot 4: GL Compatibility, Mobile y Forward+.
// Costo: 3 lecturas de textura por fragmento (4 si base_texture_mix > 0.0), sin SCREEN_TEXTURE.

group_uniforms Colores;
uniform vec4 deep_color : source_color = vec4(0.2, 0.2, 0.0, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.32, 0.60, 0.88, 1.0);
uniform vec4 foam_color : source_color = vec4(0.82, 0.93, 1.0, 1.0);
group_uniforms;

group_uniforms Flujo;
// Textura de ruido seamless (NoiseTexture2D con FastNoiseLite y seamless = true).
uniform sampler2D noise_texture : repeat_enable, filter_linear;
// Velocidad del caudal del rio.
uniform float flow_speed : hint_range(0.0, 2.0, 0.01) = 0.07;
// Direccion del flujo en coordenadas UV (0, 1 = hacia abajo).
uniform vec2 flow_direction = vec2(0.0, 1.0);
// Escala de repeticion del agua (ajusta X/Y segun la proporcion del mapa o sprite).
uniform vec2 uv_scale = vec2(7.0, 8.0);
// Intensidad de la ondulacion organica de la corriente.
uniform float distortion_strength : hint_range(0.0, 0.25, 0.005) = 0.04;
// Escala y velocidad relativa de la segunda capa para efecto de profundidad.
uniform float secondary_layer_scale : hint_range(0.5, 3.0, 0.05) = 1.45;
uniform float secondary_speed_ratio : hint_range(0.2, 2.5, 0.05) = 1.35;
group_uniforms;

group_uniforms Espuma_y_Brillos;
// Umbral donde aparecen las estelas y espuma de la corriente.
uniform float foam_threshold : hint_range(0.05, 0.9, 0.01) = 0.36;
// Suavidad de los bordes de la espuma (valores bajos = estilo mas cartoon/ilustrado).
uniform float foam_softness : hint_range(0.01, 0.3, 0.01) = 0.07;
// Opacidad de las estelas de espuma.
uniform float foam_opacity : hint_range(0.0, 1.0, 0.05) = 0.55;
group_uniforms;

group_uniforms Textura_Base;
// 0.0 = usa solo los colores del shader (ideal para ColorRect).
// > 0.0 = mezcla con la textura 2D del TextureRect/Sprite2D fluyendo hacia abajo.
uniform float base_texture_mix : hint_range(0.0, 1.0, 0.05) = 0.0;
group_uniforms;

void fragment() {
	// En Godot 2D (canvas_item), UV.y = 0 es arriba y UV.y = 1 es abajo.
	// Restar dir * TIME desplaza la textura en la direccion de `dir` (+Y = hacia abajo).
	vec2 dir = length(flow_direction) > 0.001 ? normalize(flow_direction) : vec2(0.0, 1.0);
	vec2 scaled_uv = UV * uv_scale;

	// Muestra 1: ruido de baja frecuencia para ondular la corriente.
	vec2 distort_uv = scaled_uv * 0.55 - dir * (TIME * flow_speed * 0.45);
	float distort_sample = texture(noise_texture, distort_uv).r;
	vec2 distort_offset = vec2(distort_sample - 0.5, (distort_sample - 0.5) * 0.5) * distortion_strength * 2.0;

	// Muestra 2: capa principal de corriente fluyendo hacia abajo.
	vec2 uv_layer_a = scaled_uv + distort_offset - dir * (TIME * flow_speed);
	float wave_a = texture(noise_texture, uv_layer_a).r;

	// Muestra 3: capa secundaria mas rapida con leve deriva lateral para romper repeticion.
	vec2 lateral_drift = vec2(-dir.y, dir.x) * (TIME * flow_speed * 0.12);
	vec2 uv_layer_b = scaled_uv * secondary_layer_scale
		- distort_offset * 0.7
		- dir * (TIME * flow_speed * secondary_speed_ratio)
		+ lateral_drift
		+ vec2(0.37, 0.19);
	float wave_b = texture(noise_texture, uv_layer_b).r;

	// Transicion entre agua profunda y agua clara.
	float water_height = mix(wave_a, wave_b, 0.45);
	float tone_blend = smoothstep(0.32, 0.68, water_height);
	vec3 water_rgb = mix(deep_color.rgb, shallow_color.rgb, tone_blend);

	// Soporte opcional para desplazar tambien una textura 2D propia (TextureRect / Sprite2D).
	float final_alpha = COLOR.a;
	if (base_texture_mix > 0.001) {
		vec4 tex_color = texture(TEXTURE, uv_layer_a);
		water_rgb = mix(water_rgb, tex_color.rgb, base_texture_mix);
		final_alpha *= mix(1.0, tex_color.a, base_texture_mix);
	}

	// Estelas/espuma donde coinciden crestas de ambas capas (se forman y disuelven al bajar).
	float foam_signal = wave_a * wave_b;
	float foam_mask = smoothstep(foam_threshold, foam_threshold + foam_softness, foam_signal);
	water_rgb = mix(water_rgb, foam_color.rgb, foam_mask * foam_opacity);

	COLOR = vec4(water_rgb, final_alpha);
}
