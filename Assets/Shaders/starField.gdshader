shader_type canvas_item;
render_mode blend_mix;

uniform float density : hint_range(0.0, 3.0, 0.0001) = 1.3;
uniform int layer_parascale : hint_range(0, 5, 1) = 4;

// SPEED CONTROL: Negative moves Left, Positive moves Right, 0 freezes perfectly.
uniform vec2 star_speed = vec2(-20.0, 0.0); 

uniform vec2 star_wave = vec2(0.0);
uniform float star_size : hint_range(0.0, 100.0, 0.01) = 3.0;
uniform float star_rotate_speed : hint_range(-3.0, 3.0) = 0.5;
uniform float twinkle_effect : hint_range(0.0, 1.0, 0.01) = 0.6;
uniform float twinkle_speed : hint_range(0.0, 100.0, 0.01) = 0.3;
uniform bool pixelate_enabled = false;
uniform float pixelate_count = 1000.0;
uniform float emissive_intensity : hint_range(0.0, 2.0, 0.01) = 1.0;

// Controlled manually by GDScript to ensure smooth time tracking
uniform float manual_time = 0.0;

float one_div_x(float x) {
	return (abs(x) < 0.0001) ? 1.0 : (1.0/x);
}

float one_div_x2(float x) {
	return one_div_x(x) * one_div_x(x);
}

float get_beta_w(float x, float f, float size) {
	return size * x * PI / f;
}

float get_beta_h(float y, float f, float size) {
	return size * y * PI / f;
}

float get_i(vec2 uv, float f, vec2 size) {
	return one_div_x2(get_beta_w(uv.x, f, size.x)) * one_div_x2(get_beta_h(uv.y, f, size.y));
}

float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43759.5453123);
}

vec3 random_color(vec2 seed) {
	float r1 = random(seed);
	float r2 = random(seed + 132.456);
	
	vec3 color;
	float color_type = r1;
	
	if (color_type < 0.12) {
		color = vec3(1.0, 0.2, 0.2);
	} else if (color_type < 0.24) {
		color = vec3(1.0, 0.4, 0.1);
	} else if (color_type < 0.36) {
		color = vec3(1.0, 0.9, 0.1);
	} else if (color_type < 0.48) {
		color = vec3(0.2, 1.0, 0.2);
	} else if (color_type < 0.60) {
		color = vec3(0.1, 0.9, 1.0);
	} else if (color_type < 0.72) {
		color = vec3(0.2, 0.3, 1.0);
	} else if (color_type < 0.84) {
		color = vec3(0.8, 0.2, 1.0);
	} else {
		color = vec3(1.0, 0.2, 0.8);
	}
	
	float brightness_var = 0.7 + r2 * 0.8;
	color *= brightness_var;
	
	return color;
}

vec2 get_snowflake_world_center(vec2 grid_id, vec2 time_offset, vec2 snow_offset, float layer_scale) {
	return (grid_id + snow_offset + time_offset) / layer_scale;
}

vec2 rotate(vec2 uv, float add_theta) {
	float theta = atan(uv.y, uv.x) + add_theta;
	float r = length(uv);
	return vec2(r * cos(theta), r * sin(theta));
}

void fragment() {
	vec2 st = UV;
	if (pixelate_enabled) {
		st = round(st * pixelate_count) / pixelate_count;
	}
	
	vec2 cuv = (st - 0.5) * 2.0;
	vec3 final_color = vec3(0.0);
	float final_alpha = 0.0;
	
	for (int layer = 0; layer < layer_parascale; layer++) {
		float layer_scale = exp(float(layer + 1) * density);
		float layer_size = star_size * (1.0 - float(layer) * 0.2);
		
		// 1. Unified movement offset (scaled so normal inspector speeds like -20 work cleanly)
		// Multiplied by parallax layer weight so background layers scroll slower than foreground layers
		vec2 shift = star_speed * manual_time * 0.01 * (1.0 + float(layer) * 0.5);
		
		// 2. Shift the position coordinates cleanly BEFORE dividing into sub-structures
		vec2 layer_st = (st - shift) * layer_scale;
		vec2 cuv_st = (st - shift - 0.5) * 2.0;
		
		vec2 grid_st = fract(layer_st);
		vec2 grid_id = floor(layer_st);
		float rand_seed = random(grid_id);
		
		vec2 snow_pos = vec2(
			0.5 + (0.3 * sin((rand_seed * 6.28) + (manual_time * star_wave.x))),
			0.5 + (0.2 * cos((rand_seed * 12.56) + (manual_time * star_wave.y)))
		);
		
		float dist = distance(grid_st, snow_pos);
		float snow_size = layer_size * 0.01 * (0.5 + 0.5 * rand_seed);
		float brightness = 1.0 - (float(layer) * 0.3);
		
		float m = exp((-dist * dist) / (snow_size * snow_size));
		
		// 3. Bound shapes completely inside the coordinate matrix using zero time_offset parameter
		vec2 fst = cuv_st - (get_snowflake_world_center(grid_id, vec2(0.0), snow_pos, layer_scale) - 0.5) * 2.0;		
		fst = rotate(fst, manual_time * star_rotate_speed);
		
		float snowflake = m * 0.5 * (get_i(fst, 0.8 - (dist * 42.0), vec2(1.0 / snow_size)) + 1.0);
		
		float twinkle = (1.0 - twinkle_effect) + twinkle_effect * (sin(rand_seed * 100.0 + manual_time * twinkle_speed) * cos(rand_seed * 120.0 + manual_time * (twinkle_speed + 2.0)));
		snowflake *= twinkle;
		
		vec3 star_color = random_color(grid_id + float(layer) * 1000.0);
		float emissive = 0.7 + (random(grid_id + 50.0) * 0.8);
		star_color *= emissive * emissive_intensity;
		
		vec3 layer_color = star_color * snowflake * brightness;
		final_color += layer_color;
		final_alpha = max(final_alpha, snowflake * brightness * 0.9);
	}
	
	final_color = min(final_color, vec3(1.2));
	COLOR = vec4(final_color, final_alpha);
}