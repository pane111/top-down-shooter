shader_type canvas_item;
uniform float scale_offset;
uniform float speed;

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 uv = UV;
	uv -= 0.5;
	uv *= cos(TIME*speed)*scale_offset + 1.0;
	uv += 0.5;
	COLOR = texture(TEXTURE, uv);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
