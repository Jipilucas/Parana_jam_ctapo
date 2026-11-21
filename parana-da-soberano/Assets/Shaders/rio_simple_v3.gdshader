shader_type canvas_item;

// Shader 2D simple v3: lineas verticales onduladas + modulaciones sobre el render final.
// Compatible con GL Compatibility, Mobile y Forward+ (0 lecturas de textura, sin noise).

uniform vec4 water_color : source_color = vec4(0.24, 0.50, 0.82, 1.0);
uniform vec4 line_color : source_color = vec4(0.68, 0.86, 1.0, 1.0);

group_uniforms Lineas_y_Flujo;
uniform float line_count : hint_range(1.0, 150.0, 1.0) = 30.0;
uniform float line_thickness : hint_range(0.01, 0.8, 0.01) = 0.16;
uniform float flow_speed : hint_range(0.0, 15.0, 0.1) = 1.5;
uniform float wave_amplitude : hint_range(0.0, 3.0, 0.05) = 0.45;
uniform float wave_frequency : hint_range(1.0, 120.0, 1.0) = 45.0;
uniform float sub_wave_amplitude : hint_range(0.0, 1.5, 0.02) = 0.15;
uniform float sub_wave_frequency : hint_range(1.0, 200.0, 1.0) = 100.0;
uniform float sub_wave_speed : hint_range(0.0, 20.0, 0.1) = 3.5;
uniform float line_phase_shift : hint_range(0.0, 40.0, 0.5) = 10.0;
group_uniforms;

group_uniforms Modulacion_Render_Final;
// Ondas de luz, tinte y pulso que modulan toda la imagen final
uniform float mod_frequency : hint_range(1.0, 80.0, 1.0) = 24.0;
uniform float mod_speed : hint_range(0.0, 15.0, 0.1) = 2.2;
uniform float brightness_mod : hint_range(0.0, 0.5, 0.02) = 0.16;
uniform vec4 mod_tint : source_color = vec4(0.55, 0.90, 1.0, 1.0);
uniform float tint_strength : hint_range(0.0, 1.0, 0.05) = 0.25;
// Pulso global suave sobre todo el rio (0 = desactivado)
uniform float pulse_speed : hint_range(0.0, 10.0, 0.1) = 1.2;
uniform float pulse_strength : hint_range(0.0, 0.3, 0.01) = 0.06;
group_uniforms;

varying vec4 v_modulate;

void vertex() {
	v_modulate = COLOR;
}

void fragment() {
	// 1. Onda principal + sub-ondulacion de lineas viajando hacia abajo
	float onda_principal = sin(UV.y * wave_frequency - TIME * flow_speed) * wave_amplitude;
	float onda_lineas = sin(UV.y * sub_wave_frequency - TIME * sub_wave_speed + UV.x * line_phase_shift) * sub_wave_amplitude;
	float pos_x = UV.x * line_count + onda_principal + onda_lineas;

	// 2. Dibujar lineas verticales centradas en 0.5
	float dist_centro = abs(fract(pos_x) - 0.5);
	float mitad_grosor = line_thickness * 0.5;
	float linea = smoothstep(mitad_grosor + 0.02, mitad_grosor, dist_centro);

	// 3. Render base del rio
	vec4 base_color = mix(water_color, line_color, linea);

	// 4. Modulaciones sobre el render final (ondas cruzadas bajando + pulso global)
	float mod_a = sin(UV.y * mod_frequency + UV.x * (mod_frequency * 0.5) - TIME * mod_speed);
	float mod_b = cos(UV.y * (mod_frequency * 0.65) - UV.x * (mod_frequency * 0.8) - TIME * (mod_speed * 0.75));
	float modulacion = (mod_a + mod_b) * 0.5; // Rango [-1.0, 1.0]
	float pulso = sin(TIME * pulse_speed) * pulse_strength;

	// Aplicar modulacion de brillo y tinte sobre el color final
	vec3 final_rgb = base_color.rgb * (1.0 + modulacion * brightness_mod + pulso);
	float mascara_tinte = smoothstep(-0.2, 0.8, modulacion) * tint_strength;
	final_rgb = mix(final_rgb, final_rgb * mod_tint.rgb + mod_tint.rgb * 0.15, mascara_tinte);

	COLOR = vec4(final_rgb, base_color.a * v_modulate.a);
}
