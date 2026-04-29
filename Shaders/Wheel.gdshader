shader_type canvas_item;

uniform float offset = 0.0;

void fragment() {
    vec2 uv = UV;
    uv.y += offset;
    COLOR = texture(TEXTURE, uv);
}