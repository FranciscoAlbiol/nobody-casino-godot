shader_type spatial;
render_mode unshaded;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform sampler2D noise_texture : filter_linear, repeat_enable;
uniform bool use_billboard;

group_uniforms Squiggle;
uniform vec2 scale = vec2(1.0, 1.0);
uniform float strength = 1.0;
uniform float fps = 6.0;
group_uniforms;

#define offset_multiplier vec2(3.141592, 2.718281)

void vertex() {
	if (use_billboard){
        MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	}
}

void fragment() {
	
	vec2 noise_uv = UV / scale;
	
	// Animate the frames based on time and FPS
	vec2 noise_offset = floor(TIME * fps) * offset_multiplier;
	
	// Sample the noise texture
	float noise_sample = texture(noise_texture, noise_uv + noise_offset).r * 4.0 * 3.141592;
	vec2 direction = vec2(cos(noise_sample), sin(noise_sample));
	
	// Offset the main sprite texture coordinates
	vec2 squiggle_uv = UV + direction * strength * 0.005;
	
	// Read the original Sprite3D texture data
	vec4 tex_color = texture(albedo_texture, squiggle_uv);
	
	ALBEDO = tex_color.rgb;
	ALPHA = tex_color.a;
}