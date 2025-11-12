shader_type spatial;

// Shader credit: Claude.ai
// Ran out of time to write ourselves :(

uniform sampler2D noise_texture1 : hint_default_white;
uniform sampler2D noise_texture2 : hint_default_white;

uniform vec4 water_color : source_color = vec4(0.1, 0.3, 0.5, 0.8);
uniform vec4 water_color_deep : source_color = vec4(0.05, 0.15, 0.3, 1.0);

uniform vec2 scroll_speed1 = vec2(0.02, 0.01);
uniform vec2 scroll_speed2 = vec2(-0.015, 0.025);

uniform float wave_strength = 0.1;
uniform float noise_scale = 1.0;

uniform float metallic : hint_range(0.0, 1.0) = 0.8;
uniform float roughness : hint_range(0.0, 1.0) = 0.2;

void fragment() {
    vec2 uv1 = UV * noise_scale + scroll_speed1 * TIME;
    vec2 uv2 = UV * noise_scale + scroll_speed2 * TIME;
    
    float noise1 = texture(noise_texture1, uv1).r;
    float noise2 = texture(noise_texture2, uv2).r;
    
    float combined_noise = (noise1 + noise2) * 0.5;
    
    vec4 final_color = mix(water_color_deep, water_color, combined_noise);
    
    ALBEDO = final_color.rgb;
    ALPHA = final_color.a;
    METALLIC = metallic;
    ROUGHNESS = roughness;
    
    vec3 normal_map;
    normal_map.x = (noise1 - 0.5) * wave_strength;
    normal_map.y = (noise2 - 0.5) * wave_strength;
    normal_map.z = 1.0;
    NORMAL_MAP = normalize(normal_map);
}

//void vertex() {
	//// Called for every vertex the material is visible on.
//}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
