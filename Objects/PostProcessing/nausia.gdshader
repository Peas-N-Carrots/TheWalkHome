shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform sampler2D AFTERIMAGE_TEXTURE;
uniform float AFTERIMAGE_BLEND;

uniform float CHROMA_STRENGTH: hint_range(0.0, 1.0) = 0.0;
uniform float NAUSIA_STRENGTH: hint_range(0.0, 1.0) = 0.0;
uniform float AFTERIMAGE_STRENGTH: hint_range(0.0, 1.0) = 0.0;
uniform float VIGNETTE_STRENGTH: hint_range(0.0, 1.0) = 0.0;

uniform float FADE_LEVEL: hint_range(0.0, 1.0) = 1.0;

const float VIGNETTE_INTENSITY = 0.6;
const float VIGNETTE_SOFTNESS = 0.1;

const vec2 offR = vec2(0.004, 0.002);
const vec2 offG = vec2(0.0, -0.006);
const vec2 offB = vec2(-0.004, 0.002);

//void vertex() {
	//// Called for every vertex the material is visible on.
//}

void fragment() {
	vec2 uv = SCREEN_UV;

	vec3 afterimage = texture(AFTERIMAGE_TEXTURE, uv).rgb;

	vec2 center = vec2(0.5, 0.5);
	float dist = distance(uv, center);

	// wave
	uv.x += sin(uv.y * 6.0 + TIME * 2.0) * 0.02 * NAUSIA_STRENGTH;
	uv.y += cos(uv.x * 4.7 + TIME * 3.0) * 0.02 * NAUSIA_STRENGTH;

	vec4 processed = texture(SCREEN_TEXTURE, uv);

	// chromatic aberration
	processed.rgb = vec3(texture(SCREEN_TEXTURE, uv + offR * CHROMA_STRENGTH).r,
			texture(SCREEN_TEXTURE, uv + offG * CHROMA_STRENGTH).g,
			texture(SCREEN_TEXTURE, uv + offB * CHROMA_STRENGTH).b);

	// vignette
	processed.rgb *= (1.0 - (smoothstep(VIGNETTE_SOFTNESS, VIGNETTE_INTENSITY, dist) * VIGNETTE_STRENGTH));

	// fade
	processed.rgb *= FADE_LEVEL;

	// afterimage
	processed.rgb = mix(processed.rgb, afterimage, AFTERIMAGE_BLEND * AFTERIMAGE_STRENGTH);

	COLOR = processed;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
