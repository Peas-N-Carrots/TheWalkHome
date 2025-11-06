shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform sampler2D AFTERIMAGE_TEXTURE;
uniform float AFTERIMAGE_BLEND;
uniform float STRENGTH: hint_range(0.0, 1.0) = 1.0;

const vec2 offR = vec2(0.004, 0.002);
const vec2 offG = vec2(0.0, -0.006);
const vec2 offB = vec2(-0.004, 0.002);

//void vertex() {
	//// Called for every vertex the material is visible on.
//}

void fragment() {
	vec2 uv = SCREEN_UV;
	
	vec3 afterimage = texture(AFTERIMAGE_TEXTURE, uv).rgb;
	
	uv.x += sin(uv.y * 6.0 + TIME * 2.0) * 0.02 * STRENGTH;
	uv.y += cos(uv.x * 4.7 + TIME * 3.0) * 0.02 * STRENGTH;
	
	vec4 processed = texture(SCREEN_TEXTURE, uv);
	
	processed.rgb = vec3(texture(SCREEN_TEXTURE, uv + offR * STRENGTH).r,
			texture(SCREEN_TEXTURE, uv + offG * STRENGTH).g,
			texture(SCREEN_TEXTURE, uv + offB * STRENGTH).b);
	
	processed.rgb = mix(processed.rgb, afterimage, AFTERIMAGE_BLEND);
	
	COLOR = processed;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
