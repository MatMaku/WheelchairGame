shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

uniform float strength = 0.08;
uniform float speed = 2.0;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;

    float noise = rand(uv * TIME * speed);

    vec4 color = texture(SCREEN_TEXTURE, uv);

    color.rgb += (noise - 0.5) * strength;

    COLOR = color;
	
	uv.x += sin(uv.y * 10.0 + TIME * 2.0) * 0.002;
}