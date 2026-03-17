shader_type canvas_item;

uniform vec2 direction;
uniform float speed;
uniform float w_stren = 0.01;
uniform float w_speed = 1.0;
uniform float w_freq = 5.0;
varying vec4 modulate;

void vertex(){
	modulate=COLOR;
}

void fragment(){
	vec2 move = direction * TIME * speed;
	vec2 uv = UV;
	uv.x += sin(uv.y * w_freq + TIME * w_speed) * w_stren;
	uv.y += sin(uv.x * w_freq + TIME * w_speed) * w_stren;
	COLOR = texture(TEXTURE, uv+move) * modulate;
}
