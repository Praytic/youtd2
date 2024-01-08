shader_type canvas_item;

uniform float shadow_saturation : hint_range(0.0, 1.0) = 0.5;

uniform sampler2D screen_vec : hint_screen_texture;


void fragment() {
    // Get the texture color at the current fragment
    vec4 tex_color = texture(TEXTURE, UV);

    // Check if the texture's alpha is greater than 0 (not completely transparent)
    if (tex_color.a > 0.0) {
        // If so, just use the texture color
        COLOR = tex_color;
    } else {
        // Otherwise, apply a half-transparent grey overlay
        COLOR = mix(tex_color, vec4(0.5, 0.5, 0.5, 0.5), 0.5);
    }
}