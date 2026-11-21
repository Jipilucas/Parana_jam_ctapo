shader_type canvas_item;

// Shader 2D simple v2: lineas verticales que bajan y a su vez tienen ondulaciones propias.
// Compatible con GL Compatibility, Mobile y Forward+ (0 lecturas de textura, sin noise).

uniform vec4 water_color : source_color = vec4(0.24, 0.50, 0.82, 1.0);
uniform vec4 line_color : source_color = vec4(0.68, 0.86, 1.0, 1.0);

group_uniforms Lineas;
uniform float line_count : hint_range(1.0, 150.0, 1.0) = 30.0;
uniform float line_thickness : hint_range(0.01, 0.8, 0.01) = 0.16;
group_uniforms;

group_uniforms Onda_Principal;
// Curva grande que recorre todo el rio hacia abajo
uniform float flow_speed : hint_range(0.0, 15.0, 0.1) = 1.5;
uniform float wave_amplitude : hint_range(0.0, 3.0, 0.05) = 0.45;
uniform float wave_frequency : hint_range(1.0, 120.0, 1.0) = 45.0;
group_uniforms;

group_uniforms Ondulacion_de_Lineas;
// Segunda ondulacion mas chica sobre las propias lineas
uniform float sub_wave_amplitude : hint_range(0.0, 1.5, 0.02) = 0.18;
uniform float sub_wave_frequency : hint_range(1.0, 200.0, 1.0) = 110.0;
uniform float sub_wave_speed : hint_range(0.0, 20.0, 0.1) = 4.0;
// Desfase entre lineas vecinas (0 = todas iguales, >0 = cada linea ondula distinta)
uniform float line_phase_shift : hint_range(0.0, 40.0, 0.5) = 12.0;
// Variacion ondulada del grosor de cada linea (0 = grosor fijo)
uniform float thickness_wave : hint_range(0.0, 0.8, 0.05) = 0.25;
group_uniforms;

varying vec4 v_modulate;

void vertex() {
	v_modulate = COLOR;
}

void fragment() {
	// 1. Onda principal viajando hacia abajo (-TIME * flow_speed)
	float onda_principal = sin(UV.y * wave_frequency - TIME * flow_speed) * wave_amplitude;

	// 2. Sub-ondulacion sobre las lineas (frecuencia mas alta y desfase segun X)
	float fase_sub = UV.y * sub_wave_frequency - TIME * sub_wave_speed + UV.x * line_phase_shift;
	float onda_lineas = sin(fase_sub) * sub_wave_amplitude;

	// 3. Posicion horizontal combinando ambas ondas
	float pos_x = UV.x * line_count + onda_principal + onda_lineas;

	// 4. Grosor que tambien ondula suavemente a lo largo de la linea
	float factor_grosor = 1.0 + sin(fase_sub * 0.6) * thickness_wave;
	float mitad_grosor = (line_thickness * clamp(factor_grosor, 0.2, 1.8)) * 0.5;

	// 5. Dibujar cada linea centrada en 0.5 con bordes suaves
	float dist_centro = abs(fract(pos_x) - 0.5);
	float linea = smoothstep(mitad_grosor + 0.02, mitad_grosor, dist_centro);

	// 6. Mezclar color del agua con el color de la linea
	vec4 final_color = mix(water_color, line_color, linea);
	COLOR = vec4(final_color.rgb, final_color.a * v_modulate.a);
}
