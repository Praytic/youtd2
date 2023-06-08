shader_type canvas_item;
render_mode unshaded;

uniform bool Smooth = true;
uniform float width : hint_range(0.0, 64) = 1.0;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform int pixel_size : hint_range(1, 10) = 4;

void fragment()
{
    float _width = width;
    vec2 unit = (1.0/float(pixel_size) ) / vec2(textureSize(TEXTURE, 0));
    vec4 pixel_color = texture(TEXTURE, UV);
    if (pixel_color.a == 0.0) {
        pixel_color = outline_color;
        pixel_color.a = 0.0;
        for (float x = -ceil(_width); x <= ceil(_width); x++) {
            for (float y = -ceil(_width); y <= ceil(_width); y++) {
                if (texture(TEXTURE, UV + vec2(x*unit.x, y*unit.y)).a == 0.0 || (x==0.0 && y==0.0)) {
                    continue;
                }
                if (Smooth) {
                    pixel_color.a += outline_color.a / (pow(x,2)+pow(y,2)) * (1.0-pow(2.0, -_width));
                    if (pixel_color.a > 1.0) {
                        pixel_color.a = 1.0;
                    }
                } else {
                    pixel_color.a = outline_color.a;
                }
            }
        }
    }
    COLOR = pixel_color;
}