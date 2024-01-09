shader_type canvas_item;

uniform float ring_radius : hint_range(0.1, 0.5, 0.01) = 0.12;
uniform float thickness_scalar : hint_range(0.0, 0.99, 0.05) = 0.25;
uniform float oscillation_scalar : hint_range(0.0, 0.25, 0.005) = 0.010;
uniform float speed : hint_range(0.0, 50.0, 0.1) = 4.0;
uniform vec4 main_color : source_color = vec4(1.0,1.0,1.0,1.0);
uniform vec4 lerp_color : source_color = vec4(1.0,1.0,1.0,1.0);

uniform int texture_size; 
uniform ivec2 texture_offset;


float range_lerp(float value, float min1, float min2, float max1, float max2){
	return min2 + (max2 - min2) * ((value - min1) / (max1 - min1));
}

void fragment() {
	vec4 pixel_color = texture(TEXTURE, UV);
	
	if (pixel_color.a < 0.5) {
		
		// Calculate the distance between the current pixel and the center of the model
		float u = UV.x - float(texture_size / 2 + texture_offset.x) / float(textureSize(TEXTURE, 0).x);
		float v = (UV.y - float(texture_size) / 1.35 / float(textureSize(TEXTURE, 0).y)) * 1.2;
//		vec2 scaledUV = vec2((UV.x - 0.165) * 1.0, (UV.y - 0.36) * 1.2);
//		vec2 scaledUV = vec2((UV.x - 0.5) * 1.0, (UV.y - 0.36) * 1.2);
//		vec2 scaledUV = vec2((UV.x - 0.835) * 1.0, (UV.y - 0.36) * 1.2);
		vec2 scaledUV = vec2(u, v);
		
		float dist = length(scaledUV);

		// Add a slight oscillation to the size of the ring
		float o = cos(TIME * speed);
		float ring_size = ring_radius + o * oscillation_scalar;
		
		float inner_hardness = 0.0;
		// Solve for ring alpha channel
		float alpha = step(dist, ring_size) * smoothstep(ring_size * (1.0 - thickness_scalar), ring_size, dist);
		
		// Solve w mix amount for optional color lerping
		float w = range_lerp(o, -1.0, 1.0, 1.0, 0.0);
		
		// Output the final color
		COLOR = vec4(mix(main_color.rgb, lerp_color.rgb, w), alpha );
	}
}