shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.5;
uniform float edge_saturation : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D screen_vec : hint_screen_texture;


void fragment() {
    vec4 tex_color = texture(screen_vec, SCREEN_UV);
	float dist = distance(SCREEN_UV, vec2(0.5, 0.5));
	float vignette = smoothstep(0.0, vignette_intensity, dist);

	float desaturation = mix(1.0, edge_saturation, vignette);
	vec3 desaturated_color = mix(vec3(dot(tex_color.rgb, vec3(0.299, 0.587, 0.114))), tex_color.rgb, desaturation);

	COLOR.rgb = desaturated_color;
	COLOR.a = tex_color.a;
}